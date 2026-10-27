# CLAUDE\.md — working guide for StrumMeng

This file tells you \(Claude, or any other contributor\) how to work in this repository day to day\.<br>Docs/ARCHITECTURE\.md is the source of truth for why things are structured this way: feature<br>analysis, the reasoning behind each decision, and the folder structure\. Read it before your first<br>change if you have not already\. This file is the source of truth for how to work here:<br>conventions, rules, workflow, and things that are easy to get wrong\.<br>If anything in this file conflicts with Docs/ARCHITECTURE\.md, treat ARCHITECTURE\.md as<br>authoritative and flag the conflict rather than silently picking one\.

## 1\. What this app is

An iPadOS app for self\-taught guitar players who already know their chords\. It helps them<br>strum on tempo by providing practice sessions that teach many strumming patterns one step at a<br>time, with real\-time feedback\. Strums are input on a paired iPhone used as a controller: the<br>player swipes on the iPhone, and the iPhone sends each strum to the iPad over a local peer\-to\-peer<br>link\. The iPad is the main screen: it plays the guitar sound, runs the beat clock and judges timing\.<br>There is no microphone input\. Fully on\-device: no backend, no internet, no accounts\. The only<br>network traffic is the local link between the player's own iPhone and iPad\.<br>See Docs/ARCHITECTURE\.md §1\-3 for the full feature breakdown\.

MVP scope: Practice, Guidebook, per\-pattern records, Option \(with latency calibration and<br>controller connection\)\. Showtime is out of scope for the MVP \(see §11\)\.

## 2\. Tech stack

- iPadOS 26\+ \(iPad host\) and iOS 26\+ \(iPhone controller\)\. Wi\-Fi Aware needs iOS/iPadOS 26\.
- SwiftUI only \(no UIKit unless a framework forces it and the team agrees\)\. Known exception: the<br>controller touch pad uses a UIView for multi\-touch tracking\.
- @Observable \(Observation framework\) for all view models\. Never ObservableObject or @Published\.
- MVVM \+ state machine\. See §5\.
- SwiftData for persistence, only through SessionRepository\.
- Network framework for the controller link \(Wi\-Fi Aware, with Bonjour over regular Wi\-Fi as<br>fallback\), behind ControllerLink\.
- AVAudioEngine / AVAudioSession for audio output and the beat clock only, behind protocols\.
- UserDefaults behind SettingsStore for the settings values\.
- XCTest for unit tests\. \[Assumption\] Swift Testing may replace it if the whole team uses Xcode 16\+\.
- One plain, Xcode\-native \.xcodeproj with a single universal app target \(iPad = host, iPhone =<br>controller\), organised by folders\. No local Swift packages, no XcodeGen, no Tuist\. Do not<br>introduce one without discussing it; it is a structural change\.
- No CI and no SwiftLint/SwiftFormat yet \(deliberate\)\. Follow the style rules in this file manually<br>and do not let that gap turn into inconsistent code\.

## 3\. Repository map

```text
./                                repository root
├── StrumMeng.xcodeproj
├── StrumMeng/                     universal app target
│   ├── App/                       entry point, AppContainer, AppRouter, device role
│   ├── Core/
│   │   ├── Models/                domain models and shared contracts
│   │   ├── Services/
│   │   │   ├── Audio/             BeatClock, Metronome, PatternPlayer
│   │   │   ├── Connectivity/      ControllerLink, clock sync, de-duplication
│   │   │   ├── Practice/          TimingJudge, FeedbackEngine, result builder
│   │   │   └── Settings/          SettingsStore
│   │   ├── Data/                  SwiftData models and SessionRepository
│   │   └── DesignSystem/          tokens and shared UI components
│   └── Features/
│       ├── Home/
│       ├── Practice/              List, Listen, Play, Summary, Replay
│       ├── Guidebook/
│       ├── Option/                settings and latency calibration
│       └── Controller/            iPad connection UI and iPhone touch pad
├── StrumMengTests/                mirrors Core and Features; mocks in TestSupport
├── Docs/ARCHITECTURE.md
├── CLAUDE.md
├── README.md
└── .gitignore
```

