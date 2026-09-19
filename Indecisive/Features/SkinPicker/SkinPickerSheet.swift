import SwiftUI

/// The "Skins" sheet, opened from Home's header (or a long-press on the
/// title). Picking a tile writes `@AppStorage(SkinID.storageKey)` and
/// dismisses immediately — no separate "save" step, no lingering on the
/// sheet after the choice is made — and the whole app crossfades via
/// `AppRoot`'s `.animation(.easeInOut, value:)`, plus a light selection
/// haptic here. "Done" stays as the way to back out without changing
/// anything.
struct SkinPickerSheet: View {
    @AppStorage(SkinID.storageKey) private var skinIDRaw: String = SkinID.defaultID.rawValue
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(SkinID.allCases) { id in
                        SkinPreviewTile(
                            skin: Skin.skin(for: id),
                            isSelected: id == SkinID.resolving(skinIDRaw)
                        ) {
                            skinIDRaw = id.rawValue
                            dismiss()
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Skins")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sensoryFeedback(.selection, trigger: skinIDRaw)
    }
}
