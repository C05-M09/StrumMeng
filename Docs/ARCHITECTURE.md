# StrumMeng — iPadOS Architecture &amp; Feature Analysis

Status: Design document, written before implementation\. Nothing described here is built yet; every<br>section reads as design, not as description\. Items marked \[Assumption\] have not been confirmed by the<br>team and should be revisited\. \(A throwaway prototype of the controller link and guitar sound exists;<br>it informs §3\.2\.3 and §9 but is not the implementation\.\)

Scope: MVP = Practice, Guidebook, per\-pattern records, Option\. Showtime is out of scope \(its button is<br>visible on Home but not connected\)\.

Target platform: iPadOS 26\+ \(host\) and iOS 26\+ \(iPhone controller\), SwiftUI, Swift<br>\[Assumption: Xcode 26\+; confirm whether Swift 6 language mode is enabled\]\. iOS/iPadOS 26 is required<br>for Wi\-Fi Aware\.

The app name is not final \(the design still shows "APP TITLE"\)\. Replace \[App Name\] here and in<br>CLAUDE\.md once it is chosen\.

## 1\. Architecture at a glance

Core rule: Views show state and send events\. ViewModels own state machines and trigger side effects\.<br>Services \(audio output, clock, controller link, persistence\) sit behind protocols so each can be<br>mocked\. Nothing above a service ever imports AVFoundation, Network or SwiftData directly\.

The app runs on two devices from one universal target:

- iPad \(host\): every screen in this document, guitar sound, metronome, beat clock, judging, records\.
- iPhone \(controller\): a full\-screen touch pad\. A swipe is a strum; it is sent to the iPad\. The iPhone<br>plays no sound and stores no records\.