Full detail: Docs/ARCHITECTURE\.md §5\.

## 4\. The rule that matters most

Layers depend inward\. Views never talk to services directly, and Features never import each other\.

```text
Features (View + ViewModel) ──depends on──▶ Core (models and protocols)
App (AppContainer)          ──wires implementations──▶ Core and Features
ControllerLink              ──normalises both transports──▶ StrumEvent stream
```

- Views show state and send events\. They contain no business logic and never touch AVFoundation,<br>Network or SwiftData\.
- ViewModels own a state machine and trigger side effects through protocols \(ControllerLink,<br>BeatClock, SessionRepository, SettingsStore\)\. They never create concrete services themselves\.
- Core/Services and Core/Data never import anything from Features\.
- A Feature must not import another Feature\. If two features need the same thing, move it to Core\.
- Only App/AppContainer\.swift is allowed to know the concrete implementations and wire them to protocols\.
- SwiftData's @Model types \(PracticeSessionRecord\) stay inside Core/Data\. Views and ViewModels see<br>only SessionResult\.
- All navigation goes through AppRouter\. No scattered NavigationLinks\.

If a task seems to require breaking one of these, add or adjust a protocol instead of adding the import\.

## 5\. State machine pattern

Every feature with more than a couple of states uses the same shape:

```swift
enum FeatureState: Equatable { /* cases */ }
enum FeatureEvent { /* cases */ }

func reduce(_ state: FeatureState, _ event: FeatureEvent) -> FeatureState {
    /* pure state transition */
}
```

- reduce is a pure function: no I/O, no audio, no network, no Date\(\), no randomness\. It only maps<br>\(state, event\) to a new state\.
- The @Observable ViewModel holds state, receives events from the View or from services, calls<br>reduce, and performs side effects based on the new state\.
- Illegal transitions are ignored, not crashed on \(for example tapReady while playing\)\.

Used for: PracticeState \(idle, listening, ready, countIn, playing, paused, finished\), SummaryState,<br>ControllerConnectionState \(unpaired, searching, connected, reconnecting\), CalibrationState\.

Prefer an enum ViewState over scattered booleans for any screen with loading/empty/error/loaded<br>semantics, so illegal combinations are unrepresentable\.

## 6\. Naming and coding conventions

- camelCase for variables and functions\. PascalCase for types \(struct, class, enum, protocol\) and folders\.
- One type per file; the filename matches the type name\.
- Naming pattern: XyzViewModel, XyzView, XyzService, XyzRepository, MockXyz \(test doubles\),<br>XyzState / XyzEvent\. Do not invent alternate suffixes for the same role\.
- Access control is deliberate\. Default to internal; use private for implementation details\.
- No force\-unwraps \(\!\), no try\!, no as\! outside test code\. Use guard let, if let, or typed errors\.
- Value types by default\. Models are structs conforming to Sendable \(and Codable where stored\)\.<br>Use class or actor only where reference semantics or isolation really matter \(view models, services\)\.
- Design tokens, not hard\-coded values\. Colours, fonts and spacing come from Core/DesignSystem\.<br>Never write a raw colour in a View\.
- Comments explain why, not what\. Public APIs and anything surprising get a /// doc comment\.

## 7\. Concurrency and performance rules

