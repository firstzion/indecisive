import SwiftUI

/// The small marker at the start of each item row inside a list: a
/// monospaced index number (8-Ball), an outlined flavor-colored square
/// (Wheel) or a tiny two-tone capsule (Gashapon).
struct RowMarker: View {
    let skin: Skin
    let index: Int
    let flavorIndex: Int

    private var flavor: Color {
        let flavors = skin.palette.flavors
        guard !flavors.isEmpty else { return skin.palette.accent }
        return flavors[flavorIndex % flavors.count]
    }

    var body: some View {
        switch skin.id {
        case .eightBall:
            Text(String(format: "%02d", index + 1))
                .font(skin.type.mono(12))
                .foregroundStyle(skin.palette.chevron)
                .frame(width: 20, alignment: .leading)

        case .prizeWheel:
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(flavor)
                .frame(width: 14, height: 14)
                .overlay {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .strokeBorder(skin.palette.primaryText, lineWidth: 2)
                }

        case .gashapon:
            CapsuleBall(top: flavor, size: 18, seamOpacity: 0.2, glossy: false)
        }
    }
}