*[Table view](https://miro.com/app/board/uXjVHkyk_dA=/?moveToWidget=3458764688044234784&cot=14)*

| Concern | Decision | Why \(short version\) |
| --- | --- | --- |
| Architectural style | MVVM \+ state machine, single app target organised by folders | Team of 4 developers and a small MVP\. Packages would add overhead without solving a real problem yet\. |
| UI | SwiftUI only | No UIKit legacy\. |
| State management | @Observable \(Observation framework\) | Needs iOS 17, which is already the minimum\. Less boilerplate than ObservableObject\. |
| Feature logic | Per\-feature enum State, enum Event, pure reduce\(state, event\) \-&gt; State | Transitions are unit\-testable without UI, audio or a device\. |
| Persistence | SwiftData behind a SessionRepository protocol | Native, needs iOS 17\. Only the repository touches ModelContext\. |
| Settings | UserDefaults behind SettingsStore \[Assumption\] | Four scalar values\. SwiftData would be overkill\. |
| Controller input | ControllerLink over Wi\-Fi Aware with Bonjour fallback | Both transports produce the same de\-duplicated, host\-clock StrumEvent stream behind a mockable protocol\. |
| Beat timing | Audio\-time clock behind BeatClock | Timer and asyncAfter drift\. See §6\. |
| Navigation | One AppRouter over NavigationStack | A single place that knows every route\. |
| Dependency injection | Manual constructor injection from a composition root | No framework needed at this scale\. |
| Testing | XCTest \(unit\) \[Assumption\] | Safe for every Xcode version\. Swift Testing can replace it later if the whole team is on Xcode 16\+\. |

## 2\. Confirmed product decisions

- MVP covers Practice, Guidebook, records and Option only\. Showtime is deferred\. Its button appears on<br>Home but does nothing \(no navigation, no "Coming Soon" message\)\.
- Feedback is by colour only, in real time\. Three results: Perfect, Too Early, Miss\. A strum that is<br>too late counts as Miss\. There is no "Too Late" state and no shape or icon difference between results\.
- The app judges timing and strum direction, not chords\. Practice does not require playing a chord\.<br>Each step must be strummed in its direction \(down/up\); a strum in the wrong direction inside a<br>step's window makes that step a Miss \(see §3\.2\.2 and decision 18\)\.
- Input is a paired iPhone used as a strum controller \(companion\)\. The player swipes on the iPhone;<br>each strum is sent to the iPad over a local peer\-to\-peer link\. There is no microphone input \(see §4\.2\)\.
- All patterns are open from the start\. There is a suggested order, but nothing is locked\. Order:<br>Foundation, Subdivision, Syncopation, The Upbeat, Dynamic\.
- BPM is chosen by the user on the pattern list screen, range 60 to 120\. A session repeats the selected<br>pattern 10 times; its duration is derived from the pattern's beat count and selected BPM\.
- Replay shows the previous session again, visually and audibly\. It does not start a new session and<br>does not re\-judge anything\.
- Retry shows a BPM recommendation\. The user can accept it \(new BPM\) or reject it \(keep the old BPM\)\.<br>The popup appears for every accuracy tier, including "stay at the same BPM"\.
- "History" means the records shown on each pattern card\. There is no separate history screen\. The<br>card shows the user's records for that pattern, sorted best to worst\. Three are visible, the rest scroll\.
- Local\-first, single user, no backend, no accounts, no internet\. The only network traffic is the<br>local link between the player's own iPhone and iPad\.
- iPadOS/iOS 26 is the minimum \(Wi\-Fi Aware; also covers SwiftData and @Observable\)\.
- Accessibility focus for the MVP is colour contrast \(WCAG AA\)\. Colour\-only feedback is an accepted<br>trade\-off \(see §10\)\.

## 3\. Feature\-by\-feature analysis

### 3\.1 Practice flow \(US 2, US 3\)

Flow: pattern list \(choose pattern and BPM\) → Listen → Ready → count\-in 3\-2\-1 → Play \(10 pattern repetitions\) → Summary\.

#### 3\.1\.1 Pattern list and BPM

```swift
enum Stroke: String, Codable, Sendable {
    case down, up, rest
}

struct StrumPattern: Identifiable, Codable, Sendable, Equatable {
    let id: String              // stable slug, for example "foundation"
    let name: String
    let strokes: [Stroke]
    let beatLabels: [String]    // "1", "&", "2", "&" ...
    let beatsPerPattern: Int
    let suggestedOrder: Int
    let defaultBPM: Int
}
```

- PatternCatalog\.all holds the five confirmed patterns in suggested order: Foundation Strum,
  Subdivision Strum, Syncopation Strum, The Upbeat Strum, and Dynamic Strum\.
- Patterns are stored as stable ids in session records, never as copies, so renaming a pattern updates old records\.
- PatternListViewModel owns the selected pattern and selectedBPM\. On this list, BPM changes in steps
  of 5 and is clamped to 60…120\. Selecting another pattern resets BPM to that pattern's default\.
- Each card shows name, arrow notation, and the record area \(§3\.3\)\.
- Each card shows the calculated session duration next to BPM\. Duration is<br>`10 × beatsPerPattern × 60 / BPM` seconds\. Values below one minute are shown in seconds;<br>longer values use minutes and any remaining seconds\.
- Selecting a pattern routes to Listen with only patternID and bpm, never a large object\.

#### 3\.1\.2 Practice session state machine

```swift
enum PracticeState: Equatable {
    case idle
    case listening
    case ready
    case countIn(Int)           // 3, 2, 1
    case playing
    case paused
    case finished(SessionResult)
}

enum PracticeEvent {
    case startListening, replayExample, tapNext, tapReady
    case countInTick, countInDone
    case tapPause, tapResume, tapRestart, tapBackToMenu
    case controllerDisconnected, appMovedToBackground
    case sessionEnded(SessionResult)
}

func reduce(_ state: PracticeState, _ event: PracticeEvent) -> PracticeState {
    /* pure state transition; side effects belong to the ViewModel */
}
```

- Illegal transitions are ignored \(for example tapReady while playing\)\.
- The ViewModel turns state changes into side effects: entering playing starts the clock and<br>metronome and starts accepting strums from the controller\. Entering paused stops the clock and<br>metronome, and incoming strums are ignored\. The controller link itself stays connected\.
- Pause alert offers Resume, Restart, Back to Menu\. Restart and Back to Menu discard the session\. A<br>half\-finished session is never saved\.
- Resume continues from the last beat, after a short re\-count \[Assumption\]\.
- Interruptions \(phone call, system alert, app to background\) and a controller disconnect move the<br>session to paused automatically\. A disconnect never produces Miss results\.

#### 3\.1\.3 Listen screen

The user hears the correct pattern before playing\. It can be replayed any number of times, then Next<br>leads to Ready\. PatternPlayer plays the pattern at the chosen BPM \(a guitar sample or click\-accent<br>sound \[Assumption\]; the prototype synthesises the guitar sound on device\) and stops when the user<br>leaves the screen\.

#### 3\.1\.4 Ready, count\-in and Play

- Ready is a screen with a single Ready button\. It is enabled only while a controller is connected;<br>otherwise it shows the connection status \(§3\.2\.4\)\.
- If the Wi\-Fi Aware session is close to its time limit, it is refreshed after Ready and before the<br>count\-in, and the count\-in waits until the controller is back \(§3\.2\.3\)\.
- After it, a 3\-2\-1 count\-in aligned to the beat interval at the chosen BPM\. After "1", the session<br>enters playing exactly on the first beat\.
- Play renders the pattern as a row of beat nodes with a moving beat marker\. The marker is driven by<br>BeatClock ticks, never by its own timer\.
- The metronome is scheduled by the same BeatClock\. Volume follows SettingsStore\.soundVolume\.
- Beat node colours come from design tokens, not hard\-coded values\.

### 3\.2 Real\-time feedback engine \(US 1, US 6\)

Everything that deals with strum input and time lives here\. It is isolated so the rest of the app can<br>be built against mocks from day one\.

#### 3\.2\.1 Contracts \(agree these first, before writing any implementation\)

```swift
enum BeatResult: String, Codable, Sendable {
    case perfect, tooEarly, miss
}

enum StrumDirection: String, Codable, Sendable {
    case down, up
}

struct BeatTick: Sendable, Equatable {
    let index: Int
    let expectedTime: TimeInterval       // iPad host-clock seconds
}

struct StrumEvent: Identifiable, Codable, Sendable, Equatable {
    let id: UUID                          // used to de-duplicate UDP copies
    let direction: StrumDirection
    let time: TimeInterval                // touch time converted to iPad host clock
}

struct BeatEvent: Codable, Sendable, Equatable {
    let index: Int
    let expectedTime: TimeInterval
    let strumTime: TimeInterval?          // nil when no strum matched the beat
    let direction: StrumDirection?        // judged: must match the step's stroke (decision 18)
    let result: BeatResult
}

struct SessionResult: Codable, Sendable, Equatable {
    let id: UUID
    let patternID: String
    let bpm: Int
    let duration: TimeInterval
    let beats: [BeatEvent]

    var perfectCount: Int { beats.filter { $0.result == .perfect }.count }
    var tooEarlyCount: Int { beats.filter { $0.result == .tooEarly }.count }
    var missCount: Int { beats.filter { $0.result == .miss }.count }
    var accuracy: Double { beats.isEmpty ? 0 : Double(perfectCount) / Double(beats.count) }
    var offTempoCount: Int { tooEarlyCount + missCount }
}

enum ControllerConnectionState: Sendable, Equatable {
    case unpaired, pairing, searching, reconnecting
    case connected(latencyMs: Double)
}

protocol ControllerLink: Sendable {
    var connectionStates: AsyncStream<ControllerConnectionState> { get }
    var strums: AsyncStream<StrumEvent> { get }
    func start() async throws
    func refreshIfNeeded() async throws
    func stop() async
}

protocol BeatClock: Sendable {
    var beatStream: AsyncStream<BeatTick> { get }
    func start(bpm: Int) async
    func pause() async
    func resume() async
    func stop() async
}
```

Every type above has a mock \(MockControllerLink emits scripted strums: on\-time, early, skipped, and<br>connect/disconnect events; MockBeatClock ticks deterministically\)\. Tech 2 and Tech 3 build their flows<br>against mocks until the real link exists\.

#### 3\.2\.2 Timing judgement

- TimingJudge is a pure function: \[BeatTick\], \[StrumEvent\], latencyOffset, ToleranceConfig in, \[BeatEvent\] out\.
- A strum is paired with the nearest beat inside that beat's window\. One strum can satisfy only one beat\.
- Within the Perfect window of the \(latency\-corrected\) beat time: Perfect\.
- Before the Perfect window but inside the early window: Too Early\.
- No strum inside the window, including a strum that arrives too late: Miss\.
- Direction \(decision 18\): each judged step expects its stroke's direction\. Strums inside the window<br>are read in time order\. A strum in the wrong direction makes the step a Miss at once, even if a<br>right one follows\. A right\-direction strum in the Perfect window makes it Perfect at once\. Rest<br>steps are never judged\.
- The clock's BeatTick carries no direction, so the view model pairs each tick with the pattern's<br>Stroke as a BeatTarget \(index, expectedTime, direction\) before handing it to the judge\.
- ToleranceConfig \(perfectWindowMs, earlyWindowMs\) lives in one place so it is easy to tune\. Windows<br>are capped to a fraction of the beat interval so they never overlap at high BPM\. Actual values come<br>from on\-device testing \(§9\)\.
- FeedbackEngine consumes beatStream and strums and emits each BeatEvent as soon as that beat's window<br>closes, not at the end of the session\. This is what makes colours appear in real time\.
- SessionResultBuilder collects events and produces a SessionResult on finish\(\)\. A session ended by<br>Restart or Back to Menu produces nothing\.

#### 3\.2\.3 Controller link and strum input

- Gesture \(iPhone\): a swipe with N fingers \(default 2\) past a distance threshold is one strum; the<br>direction comes from the swipe\. Single\-finger touches are ignored so the palm can rest on the screen\.<br>Sensitivity, finger count and invert are controller settings stored on the iPhone\.
- Transport: Wi\-Fi Aware \(iOS 26\) is the primary path: the devices are paired once with the system<br>pairing UI \(DeviceDiscoveryUI\), then connect directly without a router\. Regular Wi\-Fi via Bonjour<br>with a 6\-digit pair code is the fallback\. Both use the same message format\.
- Messages: UDP\. Each strum is sent several times \(3 copies\) so one lost packet does not lose the<br>strum; the iPad de\-duplicates them inside the link before they become a StrumEvent\.
- Timing: the strum time is when the finger moved on the iPhone, not when the message arrived\. The<br>link measures a clock offset between the two devices with ping/pong \(lowest round trip of recent<br>samples\) and converts the iPhone touch time into iPad host time\. Network delay therefore does not<br>count against the player\.
- Liveness: the iPhone pings every second\. No message for about 4–5 seconds means disconnected; the<br>link reconnects automatically\.
- Wi\-Fi Aware publishing has a system time limit; when it expires the connection drops\. The link<br>requests a long publish duration, restarts publishing when it expires, and is refreshed before a<br>session starts if it is old \(§3\.1\.4\), never during playing\.
- Network I/O runs off the main thread\. Strums reach the UI only through AsyncStream consumed on @MainActor\.
- The link lives for the whole app session, not per practice session, because reconnecting can take<br>several seconds\. Strums that arrive while no session is playing are ignored\.
- The iPad must not auto\-lock while the app is in the foreground, because the link drops when it does\.
- Required Info\.plist entries: NSBonjourServices, WiFiAwareServices, NSLocalNetworkUsageDescription,<br>and the Wi\-Fi Aware entitlement\.

#### 3\.2\.4 Connection state and indicator \(US 6\)

ControllerConnectionState machine: \.unpaired, \.pairing, \.searching, \.connected\(latencyMs\),<br>\.reconnecting\. Before the first session the iPad explains how to set up the iPhone \(open the app on<br>the iPhone, pair once\)\. A small indicator on the iPad shows whether a controller is connected; the<br>iPhone shows its own connection status and the measured latency\. The system local\-network / pairing<br>prompts are shown by iOS; if the user declines, a message explains how to allow it in Settings\.

### 3\.3 Results: Summary, Replay, Retry, records \(US 4, US 8\)

#### 3\.3\.1 Summary

Shows pattern, BPM, duration, accuracy \(%\), counts of Perfect, Too Early and Miss, and an "off tempo N<br>times" message \(Too Early plus Miss\)\. No stars in Practice\. Buttons: Replay, Retry, Back to Main\.

SummaryState: \.showing\(SessionResult\), \.showingRecommendation\(RecommendedBPM\), \.navigating\(destination\)\.<br>The session is saved exactly once, when the summary first appears, so re\-appearing never creates a duplicate\.

#### 3\.3\.2 Replay

Replay plays the previous session again, visually and audibly, from the stored \[BeatEvent\]\. It takes<br>no controller input and does no new judging\. The colour sequence must match the original session exactly\.

Audio is reconstructed, not recorded: the metronome and pattern are re\-scheduled from the stored beat<br>times, and the player's own strums are re\-played as guitar strums at their stored times and<br>directions\. There is no microphone recording to play back\.

#### 3\.3\.3 Retry and BPM recommendation

RecommendationPolicy is a pure function: recommend\(accuracy:currentBPM:\) \-&gt; Recommendation\. Initial<br>rules \[Assumption: BPM deltas are placeholders\]:

*[Table view](https://miro.com/app/board/uXjVHkyk_dA=/?moveToWidget=3458764688044234793&cot=14)*

| Accuracy | Recommendation |
| --- | --- |
| 0 to 50% | Decrease 20 BPM |
| 51 to 65% | Decrease 10 BPM |
| 66 to 85% | Stay at the same BPM |
| 86 to 100% | Increase 10 BPM |

The result is clamped to 40…120\. Thresholds and deltas live in configuration, not in a View\. Accept<br>returns to Ready with the new BPM \(without repeating Listen \[Assumption\]\)\. Reject keeps the old BPM\.<br>The accuracy bands match the team's star\-scoring scale used for the deferred Showtime feature\.<br>Practice never shows the stars\.

#### 3\.3\.4 Records on pattern cards

- Each card shows records for that pattern: BPM, accuracy, Perfect, Too Early, Miss\.
- Sorted by accuracy, best to worst\. Three records are visible; the rest scroll inside the card\.
- Pattern never played: an empty state\.
- The list refreshes when the user returns from a session, without restarting the app\.
- Ties in accuracy are broken by the more recent session \[Assumption\]\.

### 3\.4 Persistence

```swift
@Model
final class PracticeSessionRecord {
    @Attribute(.unique) var id: UUID
    var patternID: String
    var bpm: Int
    var playedAt: Date
    var duration: TimeInterval
    var perfectCount: Int
    var tooEarlyCount: Int
    var missCount: Int
    var accuracy: Double
    var beatsData: Data                    // [BeatEvent] encoded as JSON
}

protocol SessionRepository: Sendable {
    func save(_ result: SessionResult) async throws
    func fetch(id: UUID) async throws -> SessionResult?
    func records(patternID: String) async throws -> [SessionResult]
}
```

- Beats are stored as one JSON blob per session rather than one @Model row per beat\. It is much<br>simpler for Replay and there is no need to query individual beats\.
- The ModelContainer is created in App/ and injected into the repository, never into a View\.
- A VersionedSchema is declared from the first version so later migrations are cheap\.
- Domain code only sees SessionResult, never PracticeSessionRecord\. A small mapper translates between them\.
- All access runs on a single, consistent actor context \(@MainActor or a ModelActor\)\. The in\-memory<br>configuration \(isStoredInMemoryOnly: true\) is used in tests and previews\.
- Records live on the iPad only\. The iPhone controller stores nothing but its own controller settings\.

### 3\.5 Guidebook \(US 5\)

Three read\-only pages: Counting Beats, Practice Tempo, How to Strum\. Content is stored as local data<br>\(GuidebookPage: title, body, image\), not hard\-coded inside the View, so text can change without<br>touching UI\. Opened from the Guidebook icon on Home, with a Back button to return\.<br>\[Assumption\] "How to Strum" may need a page or a note about holding the iPhone controller\.

### 3\.6 Home, navigation and Option \(US 7, US 9\)

- Home: Practice, Option, Guidebook icon, and a Showtime button that is visible but has no action\.
- AppRouter: one @Observable object owning a NavigationPath and a single enum Route \(home,<br>practiceList, listen, ready, play, summary, replay, guidebook, option\)\. Methods: push, pop,<br>popToRoot\. Routes carry ids and primitive values only\. No scattered NavigationLinks\.
- Back button: one shared BackButton component used on every screen\. No screen is a dead end\.
- Option: two sliders \(Sound, Sound Effects\), latency calibration, and the controller connection\.
    - Sound: metronome and pattern example volume\.
    - Sound Effects: effect volume\.
    - Controller: connection type \(Wi\-Fi Aware / Wi\-Fi\), pairing, and status\.
    - The Microphone slider in the current design has no function without mic input and should be<br>removed or replaced by the controller section \(design change, needs the Designer\)\.
    - Changes apply immediately, even during a session, and persist across launches\.
- Latency calibration: CalibrationState: idle, instructions, measuring\(n/total\), computing,<br>done\(offsetMs\), failed\. The app plays a beat, the user swipes along on the iPhone, the app collects<br>samples \(8 \[Assumption\]\), takes the median difference between strum and beat as the offset, and<br>discards outliers\. Network delay is already removed by the clock offset \(§3\.2\.3\), so this measures<br>audio output delay \(for example Bluetooth headphones\) and the player's perception\. The offset is<br>saved in SettingsStore and used by TimingJudge\. When it appears \(manual only, or also on first<br>launch\) is still undecided\.

## 4\. Alternatives considered

### 4\.1 Judging up vs down strokes

Adopted \(decision 18, replacing decision 14\)\. With the companion controller \(and the on\-iPad swipe<br>input used before it\) the direction is known exactly from the swipe, so TimingJudge checks it: a<br>wrong\-direction strum in a step's window is a Miss\. There is still no "wrong direction" result;<br>the three results stay Perfect, Too Early and Miss\.

### 4\.2 Microphone input instead of a companion controller

The original concept detected strums from the iPad microphone\. It was replaced by the iPhone<br>controller because detection reliability was unproven, the metronome can leak from the speaker into<br>the mic and be counted as strums, up/down detection was unreliable, and it needs microphone<br>permission\. The trade\-off: feedback is now on the swipe on the iPhone, not on the sound of the real<br>guitar\. This was a product decision, not only a technical one\.

### 4\.3 Other architectures

*[Table view](https://miro.com/app/board/uXjVHkyk_dA=/?moveToWidget=3458764688044234794&cot=14)*

| Alternative | Why not chosen |
| --- | --- |
| Clean Architecture with local Swift packages | Compiler\-enforced boundaries are valuable, but the cost in setup and in learning for a 4\-developer MVP is not justified yet\. Folder boundaries plus protocols give most of the benefit\. Revisit if the codebase grows\. |
| Plain MVVM without state machines | The practice session has many states \(listen, ready, count\-in, play, pause, finish\) and many transitions that interact with audio\. Scattered booleans would produce illegal states\. |
| TCA / reducer framework | Strong testability but a steep learning curve and a third\-party dependency\. Our hand\-rolled reduce gives the same testability for the features that need it\. |
| Storing each beat as a SwiftData row | More queryable, but nothing in the MVP queries beats\. JSON is simpler\. |

## 5\. Module structure

Single app target, organised by folders\. Folder names use PascalCase\.

```text
StrumMeng/                         app target
├── App/                           entry point, AppContainer, AppRouter, device role
├── Core/
│   ├── Models/                    domain models and shared contracts
│   ├── Services/
│   │   ├── Audio/                 BeatClock, Metronome, PatternPlayer
│   │   ├── Connectivity/          ControllerLink, transports, clock sync, de-duplication
│   │   ├── Practice/              TimingJudge, FeedbackEngine, SessionResultBuilder
│   │   └── Settings/              SettingsStore
│   ├── Data/                      PracticeSessionRecord, mapper, SessionRepository
│   └── DesignSystem/              tokens, typography, BeatNodeView, BackButton
└── Features/
    ├── Home/
    ├── Practice/
    │   ├── List/                  cards, BPM picker, records
    │   ├── Listen/
    │   ├── Play/                  Ready, count-in, Play, pause alert
    │   ├── Summary/               result and recommendation popup
    │   └── Replay/
    ├── Guidebook/
    ├── Option/
    │   └── Calibration/
    └── Controller/
        ├── Connection/            pairing and connection status on iPad
        └── Touchpad/              swipe input and status on iPhone

StrumMengTests/                    mirrors Core and Features
└── TestSupport/                   MockControllerLink, MockBeatClock, fixtures
```

Dependency direction\. Features depend on Core\. Core/Services and Core/Data never depend on Features\.<br>A Feature never imports another Feature; shared things move to Core\. AppContainer is the only place<br>that wires concrete implementations to protocols\. \[Assumption\] This is enforced by review and<br>CLAUDE\.md rules, not by the compiler, since there are no packages\.

Dependency injection\. A single AppContainer, assembled once in the app entry point, exposes factory<br>methods \(makeHomeViewModel\(\), makePracticeSessionViewModel\(patternID:bpm:\), and so on\)\. ViewModels<br>receive dependencies through their initialisers, which is what keeps them testable\. AppContainer also<br>decides the device role \(iPad = host, iPhone = controller\)\.

## 6\. Concurrency and performance

- Beat clock: driven by audio time \(AVAudioEngine with AVAudioPlayerNode scheduled at AVAudioTime, or<br>mach\_absolute\_time if simpler\)\. Never Timer or DispatchQueue\.asyncAfter, because they drift\. Target:<br>less than 10 ms of drift after 1 minute at 40, 80 and 120 BPM \[Assumption\]\.
- Threads: network messages are received and decoded off the main thread\. UI updates happen on<br>@MainActor through streams\. Callbacks must never touch UI directly\.
- UI animation: the Play screen animates from clock ticks, not from its own timer, so visuals cannot<br>drift from the metronome sound\.
- Controller link lifetime: the whole app session; strums are only accepted while playing\.
- Layout: the Play screen should run without visible frame drops on a real iPad \[Assumption\]\.
- Actors: services that wrap non\-Sendable Apple state \(AVAudioEngine, network connections\) are<br>isolated in an actor or confined to a single queue\. Do not silence the compiler with @unchecked Sendable\.
- Cancellation: every long\-running task \(clock, feedback loop, replay, link reconnect\) is stored as a<br>handle and cancelled on pause, restart, finish and view disappearance\.

## 7\. Testing strategy

Tests must pass before a PR is merged\. Dependencies \(controller link, clock, repository\) are mocked<br>through their protocols\.

*[Table view](https://miro.com/app/board/uXjVHkyk_dA=/?moveToWidget=3458764688044234799&cot=14)*

| Layer | Approach |
| --- | --- |
| reduce functions \(all state machines\) | Unit tests for every transition, including illegal ones being ignored and pause then resume then finish |
| TimingJudge | On\-time, early, no onset, late onset \(Miss\), double onset, positive and negative latency offset |
| SessionResult | Accuracy, counts, empty beat list \(no divide\-by\-zero\) |
| RecommendationPolicy | Boundaries 50, 51, 65, 66, 85, 86, and BPM at the min/max clamp |
| SessionRepository | Save, fetch, ordering by accuracy, against an in\-memory ModelContainer |
| ControllerLink | Host\-clock conversion, duplicate packets, ordering, reconnects, and state changes |
| ViewModels | Fakes injected through initialisers; assert state transitions |
| Physical iPad and iPhone | Manual checks for pairing, fallback transport, backgrounding, reconnection, latency, and timing feel |
| Views | SwiftUI Previews for every state, no automated UI tests in the MVP |

## 8\. Accessibility

Focus: colour contrast\. Text meets 4\.5:1, large text and UI components such as beat nodes meet 3:1<br>\(WCAG AA\)\. Perfect, Too Early, Miss, idle and active colours are checked against the brown background<br>in Figma before handoff, and implemented as design tokens\. Feedback is by colour only \(a team<br>decision\), so the three result colours must also be clearly distinguishable from each other\.

Accepted risk: users with colour\-vision deficiency may find it hard to tell results apart\. Revisit<br>after user feedback\.

## 9\. Open questions and risks

*[Table view](https://miro.com/app/board/uXjVHkyk_dA=/?moveToWidget=3458764688044234803&cot=14)*

| \# | Item | Notes |
| --- | --- | --- |
| 1 | Controller link latency and reliability | Biggest risk\. Measure Wi\-Fi Aware and Bonjour fallback on real iPad/iPhone pairs, including reconnects and background/foreground transitions\. |
| 2 | Clock synchronisation and UDP de\-duplication | Verify touch timestamps are converted to iPad host time and redundant packets never become extra strums\. |
| 3 | Replay timing fidelity | Reconstruct from stored BeatEvent data and verify that visual colours and scheduled sounds match the original session\. |
| 4 | ToleranceConfig values | Perfect and early windows must be tuned on a real iPad with a real guitar\. |
| 5 | Recommendation BPM deltas | Placeholders \(20 / 10 / 0 / \+10\)\. Tune after testing with users\. |
| 6 | Latency calibration behaviour | Manual only or also on first launch; how many samples; what happens if it fails\. |
| 7 | Session length and BPM range | Resolved: 10 pattern repetitions per session and 60…120 BPM\. |
| 8 | Connection indicator placement | On Ready, on Play, or both\. |
| 9 | Xcode / Swift version and language mode | Needed to settle strict concurrency and testing framework\. |

## 10\. Decisions log

*[Table view](https://miro.com/app/board/uXjVHkyk_dA=/?moveToWidget=3458764688044234806&cot=14)*

| \# | Question | Decision |
| --- | --- | --- |
| 1 | Include Showtime in the MVP? | No\. The button is visible on Home with no action\. |
| 2 | Package\-based Clean Architecture or folders? | Folders in one app target, protocols for every service\. |
| 3 | How is state modelled? | Enum state machines with a pure reduce, one per feature that needs it\. |
| 4 | How do we judge a late strum? | As Miss\. The design has only Too Early and Miss\. |
| 5 | Is the result shown with anything besides colour? | No\. Colour only, during play and in Replay\. |
| 6 | Where is BPM chosen? | On the pattern list screen, not on Listen or Ready\. |
| 7 | What does Replay do? | Re\-shows the previous session visually and audibly from stored data\. No new judging\. |
| 8 | Does the recommendation popup always appear on Retry? | Yes, including the "stay at the same BPM" tier\. |
| 9 | Is there a History screen? | No\. Records on pattern cards are the history\. Sorted best to worst, three visible, scrollable\. |
| 10 | How are beats stored? | One JSON blob per session inside the SwiftData record\. |
| 11 | Where do settings live? | UserDefaults behind SettingsStore\. |
| 12 | Is latency calibration in the MVP? | Yes, inside Option\. |
| 13 | Is the Guidebook in the MVP? | Yes, three pages\. |
| 14 | Do we detect strum direction? | Superseded by 18\. \(Was: no for the MVP, timing only\.\) |
| 15 | Who reviews pull requests? | One reviewer\. UI PRs: Ce Gefo\. Code PRs: Axel\. |
| 16 | Which test framework? | XCTest for now\. May move to Swift Testing if the whole team is on Xcode 16\+\. |
| 17 | How long is a Practice session? | Repeat the selected pattern 10 times; calculate duration from its beat count and selected BPM\. |
| 18 | Is strum direction judged? | Yes\. Each step must be strummed in its direction; a wrong\-direction strum inside the step's window makes it a Miss immediately, even if a right one follows\. Results stay Perfect, Too Early, Miss\. |

## 11\. Suggested implementation order

1. Contracts and mocks first \(BeatResult, BeatEvent, StrumEvent, SessionResult, protocols,<br>MockControllerLink, MockBeatClock\)\. Everyone unblocks here\.
2. In parallel: Tech 1 builds the controller link \(port from the prototype: pairing, transport, clock<br>sync, de\-duplication\) and BeatClock\. Tech 3 builds the SwiftData schema and SessionRepository\.<br>Tech 4 builds AppRouter and SettingsStore\.
3. TimingJudge, FeedbackEngine, SessionResultBuilder \(pure logic, fully unit\-tested\)\.
4. Pattern list, Listen, Ready, count\-in, Play against mocks \(Tech 2\)\.
5. Summary, recommendation, Retry, Replay \(Tech 3\)\.
6. Records on cards, Option, calibration, Guidebook, Home \(Tech 4 and Tech 3\)\.
7. Swap mocks for the real controller link, then run the end\-to\-end tests on a real iPad with a real<br>paired iPhone\.

The riskiest piece \(link latency and reliability in the real environment\) is measured early, so a<br>problem is discovered in the first days, not at the end\.

## 12\. Repository layout, tooling and conventions

```text
./                                repository root
├── StrumMeng.xcodeproj
├── StrumMeng/                     app target; folders from §5
├── StrumMengTests/                XCTest target and TestSupport
├── Docs/
│   └── ARCHITECTURE.md
├── CLAUDE.md
├── README.md
└── .gitignore
```

- Branches: main \(always stable\) and dev \(integration\)\. Feature branches come from dev and merge back<br>into dev by Pull Request\. dev merges into main at stable milestones\.
- Branch names: Feat/US\- and Fix/US\-, for<br>example Feat/US1\-beat\-clock\.
- Naming: camelCase for variables and functions, PascalCase for types and folders\.
- Tests: run with ⌘U in Xcode, or xcodebuild test with an iPad simulator destination\. The controller<br>link and timing feel are only verifiable on a physical iPad and iPhone \(the simulator cannot run Wi\-Fi Aware\)\.
- Not configured yet: CI, SwiftLint, SwiftFormat\. Follow the style rules in CLAUDE\.md manually until<br>tooling exists\.

This document is the design reference\. CLAUDE\.md at the repository root is the companion that turns it<br>into day\-to\-day working rules for anyone, human or Claude, writing code here\.
