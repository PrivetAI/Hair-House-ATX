import SwiftUI

/// What the guest is holding, as ticket stubs. The time reads largest because it is the one
/// part anybody checks twice.
struct VisitsView: View {
    @EnvironmentObject private var datebook: Datebook
    @State private var pendingCancel: Appointment?

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
