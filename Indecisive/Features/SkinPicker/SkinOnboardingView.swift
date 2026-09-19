import SwiftUI

/// First-launch "Choose your toy" step, shown once before Home. Reuses the
/// same live-preview tiles as the Home "Skins" sheet — picking one both
/// selects the skin and completes onboarding in a single tap, so there's
/// no separate "Continue" button to design or forget to wire up.
///
/// Deliberately skin-neutral chrome (system colors, system font): no skin
/// has been chosen yet, so there's nothing to theme this screen *with*.
struct SkinOnboardingView: View {
    @Binding var skinIDRaw: String
    @Binding var hasChosenSkin: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 6) {
                    Text("Rand-o-matic")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                    Text("Choose your toy")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                VStack(spacing: 16) {
                    ForEach(SkinID.allCases) { id in
                        SkinPreviewTile(skin: Skin.skin(for: id), isSelected: false) {
                            skinIDRaw = id.rawValue
                            hasChosenSkin = true
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .sensoryFeedback(.selection, trigger: hasChosenSkin)
    }
}
