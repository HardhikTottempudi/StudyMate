import unittest
from unittest.mock import patch
from discover_studytok import main
from studytok import FeedError


class DiscoveryCliTest(unittest.TestCase):
    @patch('sys.argv', ['discover_studytok.py', '--tag', 'Maths'])
    @patch('discover_studytok.HashtagFeed')
    @patch('builtins.print')
    def test_cli_uses_the_same_automatic_feed(self, output, feed):
        feed.return_value.get.return_value = {'videos': [], 'hashtag': 'Maths'}
        self.assertEqual(main(), 0)
        feed.return_value.get.assert_called_once_with('Maths')

    @patch('sys.argv', ['discover_studytok.py'])
    @patch('discover_studytok.HashtagFeed')
    @patch('builtins.print')
    def test_cli_reports_setup_errors_without_secrets(self, output, feed):
        feed.return_value.get.side_effect = FeedError('youtube_setup_required')
        self.assertEqual(main(), 1)
        self.assertIn('youtube_setup_required', output.call_args.args[0])


if __name__ == '__main__':
    unittest.main()
