import SwiftUI
import WebKit

struct HairHouseWebPanel: UIViewRepresentable {
    let address: String

    func makeUIView(context: Context) -> WKWebView {
        let settings = WKWebViewConfiguration()
        settings.allowsInlineMediaPlayback = true

        let panel = WKWebView(frame: .zero, configuration: settings)
        panel.allowsBackForwardNavigationGestures = true
        // Belt and braces — the real guarantee against the notch is the frame, set where the
        // panel is presented. Never .never: that always draws under the clock.
        panel.scrollView.contentInsetAdjustmentBehavior = .always
        panel.isOpaque = true
        // The studio's own page colour, so any safe-area band matches the app rather than
        // flashing white.
        panel.backgroundColor = UIColor(red: 0.969, green: 0.973, blue: 0.969, alpha: 1)

        if let url = URL(string: address) {
            panel.load(URLRequest(url: url))
        }
        return panel
    }

    /// Must stay empty. Loading here reloads the page on every SwiftUI re-render, which reads
    /// as a page that will not settle.
    func updateUIView(_ panel: WKWebView, context: Context) {}
}

/// The Privacy Policy entry from the Studio screen. Opens the same address the app checks on
/// launch — one page to keep current rather than two — and with no redirect check of its own.
struct PolicyScreen: View {
    @Environment(\.presentationMode) private var presentation

    var body: some View {
        ZStack {
            Tone.page.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Privacy Policy")
                        .font(Tone.display(18))
                        .foregroundColor(Tone.letter)
                    Spacer()
                    Button(action: { presentation.wrappedValue.dismiss() }) {
                        CloseMark(size: 17, color: Tone.letter)
                            .frame(width: 40, height: 40)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, Span.gutter)
                .padding(.vertical, 12)
                Hairline()

                HairHouseWebPanel(address: HairHouseGate.sourceLink)
            }
        }
    }
}
