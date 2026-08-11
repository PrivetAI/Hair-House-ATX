import SwiftUI

/// The front screen leads with the soonest free appointment rather than a hero image. For a
/// studio that takes one guest at a time, that is the single fact somebody opens the app to
/// find out.
struct HomeView: View {
    @EnvironmentObject private var datebook: Datebook
    let openMenu: () -> Void

    @State private var now = Date()
    @State private var booking: Service?

    private let tick = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                soonest
                if let next = datebook.upcoming.first { yours(next) }
                shortlist
            }
            .padding(.horizontal, Span.gutter)
            .padding(.top, 10)
            .padding(.bottom, 36)
            .frame(maxWidth: Span.column, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(
            ZStack {
                Tone.page
                StrandField()
            }
            .ignoresSafeArea()
        )
        .onReceive(tick) { now = $0 }
        .sheet(item: $booking) { service in
            BookSheet(service: service).environmentObject(datebook)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 9) {
            Kicker(text: "\(Studio.city), \(Studio.region)")
            Text(Studio.name)
                .font(Tone.display(33))
                .foregroundColor(Tone.letter)
                .fixedSize(horizontal: false, vertical: true)
            DoorLine(state: DoorState.now(now))
        }
    }

    private var soonest: some View {
        Card(lifted: true) {
            VStack(alignment: .leading, spacing: 14) {
                Kicker(text: "Soonest appointment")

                if let opening = datebook.nextOpening(for: Studio.headline) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(Stamp.opening(opening.day, opening.slot.minutes))
                            .font(Tone.display(25))
                            .foregroundColor(Tone.letter)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(Studio.headline.name) with "
                             + "\(Studio.stylist(opening.slot.stylistId)?.name ?? "the studio") · "
                             + Studio.money(Studio.headline.priceCents))
                            .font(Tone.copy(14))
                            .foregroundColor(Tone.letterSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    SolidButton(title: "Book This Time") { booking = Studio.headline }
                } else {
                    Text("The signature cut is booked out for the next fortnight.")
                        .font(Tone.copy(15))
                        .foregroundColor(Tone.letter)
                        .fixedSize(horizontal: false, vertical: true)
                    OutlineButton(title: "See every service", action: openMenu)
                }
            }
        }
    }

    private func yours(_ held: Appointment) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 9) {
                Kicker(text: "You're booked", tint: Tone.accent)
                Text(held.service?.name ?? "Appointment")
                    .font(Tone.copy(17, .semibold))
                    .foregroundColor(Tone.letter)
                Text("\(Stamp.day(held.day)) at \(Studio.clock(held.minutes))"
                     + (held.stylist.map { " · \($0.name)" } ?? ""))
                    .font(Tone.figure(13))
                    .foregroundColor(Tone.letterSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// Three services that show the shape of the menu at a glance: the signature cut, the
    /// three-hour balayage at one end and the quarter-hour bang trim at the other.
    private var shortlist: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Kicker(text: "Book something")
                Spacer()
                Button(action: openMenu) {
                    Text("All services")
                        .font(Tone.figure(11, .semibold))
                        .foregroundColor(Tone.accent)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 6)

            ForEach(Array(featured.enumerated()), id: \.element.id) { index, service in
                if index > 0 { Hairline() }
                Button(action: { booking = service }) {
                    ServiceRow(service: service, opening: datebook.nextOpening(for: service))
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var featured: [Service] {
        ["cut-women", "balayage", "bang-trim"].compactMap { Studio.service($0) }
    }
}

/// Open, closing soon or shut, with a dot that changes colour rather than a word that
/// changes meaning.
struct DoorLine: View {
    let state: DoorState

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(state.isOpen ? Tone.accent : Tone.letterSoft.opacity(0.55))
                .frame(width: 7, height: 7)
            Text(state.label)
                .font(Tone.figure(11, .semibold))
                .tracking(1.1)
                .foregroundColor(Tone.letter)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// One line of the menu: what it is, what it costs, how long it takes, and the soonest it
/// can actually happen. The last part is what makes the list a book rather than a poster —
/// and with services running from fifteen minutes to three hours, the soonest times drift
/// apart by days.
struct ServiceRow: View {
    let service: Service
    let opening: (day: Date, slot: Slot)?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    Text(service.name)
                        .font(Tone.copy(15, .semibold))
                        .foregroundColor(Tone.letter)
                    if service.isSignature {
                        Kicker(text: "Signature", tint: Tone.accent)
                    }
                }
                Text(service.detail)
                    .font(Tone.copy(13))
                    .foregroundColor(Tone.letterSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Text(soonestLine)
                    .font(Tone.figure(11))
                    .foregroundColor(opening == nil ? Tone.letterSoft : Tone.accent)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                Text(Studio.money(service.priceCents))
                    .font(Tone.figure(15, .semibold))
                    .foregroundColor(Tone.letter)
                Text(Studio.duration(service.minutes))
                    .font(Tone.figure(11))
                    .foregroundColor(Tone.letterSoft)
            }
        }
        .padding(.vertical, 14)
    }

    private var soonestLine: String {
        guard let opening else { return "Booked out this fortnight" }
        let calendar = Calendar.current
        if calendar.isDateInToday(opening.day) { return "Soonest today \(opening.slot.label)" }
        if calendar.isDateInTomorrow(opening.day) { return "Soonest tomorrow \(opening.slot.label)" }
        return "Soonest \(Stamp.day(opening.day)) \(opening.slot.label)"
    }
}
