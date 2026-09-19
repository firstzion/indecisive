import SwiftUI

/// One compact row in the skin picker: the real `ListBadge` icon plus the
/// skin's own name/tagline in its own type — rendered with that skin's
/// actual tokens and components, never a screenshot or a hand-drawn
/// approximation, so the preview can't drift from what picking it actually
/// looks like. Deliberately just the badge and not a full card-plus-button
/// sample (an earlier version showed both): picking a tile dismisses the
/// sheet immediately, so the real screen is one tap away regardless, and
/// all three rows need to fit on screen at once without scrolling.
struct SkinPreviewTile: View {
    let skin: Skin
    let isSelected: Bool
    let action: () -> Void

    /// Scales the selected-checkmark with Dynamic Type — see the identical
    /// note on `ItemRow`'s icon sizes.
    @ScaledMetric private var checkmarkSize: CGFloat = 20

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ListBadge(skin: skin, flavorIndex: 0, itemCount: 6)
                VStack(alignment: .leading, spacing: 2) {
                    Text(skin.name)
                        .font(skin.type.display(17, weight: .bold, relativeTo: .body))
                        .foregroundStyle(skin.palette.primaryText)
                    Text(skin.tagline)
                        .font(skin.type.body(12, weight: .semibold))
                        .foregroundStyle(skin.palette.secondaryText)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: checkmarkSize))
                        .foregroundStyle(skin.palette.accent)
                }
            }
            .padding(12)
            .background(skin.palette.background)
            .clipShape(RoundedRectangle(cornerRadius: skin.shape.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: skin.shape.cardRadius, style: .continuous)
                    .strokeBorder(isSelected ? skin.palette.accent : .clear, lineWidth: 3)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityIdentifier("skinTile-\(skin.id.rawValue)")
    }
}
