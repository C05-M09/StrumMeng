import Foundation

@MainActor
final class AppContainer {

    private let router: AppRouter
    private let repository: SessionRepository?
    private let sessionHistory: (any SessionHistoryChecking)?
    private let settings: any SettingsStore
    private let pairingIntroductionStore: any PairingIntroductionStore
    /// One menu music and button click player for the whole app, so the music keeps its place
    /// between screens.
    private let menuSounds: any MenuSoundService
    private let results = SessionResultStore()
    private let songCatalog: any SongCatalog = DummySongCatalog()
    private let enablesHomeGuidance: Bool
    private let homeGuidanceStore: any HomeGuidanceStore
    /// The one pattern list of the app, so Retry can hand it the chosen tempo.
    private weak var patternListViewModel: PatternListViewModel?
    /// One synthesised guitar for the whole app, made when a screen first needs it. Notes are
    /// synthesised right away, so they are ready before the first strum.
    private lazy var guitar: GuitarEngine? = {
        let engine = GuitarEngine(chord: .c)
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
        settings: (any SettingsStore)? = nil,
        menuSounds: (any MenuSoundService)? = nil,
        pairingIntroductionStore: (any PairingIntroductionStore)? = nil,
        homeGuidanceStore: (any HomeGuidanceStore)? = nil,
        controllerLink: (any ControllerLink)? = nil
    ) {
        self.router = router
        self.homeGuidanceStore = homeGuidanceStore ?? UserDefaultsHomeGuidanceStore()
        self.controllerLink = controllerLink
        self.pairingIntroductionStore = pairingIntroductionStore ?? UserDefaultsPairingIntroductionStore()
        let settings = settings ?? UserDefaultsSettingsStore()
        self.settings = settings

        // The saved volumes apply from launch, before Option is ever opened.
        let sounds = menuSounds ?? AVMenuSoundService()
        sounds.setMusicVolume(settings.soundVolume)
        sounds.setEffectsVolume(settings.sfxVolume)
        self.menuSounds = sounds
        self.enablesHomeGuidance = !inMemory || homeGuidanceStore != nil

        do {
            let modelContainer = try ModelContainerFactory.make(
                inMemory: inMemory
            )
            let sessions = SwiftDataSessionRepository(modelContainer: modelContainer)
            repository = sessions
            sessionHistory = sessions
        } catch {
            // Show a records error when storage cannot be initialized.
            repository = nil
            sessionHistory = nil
        }
    }

    /// The UI sounds (clicks, garage, page turns, pop-ups, wheel ticks) for the iPad's views,
    /// put in the environment by ContentView. They follow the SFX volume like the rest.
    var soundEffectAction: SoundEffectAction {
        let sounds = menuSounds
        return SoundEffectAction { effect in sounds.play(effect) }
    }

    /// Plays or pauses the menu music for the screen on top. Called whenever the route stack or the
    /// app's active state changes; `MenuMusicPolicy` decides.
    func updateMenuMusic(for path: [AppRoute], isAppActive: Bool) {
        if MenuMusicPolicy.playsMusic(on: path.last, isAppActive: isAppActive) {
            menuSounds.startMusic()
        } else {
            menuSounds.pauseMusic()
        }
    }

