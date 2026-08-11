import SwiftUI

/// A past visit being taken up again: the service, and the chair that did it last time where
/// that chair still takes the work.
private struct Rebooking: Identifiable {
    let service: Service
    let stylistId: String?

    var id: String { "\(service.id)|\(stylistId ?? "anyone")" }
}

/// What the guest is holding, as ticket stubs. The time reads largest because it is the one
/// part anybody checks twice.
struct VisitsView: View {
    @EnvironmentObject private var datebook: Datebook
    @State private var pendingCancel: Appointment?
    @State private var rebooking: Rebooking?

    var body: some View {
        Screen {
            VStack(alignment: .leading, spacing: 7) {
                Kicker(text: "Your chair")
                Text("Visits")
                    .font(Tone.display(29))
                    .foregroundColor(Tone.letter)
            }

            if datebook.appointments.isEmpty {
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nothing booked yet")
                            .font(Tone.copy(16, .semibold))
                            .foregroundColor(Tone.letter)
                        Text("Pick something off the menu and the appointment turns up here.")
                            .font(Tone.copy(14))
                            .foregroundColor(Tone.letterSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if !datebook.upcoming.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Kicker(text: "Coming up")
                    ForEach(datebook.upcoming) { held in
                        stub(held, isPast: false)
                    }
                }
            }

            if !datebook.past.isEmpty {
                history
                VStack(alignment: .leading, spacing: 12) {
                    Kicker(text: "Been and gone")
                    ForEach(datebook.past) { held in
                        stub(held, isPast: true)
                    }
                }
            }
        }
        .alert(item: $pendingCancel) { held in
            Alert(title: Text("Cancel this appointment?"),
                  message: Text("\(held.service?.name ?? "Appointment") · "
                                + "\(Stamp.day(held.day)) at \(Studio.clock(held.minutes))"),
                  primaryButton: .destructive(Text("Give it up")) { datebook.cancel(held) },
                  secondaryButton: .cancel())
        }
        .sheet(item: $rebooking) { again in
            BookSheet(service: again.service, preferredStylistId: again.stylistId)
                .environmentObject(datebook)
        }
    }

    // MARK: What it adds up to

    /// Three figures off the visits that have happened. The gap only appears from the second
    /// visit on — there is nothing between one visit and nothing, and the division that
    /// works it out has no divisor until then.
    private var history: some View {
        Card(lifted: true) {
            VStack(alignment: .leading, spacing: 12) {
                Kicker(text: "Since you started coming")
                HStack(spacing: 12) {
                    figure(value: "\(datebook.past.count)",
                           caption: datebook.past.count == 1 ? "VISIT" : "VISITS")
                    tally
                    figure(value: Studio.moneyTotal(datebook.totalSpentCents), caption: "SPENT")
                    if let gap = datebook.averageGapDays {
                        tally
                        figure(value: "\(gap)", caption: "DAYS APART")
                    }
                    Spacer(minLength: 0)
                }
                if datebook.averageGapDays == nil {
                    Text("Come back once more and this starts showing how often you're in.")
                        .font(Tone.copy(12))
                        .foregroundColor(Tone.letterSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var tally: some View {
        Rectangle().fill(Tone.rule).frame(width: Span.rule, height: 34)
    }

    private func figure(value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(Tone.figure(19, .bold))
                .foregroundColor(Tone.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(caption)
                .font(Tone.figure(9, .semibold))
                .tracking(0.5)
                .foregroundColor(Tone.letterSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    /// Whether the chair that did it last time can do it again. A service's roster can be
    /// narrower than it was — prefilling a stylist who no longer takes the work would hand
    /// the booking sheet an empty day book.
    private func stillTakes(_ stylistId: String, _ service: Service) -> Bool {
        guard Studio.stylist(stylistId) != nil else { return false }
        return service.stylistIds.isEmpty || service.stylistIds.contains(stylistId)
    }

    private func repeatOf(_ held: Appointment, _ service: Service) -> Rebooking {
        Rebooking(service: service,
                  stylistId: stillTakes(held.stylistId, service) ? held.stylistId : nil)
    }

    private func repeatNote(_ held: Appointment, _ service: Service) -> String {
        guard stillTakes(held.stylistId, service), let person = held.stylist else { return "" }
        return "· \(person.name) again"
    }

    private func stub(_ held: Appointment, isPast: Bool) -> some View {
        HStack(spacing: 0) {
            // The tear-off edge. A flat band of evergreen is all it takes to stop the stub
            // reading as one more card.
            Rectangle()
                .fill(isPast ? Tone.rule : Tone.accent)
                .frame(width: 5)

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Studio.clock(held.minutes))
                            .font(Tone.figure(20, .bold))
                            .foregroundColor(isPast ? Tone.letterSoft : Tone.letter)
                        Text(Stamp.day(held.day))
                            .font(Tone.figure(12))
                            .foregroundColor(Tone.letterSoft)
                    }
                    Spacer(minLength: 8)
                    if !isPast {
                        Button(action: { pendingCancel = held }) {
                            CloseMark(size: 15)
                                .frame(width: 32, height: 32)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                Hairline()

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(held.service?.name ?? "Appointment")
                            .font(Tone.copy(15, .semibold))
                            .foregroundColor(isPast ? Tone.letterSoft : Tone.letter)
                            .fixedSize(horizontal: false, vertical: true)
                        if let person = held.stylist {
                            Text("with \(person.name) · \(person.role)")
                                .font(Tone.copy(13))
                                .foregroundColor(Tone.letterSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if let service = held.service {
                            Text(Studio.duration(service.minutes))
                                .font(Tone.figure(11))
                                .foregroundColor(Tone.letterSoft)
                        }
                    }
                    Spacer(minLength: 8)
                    if let service = held.service {
                        Text(Studio.money(service.priceCents))
                            .font(Tone.figure(14, .semibold))
                            .foregroundColor(isPast ? Tone.letterSoft : Tone.accent)
                    }
                }

                // The usual thing anybody does with a visit that has been: have it again.
                // Same service, and the same chair where that chair still takes it.
                if isPast, let service = held.service {
                    Hairline()
                    Button(action: { rebooking = repeatOf(held, service) }) {
                        HStack(spacing: 6) {
                            Text("Book this again")
                                .font(Tone.figure(12, .semibold))
                                .foregroundColor(Tone.accent)
                            Text(repeatNote(held, service))
                                .font(Tone.figure(11))
                                .foregroundColor(Tone.letterSoft)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 9)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(16)
        }
        .background(isPast ? Tone.card : Tone.cardLifted)
        .overlay(
            RoundedRectangle(cornerRadius: Span.corner)
                .stroke(Tone.rule, lineWidth: Span.rule)
        )
        .clipShape(RoundedRectangle(cornerRadius: Span.corner))
    }
}
