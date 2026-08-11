import Foundation

// The studio, written down once. Prices sit in cents so nothing rounds twice, and minutes
// drive the day book — a three-hour balayage genuinely eats more of the week than a bang
// trim, and the booking column is where that shows.

struct Stylist: Identifiable, Equatable {
    let id: String
    let name: String
    let role: String
    let note: String
}

struct Service: Identifiable, Equatable {
    let id: String
    let name: String
    let detail: String
    let priceCents: Int
    let minutes: Int
    let isSignature: Bool
    /// Empty means anyone on the floor takes it. Otherwise only these chairs do, and the
    /// day book gets visibly thinner for that service.
    let stylistIds: [String]
}

struct ServiceGroup: Identifiable, Equatable {
    let id: String
    let name: String
    let note: String?
    let services: [Service]
}

struct OpeningHours: Identifiable, Equatable {
    /// 1 = Sunday, matching Calendar's own weekday numbering.
    let weekday: Int
    let opensAt: Int?
    let closesAt: Int?

    var id: Int { weekday }
    var isClosed: Bool { opensAt == nil || closesAt == nil }

    var dayName: String { Studio.weekdayNames[weekday] }

    var rangeLabel: String {
        guard let open = opensAt, let close = closesAt else { return "Closed" }
        return "\(Studio.clock(open)) – \(Studio.clock(close))"
    }
}

enum Studio {
    static let name = "Hair House ATX"
    static let shortName = "Hair House"
    static let tagline = "Downtown on West Avenue. Colour that grows out properly."
    static let about = "A small downtown studio where every stylist takes one guest at a "
        + "time. Colour corrections, lived-in blonde, and cuts that still work eight weeks later."

    static let street = "805 West Ave #1"
    static let city = "Austin"
    static let region = "TX"
    static let postalCode = "78701"
    static let phone = "(737) 296-3420"
    static let established = "Since 2020"

    /// The door, in coordinates. Only ever used to drop one pin and to hand Apple Maps a
    /// point to walk to — the app never asks the phone where the guest is.
    static let latitude = 30.2725425
    static let longitude = -97.7494678

    /// The same number the studio prints, with the punctuation taken out so a dialler can
    /// take it. Read off `phone` rather than typed again, so the two cannot drift apart.
    static var phoneDigits: String { phone.filter { $0.isNumber } }

    /// The word the studio uses for the person doing the work. Every screen reads it from
    /// here rather than spelling it out, so the copy stays in one voice.
    static let staffNoun = "stylist"
    static let staffNounPlural = "stylists"

    static let ratingAverage = 4.9
    static let ratingCount = 488

    static var addressLine: String { "\(street), \(city), \(region) \(postalCode)" }

    static let stylists: [Stylist] = [
        Stylist(id: "nia", name: "Nia", role: "Colourist",
                note: "Blonding and colour correction. Books three weeks out."),
        Stylist(id: "cassidy", name: "Cassidy", role: "Stylist",
                note: "Curls, texture and smoothing treatments.")
    ]

    static func stylist(_ id: String) -> Stylist? { stylists.first { $0.id == id } }

    static let catalog: [ServiceGroup] = [
        ServiceGroup(id: "cut", name: "Cut & Style",
                     note: "Every cut includes a wash and a finish.", services: [
            Service(id: "cut-women", name: "Cut & Style",
                    detail: "Consultation, cut, blow-dry.",
                    priceCents: 8500, minutes: 60, isSignature: true,
                    stylistIds: ["nia", "cassidy"]),
            Service(id: "cut-men", name: "Men's Cut",
                    detail: "Scissor cut, styled.",
                    priceCents: 5500, minutes: 45, isSignature: false,
                    stylistIds: []),
            Service(id: "blowout", name: "Blowout",
                    detail: "Wash and smooth finish.",
                    priceCents: 5500, minutes: 45, isSignature: false,
                    stylistIds: []),
            Service(id: "bang-trim", name: "Bang Trim",
                    detail: "Between visits, on the house for regulars.",
                    priceCents: 2000, minutes: 15, isSignature: false,
                    stylistIds: [])
        ]),
        ServiceGroup(id: "colour", name: "Colour",
                     note: "Book a consultation first if you're changing more than two shades.",
                     services: [
            Service(id: "gloss", name: "Gloss & Toner",
                    detail: "Refreshes tone between colour appointments.",
                    priceCents: 6500, minutes: 45, isSignature: false,
                    stylistIds: ["nia"]),
            Service(id: "single-process", name: "Single Process",
                    detail: "All-over colour, roots to ends.",
                    priceCents: 11000, minutes: 90, isSignature: false,
                    stylistIds: ["nia", "cassidy"]),
            Service(id: "partial-highlights", name: "Partial Highlights",
                    detail: "Crown and face-framing.",
                    priceCents: 16500, minutes: 120, isSignature: false,
                    stylistIds: ["nia"]),
            Service(id: "full-highlights", name: "Full Highlights",
                    detail: "Full head, toned and styled.",
                    priceCents: 21500, minutes: 150, isSignature: false,
                    stylistIds: ["nia"]),
            Service(id: "balayage", name: "Balayage",
                    detail: "Hand-painted, soft grow-out.",
                    priceCents: 26000, minutes: 180, isSignature: true,
                    stylistIds: ["nia"])
        ]),
        ServiceGroup(id: "treatments", name: "Treatments", note: nil, services: [
            Service(id: "deep-conditioning", name: "Deep Conditioning",
                    detail: "Add to any service.",
                    priceCents: 4500, minutes: 30, isSignature: false,
                    stylistIds: []),
            Service(id: "keratin", name: "Keratin Smoothing",
                    detail: "Cuts drying time in half for about three months.",
                    priceCents: 30000, minutes: 180, isSignature: false,
                    stylistIds: ["cassidy"])
        ])
    ]

