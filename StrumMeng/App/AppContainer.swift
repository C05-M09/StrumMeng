import Foundation

@MainActor
final class AppContainer {

    private let router: AppRouter
    private let repository: SessionRepository?
    private let settings: any SettingsStore
    private let results = SessionResultStore()
    /// The one pattern list of the app, so Retry can hand it the chosen tempo.
    private weak var patternListViewModel: PatternListViewModel?
    /// One synthesised guitar for the whole app, made when a screen first needs it. Notes are
    /// synthesised right away, so they are ready before the first strum.
    private lazy var guitar: GuitarEngine? = {
        let engine = GuitarEngine()
        if let engine { Task { await engine.prepare() } }
        return engine
    }()
    private var guitarSound: any GuitarSound { guitar ?? SilentGuitarSound() }
    private var metronomeSound: any MetronomeSound { guitar ?? SilentGuitarSound() }
    /// One link for the whole app session: reconnecting takes seconds, so sessions never restart it.
    private var controllerLink: (any ControllerLink)?

    init(
        router: AppRouter,
        inMemory: Bool = false,
        settings: (any SettingsStore)? = nil
    ) {
        self.router = router
        self.settings = settings ?? UserDefaultsSettingsStore()

        do {
            let modelContainer = try ModelContainerFactory.make(
                inMemory: inMemory
            )
            repository = SwiftDataSessionRepository(
                modelContainer: modelContainer
            )
        } catch {
            // Show a records error when storage cannot be initialized.
            repository = nil
        }
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            onPracticeRequested: { [weak router] in
                router?.push(.practiceList)
            }
        )
    }

    func makeListenViewModel(pattern: StrumPattern, bpm: Int) -> ListenViewModel {
        ListenViewModel(
            pattern: pattern,
            bpm: bpm,
            player: SynthListenPlayer(sound: guitarSound),
            onReady: { [weak router] in router?.push(.play(patternID: pattern.id, bpm: bpm)) },
            onBack: { [weak router] in router?.popTo(.practiceList) }
        )
    }

    func makePlayViewModel(pattern: StrumPattern, bpm: Int) -> PlayViewModel {
        // Swipes on the iPad screen keep working next to the iPhone, so the iPhone is optional.
        let touch = TouchStrumInputService()
        let link = sharedControllerLink()
        return PlayViewModel(
            pattern: pattern,
            bpm: bpm,
            clock: AudioBeatClock(),
            input: MergedStrumInputService(sources: [link, touch]),
            touchInput: touch,
            controller: link,
            requiresController: false,
            guitar: guitarSound,
            metronome: metronomeSound,
            strumArrivalGrace: PlayViewModel.controllerStrumArrivalGrace,
            now: HostClock.now,
            waitUntil: { time in
                let delay = time - HostClock.now()
                if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
            },
            onFinished: { [weak self] result in self?.sessionFinished(result) },
            onExit: { [weak router] in router?.popTo(.practiceList) }
        )
    }

    /// Play becomes Summary, so Back from Summary never returns to the finished session.
    func sessionFinished(_ result: SessionResult) {
        results.add(result)
        router.replaceLast(with: .summary(sessionID: result.id))
    }

    /// nil if the session is unknown (it never finished in this app session).
    func makeSummaryViewModel(sessionID: UUID) -> SummaryViewModel? {
        guard let result = results.result(for: sessionID) else { return nil }
        return SummaryViewModel(
            result: result,
            repository: repository ?? UnavailableSessionRepository(),
            onNavigate: { [weak self] destination in
                self?.navigate(from: result, to: destination)
            },
            makeReplayViewModel: { [guitar = guitarSound, metronome = metronomeSound] result in
                ReplayViewModel(result: result, guitar: guitar, metronome: metronome)
            }
        )
    }

    private func navigate(from result: SessionResult, to destination: SummaryDestination) {
        switch destination {
        case let .retry(bpm):
            // The chosen tempo becomes the list's tempo too, then the pattern is listened to again.
            patternListViewModel?.send(.setBPM(bpm))
            router.popTo(.practiceList)
            router.push(.listen(patternID: result.patternID, bpm: bpm))
        case .backToMain:
            router.popTo(.practiceList)
        case .replay:
            // Shown inside SummaryView.
            break
        }
    }

    func makePatternListViewModel() -> PatternListViewModel {
        let records = repository.map { repository in
            Dictionary(uniqueKeysWithValues: PatternCatalog.all.map { pattern in
                (pattern.id, RecordsViewModel(patternID: pattern.id, repository: repository))
            })
        } ?? [:]
        let viewModel = PatternListViewModel(
            recordsViewModels: records,
            recordsFallbackState: repository == nil ? .failed : .empty,
            onListenRequested: { [weak router] patternID, bpm in
                router?.push(.listen(patternID: patternID, bpm: bpm))
            },
            onBackRequested: { [weak router] in
                router?.pop()
            }
        )
        patternListViewModel = viewModel
        return viewModel
    }

    /// Option is an overlay on Home, so whoever shows it decides what "back" means
    /// (close the overlay), instead of popping the router.
    func makeOptionViewModel(onBackRequested: @escaping () -> Void) -> OptionViewModel {
        OptionViewModel(
            settings: settings,
            onBackRequested: onBackRequested,
            onSetUpDeviceRequested: { [weak router] in router?.push(.deviceSetup) }
        )
    }

    /// Static because the iPhone needs none of the iPad's storage, audio or routes.
    static func makeCompanionViewModel(deviceName: String) -> CompanionViewModel {
        CompanionViewModel(
            client: BonjourControllerClient(deviceName: deviceName),
            pairCodes: UserDefaultsPairCodeStore(),
            makeGuitar: { GuitarEngine() }
        )
    }

    func makeDeviceSetupViewModel() -> DeviceSetupViewModel {
        DeviceSetupViewModel(link: sharedControllerLink(), onClose: { [weak router] in router?.pop() })
    }

    /// Made on first use, so an AppContainer that never needs the iPhone never opens the network.
    private func sharedControllerLink() -> any ControllerLink {
        if let controllerLink { return controllerLink }
        let link = BonjourControllerLink(pairCode: UserDefaultsPairCodeStore().hostPairCode())
        controllerLink = link
        return link
    }

    /// Up from launch, so a paired iPhone reconnects before the player reaches Play. A failure stays
    /// quiet here: on-screen swipes still work, and Set Up Device tries again and explains it.
    func startControllerLink() async {
        try? await sharedControllerLink().start()
    }

    func stopControllerLink() {
        guard let link = controllerLink else { return }
        controllerLink = nil
        Task { await link.stop() }
    }

    /// Guidebook is an overlay on Home, so whoever shows it decides what "back" means
    /// (close the overlay), instead of popping the router.
    func makeGuidebookViewModel(onBackRequested: @escaping () -> Void) -> GuidebookViewModel {
        GuidebookViewModel(
            player: SynthListenPlayer(sound: guitarSound, metronome: metronomeSound),
            onBackRequested: onBackRequested
        )
    }
}