- Beat clock uses audio time \(AVAudioEngine with AVAudioTime, or mach\_absolute\_time\)\. Never use<br>Timer or DispatchQueue\.asyncAfter for beats, because they drift\. Target: less than 10 ms drift<br>after 1 minute at 40/80/120 BPM\.
- The Play screen animates from BeatClock ticks, not from its own timer, so visuals cannot drift<br>from the metronome\.
- Network I/O stays off the main thread\. Incoming strum messages are decoded and de\-duplicated on<br>the link's own queue\. UI updates reach the main actor only through AsyncStream consumed on<br>@MainActor\. Callbacks must never touch UI directly\.
- Wrap non\-Sendable Apple state \(AVAudioEngine, NWConnection, ModelContext outside the main actor\)<br>in an actor or confine it to one queue\. Do not use @unchecked Sendable to silence the compiler;<br>that is a signal the type needs a redesign\.
- The controller link lives for the whole app session, not per practice session: do not tear it<br>down on pause, finish or Restart, because reconnecting can take several seconds\. Strums that<br>arrive while no session is playing are ignored, not judged\.
- If the controller disconnects during playing, the session pauses\. It does not keep judging<br>missing strums as Miss\.
- The iPad must not auto\-lock while the app is in the foreground \(the link drops when it does\)\.<br>When the app goes to the background, the session pauses\.
- Cancellation matters\. Every long\-running Task \(clock, feedback loop, replay, link reconnect\) is<br>stored as a handle on its owner and cancelled on pause, restart, finish and disappearance\. A<br>leaked task firing after the user has moved on is a real bug class in this app\.
- Never save a half\-finished session\. Restart and Back to Menu discard the result\.

## 8\. Testing: required, not optional

Every new reduce, pure function, repository method and view\-model transition needs a unit test in<br>the same change\. Most of this code is cheap to test well because services sit behind protocols\.

Must be covered:

