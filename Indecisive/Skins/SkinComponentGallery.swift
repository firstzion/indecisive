#if DEBUG
import SwiftUI

/// A visual QA screen showing every shared component across all three skins
/// side by side — the fastest way to check the Skins layer against the
/// original design mockups. Never part of the shipped navigation (`RootView`
/// goes straight to `HomeView`) — wrapped in `#if DEBUG` so these 90-odd
/// lines don't ship in the release binary at all. Still reachable via its
/// own `#Preview` below, or by temporarily swapping it into `RootView` for a
/// side-by-side check after a token or component change.
struct SkinComponentGallery: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                ForEach(SkinID.allCases) { id in
                    SkinSection(skin: Skin.skin(for: id))
                }
            }
            .padding(20)
        }
    }
}

private struct SkinSection: View {
    let skin: Skin

    private let sampleCounts = [14, 23, 9, 31, 7]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(skin.name).font(skin.type.display(22))
                Text(skin.tagline)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("List badges + hero badge").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                HStack(spacing: 14) {
                    ForEach(0..<5, id: \.self) { i in
                        ListBadge(skin: skin, flavorIndex: i, itemCount: sampleCounts[i])
                    }
                    HeroBadge(skin: skin, flavorIndex: 0, itemCount: 14, size: 56)
                }

                Text("Card + row markers + dashed add row").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { i in
                        HStack(spacing: 12) {
                            RowMarker(skin: skin, index: i, flavorIndex: i)
                            Text("Sample Item \(i + 1)")
                                .font(skin.type.body(15))
                                .foregroundStyle(skin.palette.primaryText)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 14)
                .indCard(skin)
                DashedAddRow(skin: skin, label: skin.copy.addRow)

                Text("Primary CTA").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                Button(skin.copy.ctaLabel) {}
                    .buttonStyle(PrimaryCTAStyle(skin: skin))

                Text("Reveal").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                ZStack {
                    skin.palette.revealBackground
                    VStack(spacing: 18) {
                        RevealKicker(skin: skin)
                        RevealCentrepiece(
                            skin: skin, winnerName: "Pho Palace", candidateCount: 14,
                            winnerWedgeIndex: 2, wedgeCount: 6
                        )
                        RevealActions(skin: skin, onAccept: {}, onReroll: {})
                    }
                    .padding(24)
                    Confetti(skin: skin)
                }
                .frame(height: 620)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .padding(16)
            .background(skin.palette.background)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
    }
}

#Preview {
    SkinComponentGallery()
}
#endif
