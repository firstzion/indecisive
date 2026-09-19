import SwiftUI

/// The larger badge on the list-detail screen's header — the same shape
/// language as `ListBadge` but bigger and idly animated. The 8-Ball is a
/// deliberate exception: it shows the branded white-diamond-with-"8" mark
/// instead of the list's own flavor color, since this spot reads as "this
/// is an 8-ball list" rather than "here's list #N's color" (matches the
/// source design exactly — the small home-row icon is flavor-tinted, the
/// big detail hero isn't).
struct HeroBadge: View {
    let skin: Skin
    let flavorIndex: Int
    let itemCount: Int
    var size: CGFloat = 56

    @State private var floatUp = false
    @State private var spinAngle = 0.0
    @Environment(\.indReducedMotion) private var reduceMotion

    private var flavor: Color {
        let flavors = skin.palette.flavors
        guard !flavors.isEmpty else { return skin.palette.accent }
        return flavors[flavorIndex % flavors.count]
    }

    var body: some View {
        Group {
            switch skin.id {
            case .eightBall:
                // The 8-ball's own shell black (`revealBackground`) and its
                // ivory-diamond white (`primaryText`) — the same two colors
                // `ListBadge`, `PrimaryCTAGlyph` and `RevealCentrepiece` use
                // for the identical mark.
                Circle()
                    .fill(skin.palette.revealBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: size * 0.08, style: .continuous)
                            .fill(skin.palette.primaryText)
                            .frame(width: size * 0.5, height: size * 0.5)
                            .overlay {
                                Text("8")
                                    .font(skin.type.display(size * 0.24))
                                    .foregroundStyle(skin.palette.revealBackground)
                                    .rotationEffect(.degrees(-45))
                            }
                            .rotationEffect(.degrees(45))
                    }
                    .offset(y: floatUp ? -6 : 0)
                    .onAppear {
                        guard !reduceMotion else { return }
                        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                            floatUp = true
                        }
                    }

            case .prizeWheel:
                WheelFill(wedgeCount: wheelWedgeCount(forItemCount: itemCount), colors: skin.palette.flavors)
                    .overlay {
                        Circle().strokeBorder(skin.palette.primaryText, lineWidth: 3)
                    }
                    .rotationEffect(.degrees(spinAngle))
                    .onAppear {
                        guard !reduceMotion else { return }
                        withAnimation(.linear(duration: 9).repeatForever(autoreverses: false)) {
                            spinAngle = 360
                        }
                    }
            }
        }
        .frame(width: size, height: size)
    }
}
