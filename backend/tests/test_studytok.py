import os
import unittest
from unittest.mock import patch
from backend.studytok import FeedError, HashtagFeed, filter_video, normalize_tag


def video(text='#Maths #Algebra'):
    return {'id': 'abcdefghijk', 'snippet': {
        'title': 'Fractions', 'description': text, 'channelTitle': 'Teacher',
        'liveBroadcastContent': 'none'},
        'status': {'privacyStatus': 'public', 'embeddable': True}}


class HashtagTest(unittest.TestCase):
    def test_exact_case_insensitive_hashtags(self):
        self.assertEqual(filter_video(video('#mAtHs #ALGEBRA'))['hashtags'], ['#Maths', '#Algebra'])
        for text in ['maths explained', '#MathsFunny', '#notMaths', '#Maths_2026', '#Maths数学']:
            self.assertIsNone(filter_video(video(text)), text)
        self.assertIsNone(filter_video(video('#Maths'), 'Science'))
        self.assertIsNotNone(filter_video(video('Learn (#Maths).'), 'Maths'))

    def test_entertainment_tags_and_unavailable_videos_are_excluded(self):
        for tag in ['#funny', '#COMEDY', '#prank', '#memes', '#entertainment']:
            self.assertIsNone(filter_video(video('#Maths ' + tag)))
        item = video()
        item['status']['embeddable'] = False
        self.assertIsNone(filter_video(item))
        item = video()
        item['status']['privacyStatus'] = 'private'
        self.assertIsNone(filter_video(item))
        item = video()
        item['snippet']['liveBroadcastContent'] = 'upcoming'
        self.assertIsNone(filter_video(item))
        for item in [None, {}, {'snippet': None}, {'id': 'bad'}, {'status': []}]:
            self.assertIsNone(filter_video(item))

    def test_only_fixed_topics_can_be_queried(self):
        self.assertEqual(normalize_tag('#mAtHs'), 'Maths')
        with self.assertRaises(FeedError):
            normalize_tag('funny cats')

    @patch.dict(os.environ, {'YOUTUBE_API_KEY': 'test-only'})
    def test_details_are_checked_and_results_cached(self):
        calls = []
        now = [0]
        def fetch(resource, params, key):
            calls.append((resource, params))
            if resource == 'search':
                return {'items': [{'id': {'videoId': 'abcdefghijk'}}, {'id': {'videoId': 'abcdefghijk'}}]}
            return {'items': [video()]}
        feed = HashtagFeed(fetch=fetch, clock=lambda: now[0])
        first = feed.get('#Maths')
        self.assertEqual(first['videos'][0]['hashtags'], ['#Maths', '#Algebra'])
        self.assertNotIn('status', first['videos'][0])
        self.assertEqual(feed.get('Maths'), first)
        self.assertEqual(len(calls), 2)
        self.assertEqual(calls[0][1]['videoEmbeddable'], 'true')
        self.assertEqual(calls[1][1]['part'], 'snippet,status')
        now[0] = 3601
        feed.get('Maths')
        self.assertEqual(len(calls), 4)

    @patch.dict(os.environ, {'YOUTUBE_API_KEY': 'test-only'})
    def test_search_hit_without_actual_hashtag_never_reaches_feed(self):
        def fetch(resource, params, key):
            return {'items': [{'id': {'videoId': 'abcdefghijk'}}]} if resource == 'search' else {'items': [video('maths tutorial')]}
        self.assertEqual(HashtagFeed(fetch=fetch).get('Maths')['videos'], [])

    @patch.dict(os.environ, {'YOUTUBE_API_KEY': ''})
    def test_missing_key_is_setup_error_not_network_error(self):
        with self.assertRaises(FeedError) as caught:
            HashtagFeed().get()
        self.assertEqual(caught.exception.code, 'youtube_setup_required')

    @patch.dict(os.environ, {'YOUTUBE_API_KEY': 'test-only'})
    def test_budget_prevents_more_searches(self):
        feed = HashtagFeed(fetch=lambda *_: self.fail('Must not query YouTube'))
        feed.searches = 80
        with self.assertRaises(FeedError) as caught:
            feed.get('Maths')
        self.assertEqual(caught.exception.code, 'youtube_quota_exceeded')


if __name__ == '__main__':
    unittest.main()
