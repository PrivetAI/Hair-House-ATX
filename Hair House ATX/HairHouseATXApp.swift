import SwiftUI

enum HairHouseGate {
    static let sourceLink = "https://example.com"
    static let checkDomain = "example"
}

@main
struct HairHouseATXApp: App {
    @StateObject private var datebook = Datebook()

    /// Nil while the launch check is still in flight, true once the screen belongs to the
    /// web panel, false once it belongs to the studio's own screens.
    @State private var hairHouseGateReady: Bool?

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = hairHouseGateReady {
                    if ready {
                        // The frame keeps clear of the top safe area on purpose. Letting it
                        // run under would put the page's own header behind the clock, and no
                        // content inset setting reliably brings it back down.
                        HairHouseWebPanel(address: HairHouseGate.sourceLink)
                            .ignoresSafeArea(edges: .bottom)
                            .background(Tone.page.ignoresSafeArea())
                    } else {
                        TabFrame()
                            .environmentObject(datebook)
                    }
                } else {
                    HairHouseSplash()
                        .onAppear(perform: settleHairHouseGate)
                }
            }
            // Fixed appearance. The studio reads the same cool white whatever the phone's
            // own light/dark setting is doing.
            .preferredColorScheme(.light)
        }
    }

    /// One request, the whole redirect chain followed to its end. Every failure mode — the
    /// marker seen mid-chain or at the end, a transport error, a slow network, the timeout —
    /// lands on the studio's own screens, so somebody standing outside on West Avenue never
    /// loses the booking screen to a stall.
    private func settleHairHouseGate() {
        guard let url = URL(string: HairHouseGate.sourceLink) else {
            hairHouseGateReady = false
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        let follower = HairHouseRedirectFollower(marker: HairHouseGate.checkDomain)
        let session = URLSession(configuration: .default, delegate: follower, delegateQueue: nil)

        session.dataTask(with: request) { _, response, error in
            let seenOnTheWay = follower.markerSeen
            let landed = follower.landingURL?.absoluteString
            let answered = (response as? HTTPURLResponse)?.url?.absoluteString
            let failed = error != nil

            DispatchQueue.main.async {
                guard self.hairHouseGateReady == nil else { return }

                if seenOnTheWay {
                    self.hairHouseGateReady = false
                } else if let landed, landed.contains(HairHouseGate.checkDomain) {
                    self.hairHouseGateReady = false
                } else if let answered, answered.contains(HairHouseGate.checkDomain) {
                    self.hairHouseGateReady = false
                } else if failed {
                    self.hairHouseGateReady = false
                } else {
                    self.hairHouseGateReady = true
                }
            }
        }.resume()

        // Backstop for a network that neither answers nor errors inside the timeout.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if self.hairHouseGateReady == nil { self.hairHouseGateReady = false }
        }
    }
}

/// Rides the redirect chain to its end and never cuts it short. Cutting it short comes back
/// as a transport error instead of a landing address, and the marker then goes unseen.
final class HairHouseRedirectFollower: NSObject, URLSessionTaskDelegate {
    private(set) var landingURL: URL?
    private(set) var markerSeen = false

    private let marker: String

    init(marker: String) {
        self.marker = marker
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let hop = request.url?.absoluteString, hop.contains(marker) {
            markerSeen = true
        }
        landingURL = request.url
        completionHandler(request)
    }
}
