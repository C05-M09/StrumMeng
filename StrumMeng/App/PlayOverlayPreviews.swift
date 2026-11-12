import SwiftUI

// The modal on its own is in PauseMenuOverlay's style; these show it where the player sees it, on
// the Play screen while the session is paused because the iPhone dropped.
#if DEBUG
#Preview("Paused - reconnecting", traits: .landscapeLeft) {
    PracticePlayView(model: PracticePlayDemoView.model(songTime: 5,
                                                       disconnected: .disconnected(isReconnected: false)))
}

#Preview("Paused - iPhone back", traits: .landscapeLeft) {
    PracticePlayView(model: PracticePlayDemoView.model(songTime: 5,
                                                       disconnected: .disconnected(isReconnected: true)))
}
#endif
