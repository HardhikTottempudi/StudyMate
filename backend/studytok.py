"""YouTube hashtag discovery. This is a relevance filter, not moderation."""
import html
import json
import os
import re
import threading
import time
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import urlopen

TOPICS = {
    'Maths': 'Maths', 'Science': 'Science', 'StudyTips': 'Study skills',
    'Study': 'Study skills', 'StudyTok': 'Study skills', 'StudyWithMe': 'Study skills',
    'ActiveRecall': 'Study skills', 'SpacedRepetition': 'Study skills',
    'ExamPrep': 'Study skills', 'Revision': 'Study skills',
    'Flashcards': 'Study skills', 'NoteTaking': 'Study skills', 'Pomodoro': 'Study skills',
    'Physics': 'Physics', 'Chemistry': 'Chemistry', 'Biology': 'Biology',
    'History': 'History', 'Coding': 'Programming', 'LanguageLearning': 'Languages',
    'Algebra': 'Maths', 'Calculus': 'Maths', 'ComputerScience': 'Programming',
}
CANONICAL = {tag.casefold(): tag for tag in TOPICS}
BLOCKED = {'funny', 'comedy', 'prank', 'pranks', 'meme', 'memes', 'entertainment'}
HASHTAG = re.compile(r'(?<![\w#])#(\w+)', re.UNICODE)
VIDEO_ID = re.compile(r'^[A-Za-z0-9_-]{11}$')


class FeedError(Exception):
    def __init__(self, code, status=503):
        self.code = code
        self.status = status
        super().__init__(code)


def normalize_tag(value):
    if value.casefold() == 'all':
        return 'All'
    tag = CANONICAL.get(value.lstrip('#').casefold())
    if tag is None:
        raise FeedError('invalid_hashtag', 400)
    return tag


def filter_video(item, selected='All'):
    """Check full title/description; a search hit alone is never sufficient."""
    if not isinstance(item, dict):
        return None
    snippet, status = item.get('snippet'), item.get('status')
    if not isinstance(snippet, dict) or not isinstance(status, dict):
        return None
    video_id = item.get('id')
    if not isinstance(video_id, str) or not VIDEO_ID.fullmatch(video_id):
        return None
    if status.get('privacyStatus') != 'public' or status.get('embeddable') is not True:
        return None
    if snippet.get('liveBroadcastContent', 'none') != 'none':
        return None
    title, description, creator = (snippet.get(k, '') for k in ('title', 'description', 'channelTitle'))
    if not all(isinstance(v, str) for v in (title, description, creator)) or not title.strip() or not creator.strip():
        return None
    title, description = html.unescape(title), html.unescape(description)
    found = {tag.casefold() for tag in HASHTAG.findall(title + '\n' + description)}
    if found & BLOCKED:
        return None
    matched = [tag for tag in TOPICS if tag.casefold() in found]
    if not matched or (selected != 'All' and selected not in matched):
        return None
    return {
        'youtubeId': video_id, 'title': title[:300], 'creator': creator[:300],
        'description': description[:500],
        'subject': TOPICS[selected if selected != 'All' else matched[0]],
        'hashtags': ['#' + tag for tag in matched],
    }


def youtube_json(resource, params, key):
    url = 'https://www.googleapis.com/youtube/v3/' + resource + '?' + urlencode({**params, 'key': key})
    try:
        with urlopen(url, timeout=10) as response:
            data = json.load(response)
        if not isinstance(data, dict) or not isinstance(data.get('items'), list):
            raise FeedError('youtube_unavailable', 502)
        return data
    except HTTPError as error:
        try:
            body = json.load(error)
            reasons = {e.get('reason') for e in body.get('error', {}).get('errors', [])}
        except (ValueError, AttributeError, TypeError):
            reasons = set()
        if reasons & {'quotaExceeded', 'dailyLimitExceeded', 'rateLimitExceeded'} or error.code == 429:
            raise FeedError('youtube_quota_exceeded', 429) from None
        if error.code in (400, 401, 403):
            raise FeedError('youtube_setup_required') from None
        raise FeedError('youtube_unavailable', 502) from None
    except (URLError, TimeoutError, OSError, ValueError):
        raise FeedError('youtube_unavailable', 502) from None


class HashtagFeed:
    """Bounded per-process cache and request coalescing to protect search quota."""
    def __init__(self, fetch=youtube_json, clock=time.monotonic):
        self.fetch, self.clock = fetch, clock
        self.cache = {}
        self.locks = {tag: threading.Lock() for tag in ['All', *TOPICS]}
        self.budget_lock = threading.Lock()
        self.window = clock()
        self.searches = 0

    def get(self, requested='All'):
        selected = normalize_tag(requested)
        key = os.getenv('YOUTUBE_API_KEY', '').strip()
        if not key:
            raise FeedError('youtube_setup_required')
        with self.locks[selected]:
            now = self.clock()
            cached = self.cache.get(selected)
            if cached and now < cached[0]:
                return cached[1]
            with self.budget_lock:
                if now - self.window >= 86400:
                    self.window, self.searches = now, 0
                if self.searches >= 80:
                    raise FeedError('youtube_quota_exceeded', 429)
                self.searches += 1
            tags = list(TOPICS) if selected == 'All' else [selected]
            results = self.fetch('search', {
                'part': 'snippet', 'type': 'video', 'maxResults': 50,
                'q': '|'.join('#' + tag for tag in tags),
                'safeSearch': 'strict', 'videoEmbeddable': 'true',
                'videoSyndicated': 'true', 'order': 'relevance',
            }, key)
            ids = []
            for item in results['items']:
                if not isinstance(item, dict) or not isinstance(item.get('id'), dict):
                    continue
                video_id = item['id'].get('videoId')
                if isinstance(video_id, str) and VIDEO_ID.fullmatch(video_id) and video_id not in ids:
                    ids.append(video_id)
            videos = []
            if ids:
                details = self.fetch('videos', {'part': 'snippet,status', 'id': ','.join(ids[:50])}, key)
                by_id = {}
                for item in details['items']:
                    video = filter_video(item, selected)
                    if video and video['youtubeId'] in ids:
                        by_id[video['youtubeId']] = video
                videos = [by_id[video_id] for video_id in ids if video_id in by_id]
            payload = {'videos': videos, 'hashtag': selected}
            self.cache[selected] = (self.clock() + 3600, payload)
            return payload
