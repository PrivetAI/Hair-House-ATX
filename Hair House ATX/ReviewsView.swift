import SwiftUI

/// Reviews, split in two on purpose. The top of the screen is the studio's public standing —
/// one average and one count, and nothing else. The reviews behind those figures belong to
/// the people who wrote them and live on the studio's Google listing, so this screen links
/// out to them rather than reprinting them. Everything below the line is the guest's own:
/// their stars, their notes, kept on this phone and sent nowhere.
struct ReviewsView: View {
    @EnvironmentObject private var datebook: Datebook
    @State private var ratingVisit: Appointment?

    var body: some View {
        Screen {
            VStack(alignment: .leading, spacing: 7) {
                Kicker(text: "How it's going")
                Text("Reviews")
                    .font(Tone.display(29))
                    .foregroundColor(Tone.letter)
            }

            standing
            rateBlock
            // Nothing rated yet means there is no record to show — an empty card claiming a
            // nought-star average would be a statement the guest never made.
            if let average = datebook.ownAverage { ownRecord(average) }
            publicBlock
        }
        .sheet(item: $ratingVisit) { visit in
            RateSheet(visit: visit, existing: datebook.rating(for: visit))
                .environmentObject(datebook)
        }
    }

    /// The studio's own figures, and only those two. Anything more specific about how the
    /// public rates this place would be a number nobody counted.
    private var standing: some View {
        Card(lifted: true) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(String(format: "%.1f", Studio.ratingAverage))
                        .font(Tone.display(30))
                        .foregroundColor(Tone.accent)
                    Text("\(Studio.ratingCount) reviews")
                        .font(Tone.figure(11))
                        .foregroundColor(Tone.letterSoft)
                }
                Rectangle().fill(Tone.rule).frame(width: Span.rule, height: 46)
                VStack(alignment: .leading, spacing: 6) {
                    StarRow(value: Studio.ratingAverage)
                    Text("The studio's standing on its Google listing.")
                        .font(Tone.copy(13))
                        .foregroundColor(Tone.letterSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: Rating your own visits

    private var rateBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Kicker(text: "Rate your visit")

            if datebook.past.isEmpty {
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nothing to rate yet")
                            .font(Tone.copy(16, .semibold))
                            .foregroundColor(Tone.letter)
                        Text("Once a booked time has been and gone it turns up here to rate. "
                             + "Whatever you write stays on this phone.")
                            .font(Tone.copy(14))
                            .foregroundColor(Tone.letterSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else if datebook.unrated.isEmpty {
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Every visit rated")
                            .font(Tone.copy(16, .semibold))
                            .foregroundColor(Tone.letter)
                        Text("Nothing outstanding. Tap any visit below to change what you said.")
                            .font(Tone.copy(14))
                            .foregroundColor(Tone.letterSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(datebook.unrated.enumerated()), id: \.element.id) { index, visit in
                        if index > 0 { Hairline() }
                        Button(action: { ratingVisit = visit }) {
                            unratedRow(visit)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }

    private func unratedRow(_ visit: Appointment) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(visit.service?.name ?? "Appointment")
                    .font(Tone.copy(15, .semibold))
                    .foregroundColor(Tone.letter)
                    .fixedSize(horizontal: false, vertical: true)
                Text(line(for: visit))
                    .font(Tone.figure(11))
                    .foregroundColor(Tone.letterSoft)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 3) {
                    ForEach(1...5, id: \.self) { _ in StarMark(filled: false) }
                }
                .padding(.top, 2)
            }
            Spacer(minLength: 8)
            Text("Rate")
                .font(Tone.figure(12, .semibold))
                .foregroundColor(Tone.accent)
        }
        .padding(.vertical, 14)
    }

    // MARK: What you've said

    private func ownRecord(_ average: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Kicker(text: "Your own record")

            Card {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(String(format: "%.1f", average))
                            .font(Tone.display(26))
                            .foregroundColor(Tone.accent)
                        Text(countLine)
                            .font(Tone.figure(11))
                            .foregroundColor(Tone.letterSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Rectangle().fill(Tone.rule).frame(width: Span.rule, height: 42)
                    StarRow(value: average)
                    Spacer(minLength: 0)
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(datebook.rated.enumerated()), id: \.element.visit.id) { index, entry in
                    if index > 0 { Hairline() }
                    Button(action: { ratingVisit = entry.visit }) {
                        ratedRow(entry.visit, entry.rating)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private var countLine: String {
        let rated = datebook.rated.count
        let total = datebook.past.count
        return rated == total ? "All \(total) visits rated" : "\(rated) of \(total) visits rated"
    }

    private func ratedRow(_ visit: Appointment, _ rating: Rating) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 3) {
                    ForEach(1...5, id: \.self) { index in
                        StarMark(filled: index <= rating.stars)
                    }
                }
                Text(visit.service?.name ?? "Appointment")
                    .font(Tone.copy(15, .semibold))
                    .foregroundColor(Tone.letter)
                    .fixedSize(horizontal: false, vertical: true)
                Text(line(for: visit))
                    .font(Tone.figure(11))
                    .foregroundColor(Tone.letterSoft)
                    .fixedSize(horizontal: false, vertical: true)
                if !rating.note.isEmpty {
                    Text(rating.note)
                        .font(Tone.copy(13))
                        .foregroundColor(Tone.letter)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
            }
            Spacer(minLength: 8)
            Text("Change")
                .font(Tone.figure(11, .semibold))
                .foregroundColor(Tone.accent)
        }
        .padding(.vertical, 14)
    }

    /// The date and, where the visit had one, the chair. Which of the two it was matters here
    /// more than anywhere else in the app — Nia and Cassidy do different work, and a guest
    /// looking back at four stars wants to know whose four stars they were.
    private func line(for visit: Appointment) -> String {
        let stamp = "\(Stamp.day(visit.day)) · \(Studio.clock(visit.minutes))"
        guard let person = visit.stylist else { return stamp }
        return "\(stamp) · \(person.name), \(person.role)"
    }

    // MARK: The real reviews

    private var publicBlock: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Kicker(text: "Public reviews")
                Text("The \(Studio.ratingCount) reviews behind that \(String(format: "%.1f", Studio.ratingAverage)) "
                     + "sit on the studio's Google listing, which is where they belong. This app "
                     + "doesn't copy them across, and the stars you leave here go nowhere — they "
                     + "stay on this phone for you.")
                    .font(Tone.copy(13))
                    .foregroundColor(Tone.letterSoft)
                    .fixedSize(horizontal: false, vertical: true)
                OutlineButton(title: "Read them on Google") {
                    LinkOut.open(LinkOut.publicReviews)
                }
            }
        }
    }
}

