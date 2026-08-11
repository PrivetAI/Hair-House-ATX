import UIKit

/// The three ways out of the app: the map, the phone and the studio's public listing. All
/// three go through one door so the guard is written once — `canOpenURL` first, because a
/// phone with no dialler (an iPad, or the simulator) should give a button that does nothing
/// rather than a call that fails somewhere out of sight.
enum LinkOut {
    /// Apple Maps, given both the address to label the pin and the coordinates to put it in
    /// the right place. The address alone would send anybody with a common street name to
    /// the wrong West Avenue.
    static var directions: String {
        let query = Studio.addressLine
            .addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        return "https://maps.apple.com/?q=\(query)&ll=\(Studio.latitude),\(Studio.longitude)"
    }

    static var call: String { "tel://\(Studio.phoneDigits)" }

    /// Where the studio's real reviews are. This app shows the studio's standing — the
    /// average and the count — and then hands the reviews themselves back to Google rather
    /// than reprinting anybody's words.
    static let publicReviews =
        "https://www.google.com/maps/search/?api=1&query=Hair%20House%20ATX%20805%20West%20Ave%20Austin%20TX"

    static func open(_ address: String) {
        guard let url = URL(string: address),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}
