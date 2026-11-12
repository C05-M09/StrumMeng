# US12 — Showtime session prototype

## Current flow

Home → Showtime → sample song card → Intro → Listen to a strumming pattern on C →
Ready → READY? → 3, 2, 1 → one-minute song gameplay → in-memory session result.
This explicitly extends the older MVP decision that left Showtime inactive.

| Work item | Current implementation | Remaining integration |
| --- | --- | --- |
| Session state machine | Tested preview gate, countdown, pause/disconnect, restart, exit, finish | Physical-device acceptance checks |
| Intro | Connected from sample cards, Next, supplied copy and shared entrance animation | Final designer approval |
| Listen | C-chord guitar, pattern-only lane, all-pattern Ready gate, no chords or song duration | Final song/pattern metadata |
| Multiple patterns | Selector replaces duration area; each required pattern must finish a loop before Ready unlocks | Final song pattern-change data |
| Count-in | Shared Practice callout/countdown, song starts at beat 0 | Physical-device timing feel |
| Play | Moving arrows, chord labels, hit ring and song-duration progress, white BPM | Teammate's chord synthesis and verified arrangements |
| Feedback | Existing Practice engine and real iPhone controller integration | Physical pair/reconnect validation |
| Pause | Shared Resume/Restart/Back overlay, automatic pause on disconnect/background | Physical-device validation |

## Listen audio and Ready

PatternStrumDemoPlayer uses GuitarSound backed by the same GuitarEngine as Practice, using GuitarSound’s default C-chord overload. This is the existing synthesized C guitar sound, not a recording of
a whole song. One eighth-note BeatClock drives scheduled strums and highlight events.
Rests are silent. Down/up follow the selected pattern at the song's BPM.

The player finished event means the selected pattern's first complete loop ended;
audio continues looping. The ViewModel records completion by distinct pattern index.
Ready uses Button_Ready_Disabled until every required pattern has been heard for at
least one loop. Replaying one pattern does not count for another. Once all are heard,
Ready becomes active and stays available while the highlight keeps moving. Pause/Resume after unlocking Ready resumes audio too.
Pressing Ready stops the preview before the gameplay count-in starts.

For multiple patterns, selection resets the preview to slot 0 but preserves fully
heard patterns. Switching before a loop ends does not count it. Pause/Resume preserves
progress. Restart in Listen clears all completion flags and returns to pattern 1.
Selecting a preview does not rewrite the song arrangement. The selector sits further
left, at ShowtimeLayout.patternSelectorCenter. A disconnected-iPhone alert pauses
preview audio even when triggered by pressing Ready without an active connection.

## Dummy data and future integration

DummySongCatalog has two clearly labelled sample arrangements, not verified transcriptions:
Twinkle Twinkle Little Star (80 BPM, 20 bars) and Jingle Bells (96 BPM, 24 bars).
Gameplay lasts 60 seconds for each: bars × 4 beats × 60/BPM. Each required Listen
pattern takes one loop: for eight slots, 3 seconds at 80 BPM and 2.5 at 96 BPM.
Jingle Bells has a second pattern at song slot 96 to exercise selection and pattern changes.

SongPatternChange and SongChordChange use eighth-note slot indices. SongTimeline
unfolds both on the same grid used for gameplay nodes and judging. The final song
catalogue can replace SongCatalog in AppContainer. Gameplay sound is still metronome
only; the teammate's chord synthesis/backing audio is not implemented here.

Song/visitor-request persistence and Showtime result saves are not implemented.
SessionResultBuilder.build(..., songID: song.id, ...) now creates the Showtime result
with the selected catalogue ID directly. AppContainer passes it into the shared PlayViewModel;
ShowtimeViewModel forwards the finished result unchanged. The builder contract and its
base tests match the owner's Feat/session-result-builder-menerima-song-id branch.
Practice omits the parameter and retains the nil default. Song IDs are still the
sample catalogue IDs until the real catalogue is connected; results remain in memory. Restart and Back discard
results. The existing SwiftData schema and shared connectivity/settings contracts are
unchanged. Calibration remains zero, matching Practice, until SettingsStore exposes it.

## Layout and code

ShowtimeViewModel owns the session state and selected preview pattern. ShowtimeReducer
is pure. SongDemoPlayer isolates preview sound; SongGameplay injects the shared Practice
engine. No service or SwiftData access occurs in Views.

Shared session engine: Core/Services/Practice/Session.
Shared lane/countdown/pause views: Core/DesignSystem/Play.
Showtime screens: Features/Showtime. Factories and previews: App.

TitleLineWrapping creates explicit word-boundary lines. ShowtimeLayout.titleLineSpacing
controls the VStack gap (currently -12). Shared PracticePlayView accepts optional title
spacing and BPM color; Practice retains its original defaults. Showtime intro uses
the same banner/mascot/bubble/text/Next geometry as the Practice Listen introduction.
Gameplay labels show the initial chord and genuine changes only, never repeated
chords at every node or repeated identical metadata entries. Song cards have no shadow.
Showtime assets are namespaced: Showtime_Assets/<asset name>, preventing duplicate names
from changing the Practice artwork.

## Check manually

1. Home → Showtime → Twinkle → Next. Hear C strumming, no chords or duration in Listen.
2. Ready initially shows its disabled artwork. It activates after all required loops.
3. Jingle → Next: use Pattern 1/2. Both patterns must be heard for a complete loop.
4. Pause/Resume before and after Ready appears. Restart resets the current preview.
5. Pair iPhone, press Ready, check countdown, arrows/chords and real timing feedback.
6. Pause, resume, restart, leave, and disconnect/reconnect iPhone during gameplay.

For Canvas-only checks, App/ShowtimePreviews.swift includes a silent interactive flow
with no iPhone requirement and static Intro/Listen/Play/pause/disconnect/result previews.
Normal app Showtime gameplay requires a paired iPhone.

## Tests

ShowtimeReducerTests, ShowtimeViewModelTests, SongTimelineTests,
PatternStrumDemoPlayerTests, SongEngineIntegrationTests and TitleLineWrappingTests.
They verify all-pattern gating, continued audio/highlights, switching/resetting patterns,
BPM scheduling, silent rests, pause/resume, cancellation and actual shared feedback.
Practice and routing tests are regression checks for the reused components.

Latest songID integration validation: 131 selected unit tests passed, covering the
owner's builder tests, unchanged Practice nil identity, engine-to-Showtime result
identity, Home navigation and repository behavior. Earlier UI validation covered
all-pattern gating, audio mute on disconnect, sparse chord labels and reviewed
Listen/Intro/Play renders. Real-device audio and iPhone connection checks remain manual.

Merge compatibility cleanup follows the current dev APIs: GuitarEngine() prepares C
through the GuitarSound default overload, and Home button sound is owned by the View's
ButtonPressSound rather than the HomeViewModel. Obsolete merge leftovers in Home's
initializer and tests were removed; Showtime navigation callbacks remain covered.
