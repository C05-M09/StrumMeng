import UIKit

/// The single app target runs as the host (main screen, sound, judging) on iPad and as the strum
/// controller on iPhone.
enum DeviceRole: Equatable {
    case host
    case controller

    init(idiom: UIUserInterfaceIdiom) {
        self = idiom == .phone ? .controller : .host
    }

    static var current: DeviceRole {
        DeviceRole(idiom: UIDevice.current.userInterfaceIdiom)
    }
}
