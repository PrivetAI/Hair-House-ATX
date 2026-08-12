import Foundation
import Combine

/// One possible start time in a day, and what is standing in its way.
enum SlotState: Equatable {
    case free
    case taken
    case gone   // Earlier today. The clock has already run past it.
}

struct Slot: Identifiable, Equatable {
    let minutes: Int
    let stylistId: String
    let state: SlotState

    var id: String { "\(minutes)-\(stylistId)" }
    var isFree: Bool { state == .free }
    var label: String { Studio.clock(minutes) }
}

/// An appointment the guest is holding. Kept on the device — this build stores the book on
/// the phone and sends nothing anywhere.
struct Appointment: Identifiable, Codable, Equatable {
    let id: UUID
    var serviceId: String
    var stylistId: String
    var day: Date
    var minutes: Int

    init(id: UUID = UUID(), serviceId: String, stylistId: String, day: Date, minutes: Int) {
        self.id = id
        self.serviceId = serviceId
        self.stylistId = stylistId
        self.day = day
        self.minutes = minutes
    }

    /// Decoded field by field with a default for each. A synthesised decoder throws the
    /// moment a property is added later, and a throw here would quietly wipe every
    /// appointment somebody is holding.
    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        id = try box.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        serviceId = try box.decodeIfPresent(String.self, forKey: .serviceId) ?? ""
        stylistId = try box.decodeIfPresent(String.self, forKey: .stylistId) ?? ""
        day = try box.decodeIfPresent(Date.self, forKey: .day) ?? Date()
        minutes = try box.decodeIfPresent(Int.self, forKey: .minutes) ?? 0
    }

    var service: Service? { Studio.service(serviceId) }
    var stylist: Stylist? { Studio.stylist(stylistId) }

    /// The wall-clock moment, used to sort and to decide what is still ahead.
    var start: Date {
        Calendar.current.date(bySettingHour: minutes / 60,
                              minute: minutes % 60,
                              second: 0,
                              of: day) ?? day
    }
}

/// What the guest thought of a visit that has already happened. Kept beside the appointments
/// on the same phone and shown to nobody: the studio's public reviews live on its Google
/// listing, and nothing written here goes anywhere near them.
struct Rating: Identifiable, Codable, Equatable {
    let appointmentId: UUID
    var stars: Int
    var note: String
    var ratedOn: Date

    /// One rating per visit, so the appointment it belongs to is the identity.
    var id: UUID { appointmentId }

    init(appointmentId: UUID, stars: Int, note: String, ratedOn: Date = Date()) {
        self.appointmentId = appointmentId
        self.stars = stars
        self.note = note
        self.ratedOn = ratedOn
    }

    /// Field by field with a default for each, for the same reason the appointments are: a
    /// synthesised decoder throws the moment a property is added later, and the throw would
    /// take every rating the guest has left with it.
    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        appointmentId = try box.decodeIfPresent(UUID.self, forKey: .appointmentId) ?? UUID()
        stars = try box.decodeIfPresent(Int.self, forKey: .stars) ?? 0
        note = try box.decodeIfPresent(String.self, forKey: .note) ?? ""
        ratedOn = try box.decodeIfPresent(Date.self, forKey: .ratedOn) ?? Date()
    }
}

/// The studio's own bookings — the ones that were already in the book before the guest
/// opened the app. Generated rather than stored, but generated the same way every launch.
enum Occupancy {
    /// The lattice the studio's own appointments sit on.
    static let step = 15

    /// FNV-1a. `String.hashValue` is seeded per process, so a book built on it would
    /// reshuffle itself on every launch — the three o'clock that was gone this morning has
    /// to still be gone this afternoon.
    static func hash(_ text: String) -> UInt64 {
        var value: UInt64 = 0xcbf29ce484222325
        for byte in text.utf8 {
            value ^= UInt64(byte)
            value = value &* 0x100000001b3
        }
        return value
    }

    static func unit(_ text: String) -> Double {
        Double(hash(text) % 10_000) / 10_000
    }

    /// How hard the whole studio is being pushed in this hour. Shared by both chairs on
    /// purpose: a busy Thursday afternoon should be busy for everyone, not two unrelated
    /// coin flips that leave one stylist mysteriously idle all day.
    static func surge(dayKey: String, minute: Int) -> Double {
        unit("surge|\(dayKey)|\(minute / 60)")
    }