*[Table view](https://miro.com/app/board/uXjVHkyk_dA=/?moveToWidget=3458764688044301550&cot=14)*

| Component | What to test |
| --- | --- |
| reduce functions | Every transition, illegal events ignored, pause → resume → finish |
| TimingJudge | On\-time, early, no onset, late onset \(Miss\), double onset, positive and negative latency offset |
| SessionResult | Accuracy, counts, empty beat list \(no divide\-by\-zero\) |
| RecommendationPolicy | Boundaries 50, 51, 65, 66, 85, 86 and BPM at the min/max clamp |
| SessionRepository | Save, fetch, ordering, using an in\-memory ModelContainer |
| ControllerLink | Clock conversion, duplicate packets, ordering, reconnects, and connection state changes |
| ViewModels | Fakes injected through initialisers; assert state transitions |

Rules:

- Use ModelConfiguration\(isStoredInMemoryOnly: true\) for SwiftData tests and previews\. Do not<br>hand\-roll a separate schema for tests\.
- Mock the controller and clock through their protocols \(MockControllerLink, MockBeatClock\)\. Do not<br>try to unit\-test the real network link; keep that adapter thin and verify it manually on a real<br>iPad \+ iPhone pair\.
- SwiftUI Views are not unit\-tested\. Provide a \#Preview for every state instead\.
- Test names read as sentences describing behaviour, for example test\_lateStrum\_isJudgedAsMiss\.
- Tests must pass before a PR is merged\.

## 9\. Timing, controller and feedback specifics

- Judgement results: Perfect, Too Early, Miss\. A strum that is too late counts as Miss\. There is<br>no "Too Late" state\.
- Feedback is colour only, in real time and in Replay\. Do not add icons, shapes or text to the<br>beat nodes unless the team decides to\.
- We judge timing and strum direction, not chords\. Each strum carries its direction \(down/up\) from<br>the swipe; a strum in the wrong direction inside a step's window makes that step a Miss, even if a<br>right one follows \(ARCHITECTURE\.md decision 18\)\. There is still no separate "wrong direction" result\.
- A strum's time is when the finger moved on the iPhone, converted to iPad clock time using the<br>clock offset measured by the link's ping/pong\. Never judge by the time the message arrived on the<br>iPad: network delay would count against the player\.
- Strums may be sent more than once \(redundant UDP\) and must be de\-duplicated inside the link,<br>before they reach TimingJudge\. One strum is one StrumEvent\.
- TimingJudge is a pure function\. One strum can satisfy only one beat\. Tolerance values live in one<br>ToleranceConfig, never hard\-coded inside the judge\.
- FeedbackEngine emits each BeatEvent as soon as that beat's window closes, not at the end of the<br>session\.
- Latency offset \(from calibration, stored in SettingsStore\) is applied inside TimingJudge\. Do not<br>apply it anywhere else\. It compensates for audio output delay \(for example Bluetooth headphones\)<br>and how the player perceives the beat, not for network delay \(that is handled by the clock offset\)\.
- The metronome and the pattern example are scheduled by the same BeatClock, never by a second clock\.
- The guitar sound and metronome play on the iPad only\. The iPhone controller is silent\.
- Wi\-Fi Aware publishing has a time limit\. When the session is old, the link is refreshed before<br>the count\-in, never during playing\.
- Contracts are shared between developers and must not change unilaterally: BeatResult, BeatEvent,<br>StrumEvent, SessionResult, ControllerLink, BeatClock, SessionRepository, SettingsStore\. If one must<br>change, discuss it first and update ARCHITECTURE\.md\.
- Replay does not take controller input and does not re\-judge\. It re\-plays stored \[BeatEvent\]<br>visually and audibly\. The colour sequence must match the original session exactly\.
- Recommendation rules live in RecommendationPolicy \(a pure function, config\-driven, clamped to<br>40…120\), not in a View\. The popup appears on every Retry, including the "stay at the same BPM" tier\.
- Records on pattern cards are sorted by accuracy \(best first\), three visible, the rest scroll\.<br>Ties go to the more recent session\.

## 10\. Adding a new feature: the expected workflow

1. Start with models and contracts\. Add or extend the struct/enum, and the protocol if a new service<br>capability is needed\. Add a mock\.
2. Write the pure logic and its tests \(reduce, judge, policy\) before any UI exists\.
3. If it touches persistence, extend PracticeSessionRecord and the mapper in Core/Data, and update<br>the in\-memory round\-trip test\. Declare a new schema version if the model changes\.
4. If it touches audio or the controller link, extend the relevant service behind its existing<br>protocol\. Do not add an ad hoc access path\.
5. Build the ViewModel, injected with protocols only\. Test it against mocks\.
6. Build the View with design tokens and shared components \(BeatNodeView, BackButton\)\. Add a<br>\#Preview for every state\.
7. Add the route to AppRouter, and wire dependencies in AppContainer\.swift\.
8. Update Docs/ARCHITECTURE\.md if the change affects structure, a contract, or a logged decision\.

## 11\. Explicitly out of scope for the MVP: do not build these unprompted

- Showtime \(song selection, scrolling chords, star ratings\)\. Its button exists on Home and must have<br>no action: no navigation, no "Coming Soon" message\.
- A separate History screen\. History is the records on pattern cards\.
- Microphone input or audio strum detection\.
- Guitar sound on the iPhone controller\.
- Any backend, internet call, account, or cloud sync\.
- Chord recognition\. Practice never requires playing a chord\.
- Locking patterns behind progress\. All patterns are open\.
- CI configuration and SwiftLint/SwiftFormat config \(deferred\)\.
- Script\-style deletion of records: not in the acceptance criteria\. If it comes up, ask first\.

If a task seems to require any of the above, stop and ask rather than quietly expanding scope\.

## 12\. Common pitfalls in this codebase

- Using Timer for the beat clock\. It drifts\. Use audio time\.
- Saving the session more than once\. Save exactly once, when the summary first appears\.<br>Re\-appearing must not create a duplicate\.
- Saving a discarded session\. Restart and Back to Menu throw the result away\.
- Judging by arrival time instead of touch time\. Use the iPhone touch time converted with the clock offset\.
- Counting a redundant UDP copy as a second strum\. De\-duplicate in the link\.
- Tearing down and re\-creating the controller link per session\. It is slow to reconnect; keep it alive\.
- Judging Miss while the controller is disconnected\. Pause instead\.
- Hard\-coding tolerance, BPM thresholds or colours inside a View or service\. Use ToleranceConfig,<br>RecommendationPolicy and design tokens\.
- Passing a @Model object or large object across screens\. Routes carry ids and primitive values only<br>\(for example patternID and bpm\)\.
- Creating a second source of truth for BPM\. selectedBPM is owned by the pattern list view model and<br>passed forward\. An accepted recommendation updates it; a rejected one leaves it alone\.
- @Model actor\-isolation errors\. The fix belongs inside Core/Data \(consistent @MainActor or<br>ModelActor usage\), never as a reason to loosen concurrency checking elsewhere\.
- Assuming the link is always fast\. Latency depends on the transport \(Wi\-Fi Aware vs regular Wi\-Fi\)<br>and the environment; it is shown on the controller and must be checked on real devices\.
- Adding a "Too Late" result\. The design has only Perfect, Too Early and Miss\.

## 13\. Git and review workflow

- Branches: main is always stable, dev is the integration branch\. Create every branch from dev and<br>merge back into dev by Pull Request\. dev is merged into main only at stable milestones decided by the PM\.
- One branch per piece of work, however small\.
- Branch names: Feat/US\- and Fix/US\-, lowercase<br>with hyphens\. Examples: Feat/US1\-beat\-clock, Fix/US3\-countin\-delay\.
- Commit messages: describe what was done\. One commit is one clear change\. Avoid empty messages such<br>as "update" or "fix"\.
- Pull Requests: one reviewer is required before merge\. UI PRs are reviewed by Ce Gefo\. Code PRs are<br>reviewed by Axel\. A PR that touches both is reviewed by both\. A reviewer does not merge their own<br>PR\. The PR description names the user story and subtask \(for example "US 1, subtask 1\.3"\)\.
- AI\-assisted code gets the same review as any other code\. The author must read and understand it<br>before committing, and should mention in the PR when AI wrote most of it\. Do not paste secrets or<br>personal data into prompts\.
- Changes to CLAUDE\.md and ARCHITECTURE\.md go through a PR and are reviewed like code\.

## 14\. Definition of done \(PR checklist\)

- [ ] New or changed logic has unit tests \(reduce, judge, policy, repository, view model\)
- [ ] No dependency crosses a boundary described in §4
- [ ] No force\-unwraps, try\! or as\! introduced
- [ ] No Timer or asyncAfter used for beat timing
- [ ] Long\-running tasks have explicit cancellation; strums outside a playing session are ignored
- [ ] SwiftData changes include an updated in\-memory round\-trip test and a schema version if needed
- [ ] Colours, fonts and spacing come from design tokens \(and meet the contrast rules in §15\)
- [ ] \#Preview exists for every new screen state
- [ ] Docs/ARCHITECTURE\.md updated if structure, a contract, or a logged decision changed
- [ ] Build succeeds with no new warnings, and all tests pass

## 15\. Accessibility \(colour contrast\)

- Text must meet 4\.5:1 contrast against its background\. Large text and UI components \(buttons, beat<br>nodes\) must meet 3:1 \(WCAG AA\)\.
- Perfect, Too Early, Miss, idle and active colours are checked against the brown background in Figma<br>before handoff, and implemented as design tokens\.
- Feedback stays colour\-only \(a team decision\), so the three result colours must be clearly<br>distinguishable from each other\.
- The UI reviewer \(Ce Gefo\) also checks contrast during PR review\.

## 16\. Build and test commands

```shell
# Run unit tests from Xcode: Command-U

# Or from the repository root after the test target exists
xcodebuild test \
  -project StrumMeng.xcodeproj \
  -scheme StrumMeng \
  -destination 'platform=iOS Simulator,name=iPad (A16)'
```

Controller behaviour, link latency and timing feel can only be verified on a physical iPad and a<br>physical iPhone \(paired, both running the app\)\. The simulator cannot run Wi\-Fi Aware and is not<br>useful for judging timing\.

## 17\. When unsure

This document and Docs/ARCHITECTURE\.md cover the decisions made so far\. For anything they do not<br>cover \(new scope, a contract change, a tooling change, a structural decision\), ask rather than<br>assuming\. That has been the working style on this project from the start; keep it that way\.
