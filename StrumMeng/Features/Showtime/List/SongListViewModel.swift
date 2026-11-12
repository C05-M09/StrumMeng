import Observation

@MainActor
@Observable
final class SongListViewModel {
    let songs: [Song]
    @ObservationIgnored private let onSelect: (Song) -> Void
    @ObservationIgnored private let onBack: () -> Void

    init(catalog: any SongCatalog, onSelect: @escaping (Song) -> Void, onBack: @escaping () -> Void) {
        songs = catalog.songs; self.onSelect = onSelect; self.onBack = onBack
    }
    func select(_ id: String) {
        guard let song = songs.first(where: { $0.id == id }) else { return }
        onSelect(song)
    }
    func back() { onBack() }
}