    /// Computed once per day and chair, then kept. Every screen asks about availability
    /// repeatedly — the services list alone wants fourteen days for eleven services — and
    /// rebuilding the day each time is wasted work. Only ever touched from the main thread,
    /// which is where SwiftUI reads it.
    private static var bookCache: [String: [Range<Int>]] = [:]

    /// The appointments already in the book for one chair on one day, as runs of minutes.
    ///
    /// Drawing each slot independently would give a shredded day — free, taken, free, taken
    /// — that no real chair ever looks like, and would make a three-hour service impossible
    /// rather than merely scarce. Walking the day and laying down whole appointments leaves
    /// realistic gaps, which is what the long services have to fit into.
    static func booked(dayKey: String, stylistId: String,
                       opens: Int, closes: Int) -> [Range<Int>] {
        let cacheKey = "\(dayKey)|\(stylistId)"
        if let kept = bookCache[cacheKey] { return kept }

        let dayPressure = unit("day|\(dayKey)")
        // Weighted short: most of what a studio takes is a cut or a gloss, and a book made
        // only of long sits leaves no gaps at all.
        let lengths = [45, 45, 45, 60, 60, 90]

        var runs: [Range<Int>] = []
        var minute = opens
        while minute < closes {
            // Tuned against a headless sweep of the whole menu: the book lands around 45%
            // full, which leaves a 45-minute cut a dozen or more starts a day and a
            // three-hour balayage a handful across the whole fortnight.
            let load = 0.05 + dayPressure * 0.09 + surge(dayKey: dayKey, minute: minute) * 0.14
            if unit("book|\(dayKey)|\(stylistId)|\(minute)") < load {
                let pick = Int(hash("run|\(dayKey)|\(stylistId)|\(minute)") % UInt64(lengths.count))
                let length = min(lengths[pick], closes - minute)
                runs.append(minute..<(minute + length))
                minute += length
            } else {
                minute += step
            }
        }

        bookCache[cacheKey] = runs
        return runs
    }
}

final class Datebook: ObservableObject {
    @Published private(set) var appointments: [Appointment] = []
    @Published private(set) var ratings: [Rating] = []

    private let storageKey = "hairhouse.appointments.v1"
    private let ratingsKey = "hairhouse.ratings.v1"

    init() {
        if let raw = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Appointment].self, from: raw) {
            appointments = decoded
        }
        if let raw = UserDefaults.standard.data(forKey: ratingsKey),
           let decoded = try? JSONDecoder().decode([Rating].self, from: raw) {
            ratings = decoded
        }
    }

    // MARK: Availability

        /// The string every occupancy hash is seeded from, so it must be stable whatever
    /// the phone's language and calendar are set to.
    static let keyFormatter = Fixed.formatter("yyyy-MM-dd", posix: true)

