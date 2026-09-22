# StudyMate: iOS experience and system design

## StudyTok: automatic hashtag feed

StudyTok now searches YouTube automatically. There is no manual approval queue and no Firestore video catalog to populate or deploy rules for.

Flow: **hashtag chip → authenticated FastAPI endpoint → YouTube search → full video metadata → exact hashtag filter → embedded player**.

The server first discovers candidates with `search.list`, then retrieves their full titles/descriptions with `videos.list`. A search hit alone is not accepted. At least one allowed hashtag must appear as a complete hashtag in the title or description; matching is case-insensitive. Selecting a tag requires that specific tag. For example, `#Maths` matches, while plain `maths`, `#MathsFunny`, and `#Maths2026` do not.

Starter tags: **#Study, #StudyTok, #StudyWithMe, #StudyTips, #ActiveRecall, #SpacedRepetition, #ExamPrep, #Revision, #Flashcards, #NoteTaking, #Pomodoro, #Maths, #Algebra, #Calculus, #Science, #Physics, #Chemistry, #Biology, #History, #Coding, #ComputerScience, #LanguageLearning**.

Videos tagged #funny, #comedy, #prank, #pranks, #meme, #memes or #entertainment are excluded even if they also carry a study hashtag. Private, non-embeddable and current/upcoming live videos are excluded. Ordinary videos and short videos are supported; the API does not identify a result as a YouTube Short, and this does not search Instagram Reels or TikTok.

**This filters metadata, not the audiovisual content.** A creator can mislabel a funny video with a study hashtag, so it cannot guarantee study-only content. YouTube also controls ads and recommendations inside its embed; `rel=0` does not remove recommendations. Stronger enforcement would require content review/classification and, for full playback control, licensed self-hosted videos. That is not part of this simpler version.

Sources: [YouTube search parameters](https://developers.google.com/youtube/v3/docs/search/list), [video metadata](https://developers.google.com/youtube/v3/docs/videos), [embedded player limitations](https://developers.google.com/youtube/player_parameters#rel).

## One-time setup

1. Enable **YouTube Data API v3** in your Google Cloud project and create an API key restricted to that API. [Google setup guide](https://developers.google.com/youtube/v3/getting-started).
2. Add `YOUTUBE_API_KEY` to the existing backend service's environment/secrets (for example, the Render Environment panel). Do not place it in Flutter, Git or a chat message.
3. Deploy the updated `backend/` service. It now exposes `GET /studytok/videos?hashtag=Maths`, protected by the same Firebase ID-token verification as the AI endpoints.
4. The app uses `AI_BACKEND_BASE_URL`, defaulting to `https://fetchdata-jx72.onrender.com`. If deploying elsewhere, run `flutter run --dart-define=AI_BACKEND_BASE_URL=https://YOUR_BACKEND`.
5. Rebuild the app and open StudyTok. Missing API configuration or an old backend endpoint shows a setup message, not a Wi-Fi error.

For local backend testing with Firebase credentials configured:

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
# Set YOUTUBE_API_KEY and Firebase credentials securely in your shell.
uvicorn main:app --host 0.0.0.0 --port 8000
```

In a second terminal, launch the iOS simulator app against the local backend:

```bash
flutter run --dart-define=AI_BACKEND_BASE_URL=http://127.0.0.1:8000
```

Optional terminal preview, using the same filter:

```bash
python3 backend/scripts/discover_studytok.py --tag StudyTips
```

No live API key or backend deployment was supplied as part of this change. Without that one-time setup, the feed cannot fetch real videos. No remote Firestore rules or content were changed.

## Reliability and cost

- Up to 50 candidates are checked per selection. The feed can therefore return fewer than 50 or no matches. No unfiltered fallback is shown.
- Each tag's results are cached on the server for one hour; refreshing does not bypass the cache. Requests for the same tag are coalesced. A per-process budget caps searches at 80 per rolling 24 hours; YouTube's own project quota still applies.
- This cache/budget is appropriate for a small single-process deployment. Before scaling to multiple workers/instances, move both into a shared store such as Redis. A restart resets the local budget. Results may remain stale until the cache expires; removed videos show a playback error.
- Token and network requests time out. Setup, session-expiry, quota and network errors have distinct UI messages. Fast hashtag switching isolates responses by provider key.
- One embedded player runs at a time. Playback stops on tab exit, backgrounding, category changes and swiping. External browsing remains blocked where navigation can be intercepted.

## iOS changes retained

Five primary destinations: Home, Focus, Learn, StudyTok and Streaks. Tabs mount on demand and retain state. Learn groups flashcards and mindmaps. System typography, native iOS transitions, larger button targets and responsive sound tiles improve consistency.

The dashboard remains usable when progress fails to load. Timers use monotonic elapsed time and pause without discarding progress on backgrounding. Save retries use a stable document ID; concurrent saves are prevented. AI requests time out, late responses do not update disposed screens, and saved-topic streams avoid resubscribing on every rebuild.

## Recommended next architecture steps

Keep Flutter, Firebase Auth/Firestore and the existing FastAPI service. Add complexity only as usage grows:

- Persist timer drafts locally per user to recover after process termination; current preservation is in-memory only.
- Add cursor pagination and server-side daily summaries for session history and dashboard totals.
- Move long AI generation to idempotent background jobs; validate output schemas and enforce per-user rate limits.
- Use a shared cache/quota limiter for YouTube across replicas, plus monitoring of empty results, upstream failures and playback errors.
- Separate public username/display-name profiles from private user data; tighten friend/snap permissions before production.
- Measure frame timings in profile mode on a physical iPhone before claiming a particular frame rate.

## Validation and remaining checks

Automated tests cover exact hashtag matching, case handling, entertainment exclusions, private/non-embeddable/live filtering, duplicate removal, caching, quota caps, request authentication, error mapping, selected-hashtag isolation, small-screen/large-text UI and timer regressions.

Live YouTube playback still needs validation with the configured API key and deployed backend. Test embedding-disabled, removed and age-restricted videos, disconnects, rapid swipes, VoiceOver and backgrounding on a real iPhone.

The previous generic Flutter simulator build hit a combined-architecture preparation issue on this Xcode/Flutter installation. An explicit arm64 build worked; use a specific iPhone simulator destination or:

```bash
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -clonedSourcePackagesDirPath build/ios/SourcePackages \
  -skipPackageUpdates -skipPackagePluginValidation -skipPackageSignatureValidation \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build
```

Latest local validation: 15 Flutter tests and 9 Python tests passed; Dart analysis reported no errors or warnings (informational lint notices remain). The updated app's arm64 iOS simulator build succeeded. YouTube responses were mocked in tests; live API playback remains unverified until the key and backend deployment are configured. The Docker image now includes the new `studytok.py` module.
