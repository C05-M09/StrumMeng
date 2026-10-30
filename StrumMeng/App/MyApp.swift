import SwiftUI

@main struct MyApp: App {
    #if DEBUG
    /// Stays on across launches from the home screen, which carry no launch arguments.
    @AppStorage("playWithController") private var playWithController = false
    #endif

    init() {
        AppFontRegistrar.registerFonts()
        #if DEBUG
        // Launching once with -playWithController (e.g. from the Xcode scheme) remembers it.
        if ProcessInfo.processInfo.arguments.contains("-playWithController") {
            UserDefaults.standard.set(true, forKey: "playWithController")
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            // Until the controller screens exist: the iPhone, or an iPad launched with
            // -controllerLinkDebug, opens the link test screen; -playWithController opens Play
            // driven by the iPhone until its status bar's App button turns it off.
            if DeviceRole.current == .host, playWithController {
                ControllerPlayDebugView(onLeave: { playWithController = false })
            } else if DeviceRole.current == .controller
                        || ProcessInfo.processInfo.arguments.contains("-controllerLinkDebug") {
                ControllerLinkDebugView(model: ControllerLinkDebugModel(
                    role: DeviceRole.current, deviceName: UIDevice.current.name))
            } else if DeviceRole.current == .host {
                // The way back to controller gameplay after the status bar's App button.
                ContentView()
                    .overlay(alignment: .topTrailing) {
                        Button("Controller play") { playWithController = true }
                            .font(.caption.monospaced())
                            .foregroundStyle(AppColor.ink)
                            .padding(.horizontal, AppSpacing.m)
                            .padding(.vertical, AppSpacing.xs)
                            .background(AppColor.paper, in: Capsule())
                            .padding(AppSpacing.m)
                    }
            } else {
                ContentView()
            }
            #else
            ContentView()
            #endif
        }
    }
}
