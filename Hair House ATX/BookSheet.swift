import SwiftUI

/// Booking shows the day as a column — every possible start from opening to the last one
/// that still fits, top to bottom, with the taken ones struck through. Scattering the free
/// times into a cloud of chips hides the shape of the day, and "come at ten instead" stops
/// being an obvious move.
struct BookSheet: View {
    let service: Service

    @EnvironmentObject private var datebook: Datebook
    @Environment(\.presentationMode) private var presentation

    /// The fortnight, worked out once. Rebuilding it inside `body` would hand ForEach a new
    /// identity for every chip on every redraw — the strip would jump back to the left each
    /// time a day or a stylist was picked.
    private let days: [Date]

    @State private var day: Date
    @State private var stylistId: String?
    @State private var confirmed: Slot?
    @State private var settled = false

    /// `preferredStylistId` is only ever set by "Book this again": the same service with the
    /// chair that did it last time already chosen. It is checked against the service's own
    /// roster here rather than trusted, so a chair that no longer takes the work quietly
    /// falls back to anyone free instead of filtering the day book down to nothing.
    init(service: Service, preferredStylistId: String? = nil) {
        self.service = service

        let allowed = service.stylistIds.isEmpty ? Studio.stylists.map { $0.id } : service.stylistIds
        _stylistId = State(initialValue: preferredStylistId.flatMap {
            allowed.contains($0) ? $0 : nil
        })

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let fortnight = (0..<14).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
        self.days = fortnight

        // Sunday and Monday are both shut, so opening on "today" would land on a dead day
        // two days in every seven. Start on the first day the door is actually open.
        let firstOpen = fortnight.first { candidate in
            !Studio.hours(for: calendar.component(.weekday, from: candidate)).isClosed
        }
        _day = State(initialValue: firstOpen ?? today)
    }

    var body: some View {
        ZStack {
            Tone.page.ignoresSafeArea()

            VStack(spacing: 0) {
                bar
                if confirmed == nil { picker } else { receipt }
            }
        }
        .onAppear(perform: settleOpeningDay)
    }

    /// The first day the door is open can still be a day with nothing left on it — today
    /// after four o'clock usually is. Landing there turns "Book This Time" into a column of
    /// struck-through rows, so if the opening day has nothing free, start on the day the
    /// soonest opening is genuinely on. Runs once: after that the day is the guest's to pick.
    private func settleOpeningDay() {
        guard !settled else { return }
        settled = true
        guard datebook.freeCount(on: day, service: service, stylistId: stylistId) == 0,
              let opening = datebook.nextOpening(for: service, stylistId: stylistId) else { return }
        day = Calendar.current.startOfDay(for: opening.day)
    }