    func makePairingIntroductionViewModel(isEnabled: Bool = true) -> PairingIntroductionViewModel {
        PairingIntroductionViewModel(
            store: pairingIntroductionStore,
            state: isEnabled ? .idle : .finished,
            onSetupRequested: { [weak router] in router?.push(.deviceSetup) }
        )
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            guidance: enablesHomeGuidance ? HomeGuidanceViewModel(store: homeGuidanceStore) : nil,
            onPracticeRequested: { [weak router] in
                router?.push(.practiceList)
            },
            onShowtimeRequested: { [weak router] in router?.push(.showtimeList) }
        )
    }

    func makeSongListViewModel() -> SongListViewModel {
        SongListViewModel(catalog: songCatalog,
            onSelect: { [weak router] song in router?.push(.showtime(songID: song.id)) },
            onBack: { [weak router] in router?.pop() })
    }

    func makeShowtimeViewModel(songID: String) -> ShowtimeViewModel? {
        guard let song = songCatalog.songs.first(where: { $0.id == songID }) else { return nil }
        let timeline = SongTimeline(song: song)
        let link = sharedControllerLink()
        let gameplay = PlayViewModel(pattern: timeline.sessionPattern, bpm: song.bpm,
            clock: AudioBeatClock(), input: link, touchInput: nil, controller: link,
            requiresController: true, metronome: metronomeSound,
            // Calibration is not exposed by SettingsStore yet; same zero offset as Practice.
            latencyOffset: 0,
            strumArrivalGrace: PlayViewModel.controllerStrumArrivalGrace,
            leadInSteps: 0, repetitions: 1, finishBreak: 0, finishesAtDurationBoundary: true,
            now: HostClock.now,
            waitUntil: { time in
                let delay = time - HostClock.now()
                if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
            })
        return ShowtimeViewModel(song: song,
            demo: PatternStrumDemoPlayer(clock: AudioBeatClock(), sound: guitarSound, now: HostClock.now),
            gameplay: gameplay, onBack: { [weak router] in router?.popTo(.showtimeList) })
    }

    func makeListenViewModel(pattern: StrumPattern, bpm: Int) -> ListenViewModel {
        ListenViewModel(
            pattern: pattern,
            bpm: bpm,
            player: SynthListenPlayer(sound: guitarSound),
            history: sessionHistory ?? UnavailableSessionRepository(),
            onReady: { [weak router] in router?.push(.play(patternID: pattern.id, bpm: bpm)) },
            onBack: { [weak router] in router?.popTo(.practiceList) }
        )
    }

    func makePlayViewModel(
        pattern: StrumPattern,
        bpm: Int,
        onFinished: ((SessionResult) -> Void)? = nil
    ) -> PlayViewModel {
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
            onFinished: onFinished ?? { [weak self] result in self?.sessionFinished(result) },
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
            reloadRecords()
        case .backToMain:
            router.popTo(.practiceList)
            reloadRecords()
        case .replay:
            // Shown inside SummaryView.
            break
        }
    }

    /// Summary waits for the save before navigating, so the new session is already stored here.
    private func reloadRecords() {
        Task { await patternListViewModel?.reloadRecords() }
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
            lastPlayedBPM: { [repository] patternID in
                guard let repository else { return nil }
                return try? await repository.lastPracticeBPM(forPattern: patternID)
            },
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
            sounds: menuSounds,
            onBackRequested: onBackRequested,
            onSetUpDeviceRequested: { [weak router] in router?.push(.deviceSetup) }
        )
    }

    /// Static because the iPhone needs none of the iPad's storage, audio or routes.
    static func makeCompanionViewModel(deviceName: String) -> CompanionViewModel {
        CompanionViewModel(
            client: BonjourControllerClient(deviceName: deviceName),
            pairCodes: UserDefaultsPairCodeStore(),
            makeGuitar: { GuitarEngine() },
            makeSounds: { AVMenuSoundService(files: .controller) }
        )
    }

    func makeDeviceSetupViewModel() -> DeviceSetupViewModel {
        let guidanceStore = homeGuidanceStore
        return DeviceSetupViewModel(
            link: sharedControllerLink(),
            onClose: { [weak router] in
                // Back also hands off to the Home tour, even without a paired device.
                guidanceStore.scheduleAfterSetup()
                router?.pop()
            }
        )
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
#if DEBUG
    /// Canvas-only flow: no persistence and no network; unplayed nodes are judged Miss normally.
    static func makeShowtimePreviewViewModel() -> ShowtimeViewModel {
        let song = DummySongCatalog().songs[0]
        let timeline = SongTimeline(song: song)
        let sound = SilentGuitarSound()
        let gameplay = PlayViewModel(pattern: timeline.sessionPattern, bpm: song.bpm,
            clock: AudioBeatClock(), input: TouchStrumInputService(), touchInput: nil,
            requiresController: false, metronome: sound, leadInSteps: 0, repetitions: 1,
            finishBreak: 0, finishesAtDurationBoundary: true, now: HostClock.now,
            waitUntil: { deadline in
                let delay = deadline - HostClock.now()
                if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
            })
        return ShowtimeViewModel(song: song,
            demo: PatternStrumDemoPlayer(clock: AudioBeatClock(), sound: sound, now: HostClock.now), gameplay: gameplay, onBack: {})
    }
#endif

}
