import SwiftUI

@main struct MyApp: App {
    init() {
        AppFontRegistrar.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            // The iPad is the host and opens Home; the iPhone is the controller.
            if DeviceRole.current == .controller {
                CompanionRootView(viewModel: AppContainer.makeCompanionViewModel(deviceName: UIDevice.current.name))
            } else {
                ContentView()
            }
        }
    }
}
