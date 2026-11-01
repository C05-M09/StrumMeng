import SwiftUI

@main struct MyApp: App {
    #if DEBUG
    /// Stays on across launches from the home screen, which carry no launch arguments.
    @AppStorage("playWithController") private var playWithController = false
    /// Keeps the link test screen reachable on the iPhone while the companion screens are dummies.
    @AppStorage("companionLinkTest") private var companionLinkTest = false
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
            // The iPhone opens the companion screens and its Link test button opens the link test
            // screen; so does an iPad launched with -controllerLinkDebug. -playWithController
            // opens Play driven by the iPhone until its status bar's App button turns it off.
            if DeviceRole.current == .host, playWithController {
                ControllerPlayDebugView(onLeave: { playWithController = false })
            } else if companionLinkTest && DeviceRole.current == .controller
                        || ProcessInfo.processInfo.arguments.contains("-controllerLinkDebug") {
                ControllerLinkDebugView(model: ControllerLinkDebugModel(
                    role: DeviceRole.current, deviceName: UIDevice.current.name))
                    .overlay(alignment: .bottomTrailing) {
                        if DeviceRole.current == .controller {
                            debugButton("Companion") { companionLinkTest = false }
                        }
                    }
            } else if DeviceRole.current == .host {
                // The way back to controller gameplay after the status bar's App button.
                ContentView()
                    .overlay(alignment: .topTrailing) {
                        debugButton("Controller play") { playWithController = true }
                    }
            } else {
                CompanionRootView(viewModel: AppContainer.makeCompanionViewModel(deviceName: UIDevice.current.name))
                    .overlay(alignment: .bottomTrailing) {
                        debugButton("Link test") { companionLinkTest = true }
                    }
            }
            #else
            if DeviceRole.current == .controller {
                CompanionRootView(viewModel: AppContainer.makeCompanionViewModel(deviceName: UIDevice.current.name))
            } else {
                ContentView()
            }
            #endif
        }
    }

    #if DEBUG
    private func debugButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.caption.monospaced())
            .foregroundStyle(AppColor.ink)
            .padding(.horizontal, AppSpacing.m)
            .padding(.vertical, AppSpacing.xs)
            .background(AppColor.paper, in: Capsule())
            .padding(AppSpacing.m)
    }
    #endif
}
