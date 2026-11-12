import XCTest
@testable import StrumMeng

@MainActor
final class SongListViewModelTests: XCTestCase {
    private var mockPlayer: MockShowtimeSongPlayer!
    private var selectedSongID: String?
    private var backRequested = false

    override func setUp() {
        super.setUp()
        mockPlayer = MockShowtimeSongPlayer()
        selectedSongID = nil
        backRequested = false
    }

    private func makeViewModel() -> SongListViewModel {
        SongListViewModel(
            player: mockPlayer,
            onSongSelected: { [weak self] id in self?.selectedSongID = id },
            onBackRequested: { [weak self] in self?.backRequested = true }
        )
    }

    func test_startPlayback_playsSelectedSong() {
        let viewModel = makeViewModel()
        viewModel.startPlayback()

        XCTAssertEqual(mockPlayer.playSongCalls, ["twinkle-twinkle"])
        XCTAssertEqual(mockPlayer.currentSongID, "twinkle-twinkle")
        XCTAssertTrue(mockPlayer.isPlaying)
    }

    func test_swipeLeft_switchesToNextSong_andPlaysIt() {
        let viewModel = makeViewModel()
        viewModel.startPlayback()

        viewModel.send(.swipeLeft)

        XCTAssertEqual(viewModel.state.selectedSong?.id, "jingle-bells")
        XCTAssertEqual(mockPlayer.playSongCalls, ["twinkle-twinkle", "jingle-bells"])
        XCTAssertEqual(mockPlayer.currentSongID, "jingle-bells")
    }

    func test_swipeRight_wrapsAroundToLastSong_andPlaysIt() {
        let viewModel = makeViewModel()
        viewModel.startPlayback()

        viewModel.send(.swipeRight)

        XCTAssertEqual(viewModel.state.selectedSong?.id, "down-by-the-riverside")
        XCTAssertEqual(mockPlayer.playSongCalls, ["twinkle-twinkle", "down-by-the-riverside"])
        XCTAssertEqual(mockPlayer.currentSongID, "down-by-the-riverside")
    }

    func test_multipleSwipes_switchSongsSequentially() {
        let viewModel = makeViewModel()

        viewModel.send(.swipeLeft) // jingle-bells
        viewModel.send(.swipeLeft) // abc-song
        viewModel.send(.swipeLeft) // row-row-row-your-boat
        viewModel.send(.swipeLeft) // down-by-the-riverside
        viewModel.send(.swipeLeft) // twinkle-twinkle

        XCTAssertEqual(viewModel.state.selectedSong?.id, "twinkle-twinkle")
        XCTAssertEqual(mockPlayer.playSongCalls, [
            "jingle-bells",
            "abc-song",
            "row-row-row-your-boat",
            "down-by-the-riverside",
            "twinkle-twinkle"
        ])
    }

    func test_selectSong_stopsPlayback_andCallsCallback() {
        let viewModel = makeViewModel()
        viewModel.startPlayback()

        viewModel.send(.selectSong)

        XCTAssertEqual(selectedSongID, "twinkle-twinkle")
        XCTAssertEqual(mockPlayer.stopCount, 1)
        XCTAssertFalse(mockPlayer.isPlaying)
    }

    func test_tapBack_stopsPlayback_andCallsCallback() {
        let viewModel = makeViewModel()
        viewModel.startPlayback()

        viewModel.send(.tapBack)

        XCTAssertTrue(backRequested)
        XCTAssertEqual(mockPlayer.stopCount, 1)
        XCTAssertFalse(mockPlayer.isPlaying)
    }

    func test_pauseAndResumePlayback() {
        let viewModel = makeViewModel()
        viewModel.startPlayback()

        viewModel.pausePlayback()
        XCTAssertEqual(mockPlayer.pauseCount, 1)
        XCTAssertFalse(mockPlayer.isPlaying)

        viewModel.resumePlayback()
        XCTAssertEqual(mockPlayer.resumeCount, 1)
        XCTAssertTrue(mockPlayer.isPlaying)
    }
}

