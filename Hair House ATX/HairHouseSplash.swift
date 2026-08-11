import SwiftUI

/// Held for the second or two the launch check takes, in the studio's evergreen on cool
/// white, so the wait reads as the app opening rather than as a blank frame.
struct HairHouseSplash: View {
    @State private var settling = false

    var body: some View {
        ZStack {
            Tone.page.ignoresSafeArea()
            StrandField(spacing: 34, opacity: 0.06).ignoresSafeArea()

            VStack(spacing: 22) {
                // The mark from the icon, redrawn: an evergreen ring around an open centre.
                ZStack {
                    Circle()
                        .stroke(Tone.accent, lineWidth: 2)
                        .frame(width: 76, height: 76)
                    Circle()
                        .fill(Tone.accent)
                        .frame(width: 26, height: 26)
                }
                .scaleEffect(settling ? 1.05 : 0.94)
                .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                           value: settling)

                VStack(spacing: 7) {
                    Text(Studio.name)
                        .font(Tone.display(25))
                        .foregroundColor(Tone.letter)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Kicker(text: "\(Studio.city), \(Studio.region)")
                }
            }
            .padding(.horizontal, 32)
        }
        .onAppear { settling = true }
    }
}
