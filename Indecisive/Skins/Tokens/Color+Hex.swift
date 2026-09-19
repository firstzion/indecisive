import SwiftUI

extension Color {
    /// A color from a 24-bit RGB hex literal, e.g. `Color(hex: 0xFF3B5C)`.
    /// Every skin palette value is defined this way so it matches the
    /// design's hex swatches exactly rather than approximating with a
    /// named system color.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