static func dayKey(_ day: Date) -> String {
        keyFormatter.string(from: day)
    }

    /// How finely the day is offered. A quarter-hour bang trim wants quarter-hour starts; a
    /// three-hour balayage on the same lattice would be a wall of near-identical rows.
    static func stride(for service: Service) -> Int {
        service.minutes < 60 ? 15 : 30
    }

    /// The day laid out as start times for one service.
    ///
    /// The loop stops at `closes - service.minutes`, which is what makes the long services
    /// visibly shorter columns: a 180-minute balayage cannot start after three o'clock on a
    /// six o'clock day, so its column ends where a 45-minute cut's is still going. On top of
    /// that a start only counts as free if the chair stays clear for the service's whole
    /// run, which is what makes them sparse as well as short.
    func slots(on day: Date, service: Service, stylistId: String?) -> [Slot] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: day)
        let hours = Studio.hours(for: weekday)
        guard let opens = hours.opensAt, let closes = hours.closesAt else { return [] }

        let key = Datebook.dayKey(day)
        let chairs = candidates(for: service, preferred: stylistId)
        guard !chairs.isEmpty else { return [] }

        let isToday = calendar.isDateInToday(day)
        let nowMinutes = calendar.component(.hour, from: Date()) * 60
            + calendar.component(.minute, from: Date())

        var result: [Slot] = []
        var minute = opens
        let gap = Datebook.stride(for: service)

        while minute + service.minutes <= closes {
            let run = minute..<(minute + service.minutes)
            let openChair = chairs.first { chair in
                let taken = Occupancy.booked(dayKey: key, stylistId: chair,
                                             opens: opens, closes: closes)
                if taken.contains(where: { $0.overlaps(run) }) { return false }
                return !isHeld(dayKey: key, run: run, stylistId: chair)
            }

            let state: SlotState
            if isToday && minute <= nowMinutes {
                state = .gone
            } else {
                state = openChair == nil ? .taken : .free
            }

            result.append(Slot(minutes: minute,
                               stylistId: openChair ?? chairs[0],
                               state: state))
            minute += gap
        }
        return result
    }

    /// How many starts a given day can still offer. Drives the number under each day chip,
    /// which is where the price-and-length spread becomes obvious: a bang trim shows a dozen,
    /// a balayage shows nought or one.
    func freeCount(on day: Date, service: Service, stylistId: String?) -> Int {
        slots(on: day, service: service, stylistId: stylistId).filter { $0.isFree }.count
    }

    /// Which chairs take this service at all. A service tied to one stylist has exactly one,
    /// and its book is genuinely thinner as a result.
    func candidates(for service: Service, preferred: String?) -> [String] {
        let allowed = service.stylistIds.isEmpty ? Studio.stylists.map { $0.id } : service.stylistIds
        if let preferred, allowed.contains(preferred) { return [preferred] }
        return allowed
    }

    /// The soonest free start inside the next fortnight, or nil if the service is booked out.
    func nextOpening(for service: Service, stylistId: String? = nil) -> (day: Date, slot: Slot)? {
        let calendar = Calendar.current
        let now = Date()
        for offset in 0..<14 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: now) else { continue }
            for slot in slots(on: day, service: service, stylistId: stylistId) where slot.isFree {
                return (day, slot)
            }
        }
        return nil
    }

    // MARK: The guest's own appointments

    private func isHeld(dayKey: String, run: Range<Int>, stylistId: String) -> Bool {
        appointments.contains { held in
            guard Datebook.dayKey(held.day) == dayKey, held.stylistId == stylistId else { return false }
            guard let service = held.service else { return false }
            return (held.minutes..<(held.minutes + service.minutes)).overlaps(run)
        }
    }

    func book(service: Service, stylistId: String, day: Date, minutes: Int) {
        appointments.append(Appointment(serviceId: service.id, stylistId: stylistId,
                                        day: day, minutes: minutes))
        persist()
    }

    func cancel(_ appointment: Appointment) {
        appointments.removeAll { $0.id == appointment.id }
        // A rating with no visit behind it would count towards the guest's own average for
        // ever without appearing in any list.
        ratings.removeAll { $0.appointmentId == appointment.id }
        persist()
        persistRatings()
    }

    var upcoming: [Appointment] {
        appointments.filter { $0.start >= Calendar.current.startOfDay(for: Date()) }
            .sorted { $0.start < $1.start }
    }

    var past: [Appointment] {
        appointments.filter { $0.start < Calendar.current.startOfDay(for: Date()) }
            .sorted { $0.start > $1.start }
    }

    private func persist() {
        if let raw = try? JSONEncoder().encode(appointments) {
            UserDefaults.standard.set(raw, forKey: storageKey)
        }
    }

    // MARK: What the guest made of it

    func rating(for appointment: Appointment) -> Rating? {
        ratings.first { $0.appointmentId == appointment.id }
    }

    /// One rating per visit, replaced rather than added to — going back to change your mind
    /// about a visit should not leave two opinions of it in the average.
    func rate(_ appointment: Appointment, stars: Int, note: String) {
        let kept = Rating(appointmentId: appointment.id,
                          stars: min(5, max(1, stars)),
                          note: note.trimmingCharacters(in: .whitespacesAndNewlines))
        ratings.removeAll { $0.appointmentId == appointment.id }
        ratings.append(kept)
        persistRatings()
    }

    /// Visits that have happened and have nothing said about them yet, newest first.
    var unrated: [Appointment] { past.filter { rating(for: $0) == nil } }

    /// The rated ones, paired with what was said. Built from `past` rather than from the
    /// ratings, so a rating whose appointment has gone simply never appears.
    var rated: [(visit: Appointment, rating: Rating)] {
        past.compactMap { visit in rating(for: visit).map { (visit: visit, rating: $0) } }
    }

    /// The guest's own average, or nil until they have rated something. An average of
    /// nothing is not nought stars, and the divisor would be zero.
    var ownAverage: Double? {
        let scores = rated.map { Double($0.rating.stars) }
        guard !scores.isEmpty else { return nil }
        return scores.reduce(0, +) / Double(scores.count)
    }

    // MARK: The history, totalled

    /// What the visits behind them cost, added up. Services that are no longer on the menu
    /// contribute nothing rather than crashing the sum.
    var totalSpentCents: Int {
        past.compactMap { $0.service?.priceCents }.reduce(0, +)
    }

    /// Mean days from one visit to the next, rounded. Nil below two visits: there is no gap
    /// between a single visit and nothing, and `count - 1` would be a division by zero.
    var averageGapDays: Int? {
        let calendar = Calendar.current
        let days = past.map { calendar.startOfDay(for: $0.start) }.sorted()
        guard days.count > 1, let first = days.first, let last = days.last else { return nil }
        let span = calendar.dateComponents([.day], from: first, to: last).day ?? 0
        return max(0, Int((Double(span) / Double(days.count - 1)).rounded()))
    }

    private func persistRatings() {
        if let raw = try? JSONEncoder().encode(ratings) {
            UserDefaults.standard.set(raw, forKey: ratingsKey)
        }
    }
}

