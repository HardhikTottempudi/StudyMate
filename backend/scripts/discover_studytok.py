"""Preview the same hashtag-filtered feed used by the app.

Set YOUTUBE_API_KEY in the environment, then run:
python3 backend/scripts/discover_studytok.py --tag StudyTips
No Firestore writes or manual approval step are involved.
"""
import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from studytok import FeedError, HashtagFeed, TOPICS


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--tag', choices=['All', *sorted(TOPICS)], default='StudyTips')
    args = parser.parse_args()
    try:
        print(json.dumps(HashtagFeed().get(args.tag), indent=2, ensure_ascii=False))
    except FeedError as error:
        print(f'StudyTok: {error.code}', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
