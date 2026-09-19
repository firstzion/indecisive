import SwiftUI

/// The "create a new list" sheet: name + an optional flavour color. Not
/// specified by the source design mockups (PLAN.md §2's "Not in the
/// design" list) — this is a first pass and a good candidate to send back
/// through Claude Design once the core flow is working (PLAN.md §8.6).
struct NewListSheet: View {
    let skin: Skin
    let onCreate: (_ name: String, _ flavorIndex: Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var flavorIndex = 0
    @FocusState private var isFocused: Bool

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            // A ScrollView, not a bare VStack + trailing Spacer — at very
            // large Dynamic Type sizes the field and swatches could
            // otherwise outgrow the screen with no way to reach "Create".
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    TextField(skin.copy.newListRow, text: $name)
                        .font(skin.type.display(22, weight: .bold, relativeTo: .body))
                        .foregroundStyle(skin.palette.primaryText)
                        .focused($isFocused)
                        .padding(16)
                        .background(skin.palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: skin.shape.cardRadius, style: .continuous))
                        .submitLabel(.done)
                        .accessibilityIdentifier("newListNameField")
                        .onSubmit(createIfValid)

                    if skin.palette.flavors.count > 1 {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Flavour")
                                .font(skin.type.body(13, weight: .semibold))
                                .foregroundStyle(skin.palette.secondaryText)
                            HStack(spacing: 12) {
                                ForEach(Array(skin.palette.flavors.enumerated()), id: \.offset) { index, color in
                                    Circle()
                                        .fill(color)
                                        .frame(width: 34, height: 34)
                                        .overlay {
                                            Circle()
                                                .strokeBorder(skin.palette.primaryText, lineWidth: index == flavorIndex ? 3 : 0)
                                        }
                                        .onTapGesture { flavorIndex = index }
                                        .accessibilityLabel("Flavour \(index + 1)")
                                        .accessibilityAddTraits(index == flavorIndex ? [.isSelected] : [])
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(skin.palette.background)
            .navigationTitle("New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: createIfValid)
                        .disabled(trimmedName.isEmpty)
                        .fontWeight(.bold)
                }
            }
        }
        .tint(skin.palette.accent)
        .preferredColorScheme(skin.palette.colorScheme)
        .onAppear { isFocused = true }
    }

    private func createIfValid() {
        guard !trimmedName.isEmpty else { return }
        onCreate(trimmedName, flavorIndex)
        dismiss()
    }
}
