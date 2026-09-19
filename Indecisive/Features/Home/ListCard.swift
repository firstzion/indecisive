import SwiftUI

/// One row on the Home screen: badge, name, item count, chevron.
struct ListCard: View {
    let skin: Skin
    let list: PickList

    var body: some View {
        HStack(spacing: 14) {
            ListBadge(skin: skin, flavorIndex: list.flavorIndex, itemCount: list.items.count)
            VStack(alignment: .leading, spacing: 2) {
                Text(list.name)
                    .font(skin.compactTitleFont(19))
                    .foregroundStyle(skin.palette.primaryText)
                    .lineLimit(1)
                Text(skin.copy.countLine(list.items.count))
                    .font(skin.type.body(13, weight: .semibold))
                    .foregroundStyle(skin.palette.secondaryText)
            }
            Spacer(minLength: 8)
            Text("›")
                .font(skin.type.body(22, weight: .bold))
                .foregroundStyle(skin.palette.chevron)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .indCard(skin)
        .contentShape(Rectangle())
        // Without this, VoiceOver reads the badge, name, count and "›"
        // chevron as four separate stops on one row. One combined element
        // with an explicit label reads naturally instead.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(list.name), \(skin.copy.countLine(list.items.count))")
        .accessibilityAddTraits(.isButton)
        // Stable, copy-independent hook for UI tests — the label above
        // changes with the skin and item count, this doesn't.
        .accessibilityIdentifier("listRow-\(list.name)")
    }
}
