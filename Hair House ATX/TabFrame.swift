import SwiftUI

/// A hand-built bar rather than TabView: `.tabItem` renders only Image and Text, so the
/// Canvas marks this app is drawn with would simply never appear inside one.
struct TabFrame: View {
    @EnvironmentObject private var datebook: Datebook
    @State private var tab = 0

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch tab {
                case 0: HomeView(openMenu: { tab = 1 })
                case 1: ServicesView()
                case 2: VisitsView()
                default: StudioView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // A ScrollView draws its content through the top inset by design — fine under a
            // navigation bar, but nothing here has one, so rows would ride over the clock.
            // Clipping to the content area is what actually stops it.
            .clipped()

            bar
        }
        // Painted through `.background` rather than as a ZStack sibling: a sibling that
        // ignores the safe area stretches the stack, and the scrolling content above then
        // runs under the clock. A background fills the screen without moving the layout.
        .background(Tone.page.ignoresSafeArea())
        // No screen here carries a navigation bar, so scrolled content would otherwise ride
        // up over the status bar. A zero-height band that ignores the top inset expands into
        // it and paints it out, without taking part in layout.
        .overlay(
            Tone.page
                .frame(height: 0)
                .ignoresSafeArea(edges: .top),
            alignment: .top
        )
    }

    private var bar: some View {
        VStack(spacing: 0) {
            Hairline()
            HStack(spacing: 0) {
                button(index: 0, label: "Home") { DoorMark(size: 22, color: tint(0)) }
                button(index: 1, label: "Services") { StrandMark(size: 22, color: tint(1)) }
                button(index: 2, label: "Visits") { TicketMark(size: 22, color: tint(2)) }
                button(index: 3, label: "Studio") { MirrorMark(size: 22, color: tint(3)) }
            }
            .padding(.top, 9)
            .padding(.bottom, 3)
            .background(Tone.cardLifted.ignoresSafeArea(edges: .bottom))
        }
    }

    private func tint(_ index: Int) -> Color {
        tab == index ? Tone.accent : Tone.letterSoft.opacity(0.65)
    }

    private func button<Mark: View>(index: Int, label: String,
                                    @ViewBuilder mark: () -> Mark) -> some View {
        Button(action: { tab = index }) {
            VStack(spacing: 5) {
                mark()
                Text(label)
                    .font(Tone.figure(10, .semibold))
                    .tracking(0.7)
                    .foregroundColor(tint(index))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