/// Open, closing soon, or shut — worked out from the studio's own hours rather than typed
/// onto a screen, so the two closed days can never disagree with the table.
enum DoorState {
    case open(until: Int)
    case closingSoon(until: Int)
    case shut(reopensDay: String?, reopensAt: Int?)

    static func now(_ moment: Date = Date()) -> DoorState {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: moment)
        let minutes = calendar.component(.hour, from: moment) * 60
            + calendar.component(.minute, from: moment)
        let today = Studio.hours(for: weekday)

        if let opens = today.opensAt, let closes = today.closesAt,
           minutes >= opens, minutes < closes {
            return closes - minutes <= 60 ? .closingSoon(until: closes) : .open(until: closes)
        }

        // Walk forward to the next day the door opens. With Sunday and Monday both shut
        // that can be two days away, so the loop has to keep going rather than assume
        // tomorrow.
        for offset in 0..<8 {
            let day = (weekday - 1 + offset) % 7 + 1
            let hours = Studio.hours(for: day)
            guard let opens = hours.opensAt else { continue }
            if offset == 0 {
                if minutes < opens { return .shut(reopensDay: nil, reopensAt: opens) }
                continue
            }
            let label = offset == 1 ? "tomorrow" : Studio.weekdayNames[day]
            return .shut(reopensDay: label, reopensAt: opens)
        }
        return .shut(reopensDay: nil, reopensAt: nil)
    }

    var isOpen: Bool {
        if case .shut = self { return false }
        return true
    }

    var label: String {
        switch self {
        case .open(let until): return "OPEN UNTIL \(Studio.clock(until).uppercased())"
        case .closingSoon(let until): return "CLOSING AT \(Studio.clock(until).uppercased())"
        case .shut(let day, let at):
            guard let at else { return "CLOSED" }
            guard let day else { return "CLOSED · OPENS \(Studio.clock(at).uppercased())" }
            return "CLOSED · OPENS \(day.uppercased()) \(Studio.clock(at).uppercased())"
        }
    }
}

/// Short date stamps, in one place so every screen writes a date the same way.
/// Built once and pinned to English and Gregorian — these apps ship in English only,
/// and a day strip that changed language with the phone would not match the shop's sign.
enum Stamp {
    private static let fullFace = Fixed.formatter("EEE d MMM")
    private static let shortFace = Fixed.formatter("EEE")
    private static let figureFace = Fixed.formatter("d")
    private static let longFace = Fixed.formatter("EEEE")

    static func day(_ date: Date) -> String {
        fullFace.string(from: date)
    }

    static func weekday(_ date: Date) -> String {
        shortFace.string(from: date)
    }

    static func dayNumber(_ date: Date) -> String {
        figureFace.string(from: date)
    }

    /// "Today at 2 PM" / "Tomorrow at 9 AM" / "Thursday at 10:30 AM".
    static func opening(_ day: Date, _ minutes: Int) -> String {
        let calendar = Calendar.current
        let time = Studio.clock(minutes)
        if calendar.isDateInToday(day) { return "Today at \(time)" }
        if calendar.isDateInTomorrow(day) { return "Tomorrow at \(time)" }
        return "\(longFace.string(from: day)) at \(time)"
    }
}

/// Date formatting is pinned rather than left to the device. `DateFormatter` otherwise
/// follows the phone's locale and calendar, which would translate the day strip and — far
/// worse — change the day key the occupancy hash is seeded from, reshuffling the whole
/// fortnight for anyone whose phone is not on English and Gregorian.
enum Fixed {
    static let gregorian: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }()

    static func formatter(_ format: String, posix: Bool = false) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: posix ? "en_US_POSIX" : "en_US")
        formatter.calendar = Fixed.gregorian
        formatter.dateFormat = format
        return formatter
    }
}
