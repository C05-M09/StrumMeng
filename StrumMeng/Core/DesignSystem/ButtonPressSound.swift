import SwiftUI

/// Plays the button click the moment a button is pressed down, like a physical button.
/// Every shared button style applies it, so a new button clicks without extra code.
/// A disabled button never reports a press, so it stays silent.
struct ButtonPressSound: ViewModifier {
    let isPressed: Bool

    @Environment(\.playSoundEffect) private var playSoundEffect

    func body(content: Content) -> some View {
        content.onChange(of: isPressed) { _, pressed in
            if pressed { playSoundEffect(.button) }
        }
    }
}

extension View {
    /// Clicks when `isPressed` turns true. Used inside button styles.
    func clicksWhenPressed(_ isPressed: Bool) -> some View {
        modifier(ButtonPressSound(isPressed: isPressed))
    }
}