    private var bar: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(service.name)
                        .font(Tone.display(19))
                        .foregroundColor(Tone.letter)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(Studio.money(service.priceCents)) · \(Studio.duration(service.minutes))")
                        .font(Tone.figure(12))
                        .foregroundColor(Tone.letterSoft)
                }
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

    // MARK: Picking

    private var picker: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                dayStrip
                chairStrip
                column
            }
            .padding(.horizontal, Span.gutter)
            .padding(.vertical, 18)
            .frame(maxWidth: Span.column, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private var chairs: [String] {
        service.stylistIds.isEmpty ? Studio.stylists.map { $0.id } : service.stylistIds
    }

    // MARK: The fortnight

    /// All fourteen days, shut ones included. Hiding Sunday and Monday would make the strip
    /// read as an unbroken run of open days and quietly mislead; greying them out shows the
    /// studio's week — five days on, two off — at a glance.
    private var dayStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Kicker(text: "Day")
                Spacer()
                Text("\(Studio.closedDayNames) the studio is shut")
                    .font(Tone.figure(10))
                    .foregroundColor(Tone.letterSoft)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(days, id: \.timeIntervalSince1970) { candidate in
                        dayChip(candidate)
                    }
                }
                .padding(.horizontal, 1)
                .padding(.vertical, 2)
            }
        }
    }

    private func dayChip(_ candidate: Date) -> some View {
        let weekday = Calendar.current.component(.weekday, from: candidate)
        let shut = Studio.hours(for: weekday).isClosed
        let chosen = Calendar.current.isDate(candidate, inSameDayAs: day)
        let free = shut ? 0 : datebook.freeCount(on: candidate, service: service,
                                                 stylistId: stylistId)

        return Button(action: { if !shut { day = candidate } }) {
            VStack(spacing: 3) {
                Text(Stamp.weekday(candidate).uppercased())
                    .font(Tone.figure(10, .semibold))
                    .tracking(0.6)
                Text(Stamp.dayNumber(candidate))
                    .font(Tone.figure(17, .bold))
                Text(shut ? "SHUT" : (free == 0 ? "FULL" : "\(free) FREE"))
                    .font(Tone.figure(9, .semibold))
                    .tracking(0.3)
            }
            .foregroundColor(chipInk(chosen: chosen, shut: shut, free: free))
            .frame(width: 62, height: 72)
            .background(chosen ? Tone.accent : (shut ? Tone.card.opacity(0.6) : Tone.cardLifted))
            .overlay(
                RoundedRectangle(cornerRadius: Span.corner)
                    .stroke(chosen ? Tone.accent : Tone.rule, lineWidth: Span.rule)
            )
            .clipShape(RoundedRectangle(cornerRadius: Span.corner))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        // Shut days are shown and cannot be picked. Both halves matter.
        .disabled(shut)
    }

    private func chipInk(chosen: Bool, shut: Bool, free: Int) -> Color {
        if chosen { return Tone.onAccent }
        if shut { return Tone.letterSoft.opacity(0.4) }
        return free == 0 ? Tone.letterSoft : Tone.letter
    }

    // MARK: Who takes it

    private var chairStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Kicker(text: Studio.staffNoun)
            if chairs.count > 1 {
                HStack(spacing: 9) {
                    chip(title: "Anyone", chosen: stylistId == nil) { stylistId = nil }
                    ForEach(chairs, id: \.self) { id in
                        if let person = Studio.stylist(id) {
                            chip(title: person.name, chosen: stylistId == id) { stylistId = id }
                        }
                    }
                    Spacer(minLength: 0)
                }
            } else if let only = chairs.first, let person = Studio.stylist(only) {
                // One qualified chair, so there is nothing to choose. Say who, rather than
                // offering a picker with a single answer in it.
                Text("\(person.name) takes every \(service.name.lowercased()) — "
                     + "the only \(Studio.staffNoun) booked for it.")
                    .font(Tone.copy(13))
                    .foregroundColor(Tone.letterSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func chip(title: String, chosen: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Tone.copy(14, .medium))
                .foregroundColor(chosen ? Tone.onAccent : Tone.letter)
                .padding(.horizontal, 15)
                .padding(.vertical, 9)
                .background(chosen ? Tone.accent : Tone.cardLifted)
                .overlay(
                    RoundedRectangle(cornerRadius: Span.corner)
                        .stroke(chosen ? Tone.accent : Tone.rule, lineWidth: Span.rule)
                )
                .clipShape(RoundedRectangle(cornerRadius: Span.corner))
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: The day

    private var slots: [Slot] { datebook.slots(on: day, service: service, stylistId: stylistId) }

    private var lastStartLine: String? {
        let weekday = Calendar.current.component(.weekday, from: day)
        let hours = Studio.hours(for: weekday)
        guard let closes = hours.closesAt else { return nil }
        let last = closes - service.minutes
        guard let opens = hours.opensAt, last >= opens else { return nil }
        return "Runs \(Studio.duration(service.minutes)) — the last start that still finishes "
            + "before \(Studio.clock(closes)) is \(Studio.clock(last))."
    }

    private var column: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Kicker(text: Stamp.day(day))
                Spacer()
                Text("\(slots.filter { $0.isFree }.count) free")
                    .font(Tone.figure(11, .semibold))
                    .foregroundColor(Tone.accent)
            }
            .padding(.bottom, 6)

            if let line = lastStartLine {
                Text(line)
                    .font(Tone.copy(12))
                    .foregroundColor(Tone.letterSoft)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 8)
            }

            if slots.isEmpty {
                Text("The studio is shut this day.")
                    .font(Tone.copy(14))
                    .foregroundColor(Tone.letterSoft)
                    .padding(.vertical, 14)
            } else {
                ForEach(slots) { slot in
                    Button(action: { take(slot) }) {
                        row(slot)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!slot.isFree)

                    Hairline()
                }
            }
        }
    }

    private func row(_ slot: Slot) -> some View {
        HStack(spacing: 12) {
            Text(slot.label)
                .font(Tone.figure(14, slot.isFree ? .semibold : .regular))
                .foregroundColor(slot.isFree ? Tone.letter : Tone.letterSoft.opacity(0.65))
                .strikethrough(!slot.isFree, color: Tone.letterSoft.opacity(0.55))
                .frame(width: 86, alignment: .leading)

            Text(note(for: slot))
                .font(Tone.figure(12))
                .foregroundColor(Tone.letterSoft.opacity(slot.isFree ? 1 : 0.65))

            Spacer(minLength: 4)

            if slot.isFree {
                Text("Book")
                    .font(Tone.figure(12, .semibold))
                    .foregroundColor(Tone.accent)
            }
        }
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    private func note(for slot: Slot) -> String {
        switch slot.state {
        case .free: return Studio.stylist(slot.stylistId)?.name ?? ""
        case .taken: return "taken"
        case .gone: return "past"
        }
    }

    private func take(_ slot: Slot) {
        guard slot.isFree else { return }
        datebook.book(service: service, stylistId: slot.stylistId,
                      day: day, minutes: slot.minutes)
        confirmed = slot
    }

    // MARK: Confirmation

    private var receipt: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Card(lifted: true) {
                    VStack(alignment: .leading, spacing: 12) {
                        Kicker(text: "Held on this phone", tint: Tone.accent)
                        Text("\(Stamp.day(day)) at \(confirmed.map { Studio.clock($0.minutes) } ?? "")")
                            .font(Tone.display(23))
                            .foregroundColor(Tone.letter)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(service.name) with "
                             + "\(confirmed.flatMap { Studio.stylist($0.stylistId) }?.name ?? "the studio")"
                             + " · \(Studio.duration(service.minutes))")
                            .font(Tone.copy(15))
                            .foregroundColor(Tone.letterSoft)
                            .fixedSize(horizontal: false, vertical: true)
                        Hairline()
                        Text("This build keeps the book on your phone. Nothing has been sent to "
                             + "the studio — call \(Studio.phone) to confirm the chair.")
                            .font(Tone.copy(13))
                            .foregroundColor(Tone.letterSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                SolidButton(title: "Done") { presentation.wrappedValue.dismiss() }
            }
            .padding(.horizontal, Span.gutter)
            .padding(.vertical, 20)
            .frame(maxWidth: Span.column, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }
}
