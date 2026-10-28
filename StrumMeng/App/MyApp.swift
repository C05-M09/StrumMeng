import SwiftUI

@main struct MyApp: App {
    init() {
        AppFontRegistrar.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            // Until the controller screens exist: the iPhone, or an iPad launched with
            // -controllerLinkDebug, opens the link test screen; -playWithController opens Play
            // driven by the iPhone. The latter can also be stored on a simulator so every Xcode
            // run keeps it: xcrun simctl spawn <device> defaults write <bundle id> playWithController -bool YES
            let arguments = ProcessInfo.processInfo.arguments
            let playWithController = arguments.contains("-playWithController")
                || UserDefaults.standard.bool(forKey: "playWithController")
            if DeviceRole.current == .host, playWithController {
                ControllerPlayDebugView()
            } else if DeviceRole.current == .controller || arguments.contains("-controllerLinkDebug") {
                ControllerLinkDebugView(model: ControllerLinkDebugModel(
                    role: DeviceRole.current, deviceName: UIDevice.current.name))
            } else {
                ContentView()
            }
            #else
            ContentView()
            #endif
        }
    }
}