/// One visit, one to five stars, and a note the guest writes for themselves. Deliberately
/// small: the studio never sees any of it, so there is nothing here to fill in for anybody
/// else's benefit.
struct RateSheet: View {
    let visit: Appointment
    let existing: Rating?

    @EnvironmentObject private var datebook: Datebook
    @Environment(\.presentationMode) private var presentation

    @State private var stars: Int
    @State private var note: String
    /// Focus is driven rather than left to the field: a bare tap on a TextField wrapped in a
    /// padded, clipped box does not put the caret in it, and the note then looks broken.
    @FocusState private var writingNote: Bool

    /// A note somebody writes for themselves is a line, not an essay, and the row it ends up
    /// on is one card wide.
    private let noteLimit = 140

    init(visit: Appointment, existing: Rating?) {
        self.visit = visit
        self.existing = existing
        _stars = State(initialValue: existing?.stars ?? 0)
        _note = State(initialValue: existing?.note ?? "")
    }

    var body: some View {
        ZStack {
            Tone.page.ignoresSafeArea()

            VStack(spacing: 0) {
                bar

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        visitCard
                        starPicker
                        noteField
                        SolidButton(title: existing == nil ? "Save rating" : "Update rating",
                                    isEnabled: stars > 0) {
                            datebook.rate(visit, stars: stars, note: note)
                            presentation.wrappedValue.dismiss()
                        }
                    }
                    .padding(.horizontal, Span.gutter)
                    .padding(.vertical, 18)
                    .frame(maxWidth: Span.column, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var bar: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Text("Rate your visit")
                    .font(Tone.display(19))
                    .foregroundColor(Tone.letter)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Button(action: { presentation.wrappedValue.dismiss() }) {
                    CloseMark(size: 17, color: Tone.letter)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, Span.gutter)
            .padding(.vertical, 12)
            .frame(maxWidth: Span.column)
            .frame(maxWidth: .infinity)
            Hairline()
        }
    }

    private var visitCard: some View {
        Card(lifted: true) {
            VStack(alignment: .leading, spacing: 6) {
                Text(visit.service?.name ?? "Appointment")
                    .font(Tone.copy(17, .semibold))
                    .foregroundColor(Tone.letter)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(Stamp.day(visit.day)) at \(Studio.clock(visit.minutes))")
                    .font(Tone.figure(13))
                    .foregroundColor(Tone.letterSoft)
                if let person = visit.stylist {
                    Text("with \(person.name) · \(person.role)")
                        .font(Tone.copy(13))
                        .foregroundColor(Tone.letterSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var starPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Kicker(text: "How was it")
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { index in
                    Button(action: { stars = index }) {
                        StarMark(filled: index <= stars, size: 32)
                            .frame(width: 46, height: 46)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                Spacer(minLength: 0)
            }
            Text(starWord)
                .font(Tone.figure(12))
                .foregroundColor(stars > 0 ? Tone.accent : Tone.letterSoft)
        }
    }

    private var starWord: String {
        switch stars {
        case 1: return "One star"
        case 2: return "Two stars"
        case 3: return "Three stars"
        case 4: return "Four stars"
        case 5: return "Five stars"
        default: return "Tap a star"
        }
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Kicker(text: "A note, if you want one")
            TextField("Shorter is fine", text: $note)
                .focused($writingNote)
                .submitLabel(.done)
                .font(Tone.copy(15))
                .foregroundColor(Tone.letter)
                .accentColor(Tone.accent)
                .padding(14)
                .background(Tone.cardLifted)
                .overlay(
                    RoundedRectangle(cornerRadius: Span.corner)
                        .stroke(Tone.rule, lineWidth: Span.rule)
                )
                .clipShape(RoundedRectangle(cornerRadius: Span.corner))
                // The whole padded box, not just the line of text, puts the caret in.
                .contentShape(Rectangle())
                .onTapGesture { writingNote = true }
                .onChange(of: note) { latest in
                    if latest.count > noteLimit { note = String(latest.prefix(noteLimit)) }
                }
            Text("Private. Kept on this phone, never sent to the studio and never shown to "
                 + "anybody else — the sort of thing that reminds you which shade you asked for.")
                .font(Tone.copy(12))
                .foregroundColor(Tone.letterSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