    static var allServices: [Service] { catalog.flatMap { $0.services } }

    static func service(_ id: String) -> Service? { allServices.first { $0.id == id } }

    /// The signature cut, and the one the front screen leads with.
    static var headline: Service { service("cut-women") ?? allServices[0] }

    /// Five days a week. Sunday and Monday are both shut — an unusual pair, and the reason
    /// the booking strip shows dead days rather than hiding them.
    static let hours: [OpeningHours] = [
        OpeningHours(weekday: 1, opensAt: nil, closesAt: nil),
        OpeningHours(weekday: 2, opensAt: nil, closesAt: nil),
        OpeningHours(weekday: 3, opensAt: 9 * 60, closesAt: 18 * 60),
        OpeningHours(weekday: 4, opensAt: 9 * 60, closesAt: 18 * 60),
        OpeningHours(weekday: 5, opensAt: 9 * 60, closesAt: 19 * 60),
        OpeningHours(weekday: 6, opensAt: 9 * 60, closesAt: 19 * 60),
        OpeningHours(weekday: 7, opensAt: 10 * 60, closesAt: 17 * 60)
    ]

    static func hours(for weekday: Int) -> OpeningHours {
        hours.first { $0.weekday == weekday } ?? hours[0]
    }

    /// The week starting Monday, so the table reads the way a door card does — and so the
    /// two shut days sit together at the ends rather than being lost mid-list.
    static var weekOrdered: [OpeningHours] {
        [2, 3, 4, 5, 6, 7, 1].compactMap { day in hours.first { $0.weekday == day } }
    }

    static let weekdayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday",
                               "Thursday", "Friday", "Saturday"]

    /// The shut days, named — read off the hours rather than typed onto a screen, so the
    /// booking strip's caption can never drift out of step with the table.
    static var closedDayNames: String {
        let names = hours.filter { $0.isClosed }.map { $0.dayName }
        guard let last = names.last else { return "" }
        if names.count == 1 { return last }
        return names.dropLast().joined(separator: ", ") + " and " + last
    }

    static func clock(_ minutes: Int) -> String {
        let hour = minutes / 60, minute = minutes % 60
        let hour12 = hour % 12 == 0 ? 12 : hour % 12
        let suffix = hour < 12 ? "AM" : "PM"
        return minute == 0 ? "\(hour12) \(suffix)"
                           : String(format: "%d:%02d %@", hour12, minute, suffix)
    }

    static func money(_ cents: Int) -> String {
        cents % 100 == 0 ? "$\(cents / 100)" : String(format: "$%.2f", Double(cents) / 100)
    }

    /// A run of visits at these prices passes a thousand dollars quickly, and "$1240" is not
    /// a figure anybody reads at a glance. Single prices stay with `money` — none of them is
    /// long enough to need grouping — and only the totals come through here.
    static func moneyTotal(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = cents % 100 == 0 ? 0 : 2
        formatter.maximumFractionDigits = cents % 100 == 0 ? 0 : 2
        let amount = NSNumber(value: Double(cents) / 100)
        return "$" + (formatter.string(from: amount) ?? "\(cents / 100)")
    }

    static func duration(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) min" }
        let hours = minutes / 60, rest = minutes % 60
        return rest == 0 ? "\(hours) hr" : "\(hours) hr \(rest) min"
    }
}
