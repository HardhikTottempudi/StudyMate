# StudyMate visual direction

Based on the soft, pastel dashboard reference supplied in this conversation. Adapted to an iPhone layout with existing study features and navigation.

- Warm grey background, translucent white panels and fine white borders.
- Charcoal text; muted grey secondary copy; restrained burnt-orange actions.
- Peach, rose, lilac and sage artwork with cream fades. Artwork is painted locally in Flutter, without image downloads or live backdrop blurs.
- Rounded 28–32 px surfaces, pill-shaped filters and buttons, generous spacing.
- Five primary tabs and functional dashboard shortcuts. Today/Focus/Unwind filters reveal the relevant sections.
- Shared styling across Home, Focus, Learn and StudyTok. The YouTube player itself retains its native dark playback surface.
- Adaptive card stacking for narrow screens or large text. Scrollable content and labelled audio controls preserve access to actions.

Shared components: `lib/shared/widgets/soft_surface.dart`, `lib/shared/widgets/study_tab_bar.dart`. Theme: `lib/shared/theme/app_theme.dart`.

[Dashboard preview](previews/dashboard.png) is rendered from the real dashboard widget with sample data and test fonts, not a screenshot of a signed-in production account. Text can differ slightly on iOS's system font.

Validation: 17 Flutter tests passed, analyzer reported no errors or warnings (informational lint notices remain), and the arm64 iOS simulator build succeeded. Real-device performance has not been profiled.
