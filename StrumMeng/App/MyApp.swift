import SwiftUI

@main struct MyApp: App {
    init() {
        AppFontRegistrar.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            // Until the controller screens exist: the iPhone, or an iPad launched with
            // -controllerLinkDebug, opens the link test screen.
            if DeviceRole.current == .controller || ProcessInfo.processInfo.arguments.contains("-controllerLinkDebug") {
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
