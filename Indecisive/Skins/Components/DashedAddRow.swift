import SwiftUI

/// The dashed "+ …" row: adding an item within a list, or a new list on
/// Home. The 8-Ball sets the label in its display font (Lilita One); the
/// Wheel deliberately uses its *body* font here — Titan One reads too heavy
/// at this size — matching the source design.
struct DashedAddRow: View {
    let skin: Skin
    let label: String

    private var labelFont: Font { skin.compactTitleFont(16) }

    var body: some View {
        HStack(spacing: 8) {
            Text("+").font(labelFont)
            Text(label).font(labelFont)
        }
        .foregroundStyle(skin.palette.tertiaryText)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .overlay {
            RoundedRectangle(cornerRadius: skin.shape.dashedCornerRadius, style: .continuous)
                .strokeBorder(
                    skin.palette.dashedBorder,
                    style: StrokeStyle(lineWidth: skin.shape.dashedBorderWidth, dash: [7, 6])
                )
        }
    }
}
