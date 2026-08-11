import SwiftUI

/// Eleven services across three groups. The two group notes are the studio's own words and
/// belong with the prices, not on a separate about screen.
struct ServicesView: View {
    @EnvironmentObject private var datebook: Datebook
    @State private var booking: Service?

    var body: some View {
        Screen {
            VStack(alignment: .leading, spacing: 7) {
                Kicker(text: "The menu")
                Text("Services")
                    .font(Tone.display(29))
                    .foregroundColor(Tone.letter)
            }

            ForEach(Studio.catalog) { group in
                VStack(alignment: .leading, spacing: 0) {
                    Kicker(text: group.name)
                        .padding(.bottom, group.note == nil ? 6 : 5)

                    if let note = group.note {
                        Text(note)
                            .font(Tone.copy(13))
                            .foregroundColor(Tone.letterSoft)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 6)
                    }

                    ForEach(Array(group.services.enumerated()), id: \.element.id) { index, service in
                        if index > 0 { Hairline() }
                        Button(action: { booking = service }) {
                            VStack(alignment: .leading, spacing: 6) {
                                ServiceRow(service: service,
                                           opening: datebook.nextOpening(for: service))
                                if let only = soleStylist(service) {
                                    Text("\(only.name) is the only \(Studio.staffNoun) for this one.")
                                        .font(Tone.figure(11))
                                        .foregroundColor(Tone.letterSoft)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(.bottom, 12)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }

            Text("Prices and lengths are the studio's own. Anything over two hours is held "
                 + "for one guest, so those times run out first.")
                .font(Tone.copy(13))
                .foregroundColor(Tone.letterSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .sheet(item: $booking) { service in
            BookSheet(service: service).environmentObject(datebook)
        }
    }

    /// Surfaces the split down the middle of this roster: nearly all the colour work belongs
    /// to Nia and the smoothing to Cassidy, so those books are genuinely thinner than a cut's.
    private func soleStylist(_ service: Service) -> Stylist? {
        guard service.stylistIds.count == 1, let id = service.stylistIds.first else { return nil }
        return Studio.stylist(id)
    }
}
