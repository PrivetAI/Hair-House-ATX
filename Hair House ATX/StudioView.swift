import SwiftUI
import MapKit

/// The one pin on the studio's map. MapKit wants an Identifiable item even where there is
/// only ever going to be one of them.
struct StudioPin: Identifiable {
    let id = "studio"
    let coordinate: CLLocationCoordinate2D

    static let here = StudioPin(coordinate: CLLocationCoordinate2D(latitude: Studio.latitude,
                                                                  longitude: Studio.longitude))
}

/// The studio itself: the week, the address, the rating and the two chairs.
struct StudioView: View {
    @State private var now = Date()
    @State private var readingPolicy = false

    /// Tight enough that the block of West Avenue is readable, wide enough that the cross
    /// streets are still named.
    @State private var region = MKCoordinateRegion(
        center: StudioPin.here.coordinate,
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))

    private let tick = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        Screen {
            VStack(alignment: .leading, spacing: 8) {
                Kicker(text: "\(Studio.city), \(Studio.region)")
                Text(Studio.name)
                    .font(Tone.display(28))
                    .foregroundColor(Tone.letter)
                    .fixedSize(horizontal: false, vertical: true)
                DoorLine(state: DoorState.now(now))
            }

            Text(Studio.tagline)
                .font(Tone.copy(15))
                .foregroundColor(Tone.letterSoft)
                .fixedSize(horizontal: false, vertical: true)

            rating
            about
            hoursTable
            contact
            roster
            policy
        }
        .onReceive(tick) { now = $0 }
        .sheet(isPresented: $readingPolicy) {
            PolicyScreen()
        }
    }

    private var rating: some View {
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
                    Text("\(Studio.established), on West Avenue.")
                        .font(Tone.copy(13))
                        .foregroundColor(Tone.letterSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var about: some View {
        Text(Studio.about)
            .font(Tone.copy(14))
            .foregroundColor(Tone.letter)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// All seven rows. Sunday and Monday are the pair anybody scans for, so the table shows
    /// both shut days rather than collapsing the week into a "Tue–Sat" line that hides which
    /// two days are gone.
    private var hoursTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            Kicker(text: "Hours")
                .padding(.bottom, 10)
            ForEach(Array(Studio.weekOrdered.enumerated()), id: \.element.weekday) { index, entry in
                if index > 0 { Hairline() }
                HStack {
                    Text(entry.dayName)
                        .font(Tone.copy(15, isToday(entry) ? .semibold : .regular))
                        .foregroundColor(entry.isClosed ? Tone.letterSoft : Tone.letter)
                    Spacer(minLength: 8)
                    Text(entry.rangeLabel)
                        .font(Tone.figure(13))
                        .foregroundColor(entry.isClosed ? Tone.letterSoft.opacity(0.75) : Tone.letterSoft)
                }
                .padding(.vertical, 11)
                .padding(.horizontal, isToday(entry) ? 10 : 0)
                .background(isToday(entry) ? Tone.card : Color.clear)
            }
        }
    }

    private func isToday(_ entry: OpeningHours) -> Bool {
        Calendar.current.component(.weekday, from: now) == entry.weekday
    }

    private var contact: some View {
        VStack(alignment: .leading, spacing: 12) {
            Kicker(text: "Find the studio")
            Text(Studio.addressLine)
                .font(Tone.copy(15))
                .foregroundColor(Tone.letter)
                .fixedSize(horizontal: false, vertical: true)
            Text(Studio.phone)
                .font(Tone.figure(15))
                .foregroundColor(Tone.accent)

            map

            // Both hand off to an app that does the job properly. Trying to draw a route or
            // dial inside a booking app would be a worse version of two things the phone
            // already has.
            HStack(spacing: 10) {
                OutlineButton(title: "Directions") { LinkOut.open(LinkOut.directions) }
                OutlineButton(title: "Call") { LinkOut.open(LinkOut.call) }
            }
        }
    }

    /// A still picture of one address rather than a map to explore: no panning, no zoom, no
    /// taps at all. The studio does not move, and nothing here asks the phone where the guest
    /// is — there is no user location on it, so the app needs no location permission.
    private var map: some View {
        Map(coordinateRegion: $region,
            interactionModes: [],
            annotationItems: [StudioPin.here]) { pin in
                MapAnnotation(coordinate: pin.coordinate) { PinMark() }
            }
            .frame(height: 170)
            .overlay(
                RoundedRectangle(cornerRadius: Span.corner)
                    .stroke(Tone.rule, lineWidth: Span.rule)
            )
            .clipShape(RoundedRectangle(cornerRadius: Span.corner))
            .allowsHitTesting(false)
            .accessibilityElement()
            .accessibilityLabel("Map showing \(Studio.name) at \(Studio.addressLine)")
    }

    private var roster: some View {
        VStack(alignment: .leading, spacing: 0) {
            Kicker(text: "The \(Studio.staffNounPlural)")
                .padding(.bottom, 12)
            ForEach(Array(Studio.stylists.enumerated()), id: \.element.id) { index, person in
                if index > 0 { Hairline() }
                HStack(alignment: .top, spacing: 14) {
                    Text(String(person.name.prefix(1)))
                        .font(Tone.figure(13, .bold))
                        .foregroundColor(Tone.accent)
                        .frame(width: 36, height: 36)
                        .overlay(Circle().stroke(Tone.rule, lineWidth: Span.rule))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(person.name)
                            .font(Tone.copy(15, .semibold))
                            .foregroundColor(Tone.letter)
                        Text(person.role)
                            .font(Tone.figure(11))
                            .foregroundColor(Tone.accent)
                        Text(person.note)
                            .font(Tone.copy(13))
                            .foregroundColor(Tone.letterSoft)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 14)
            }
        }
    }

    private var policy: some View {
        VStack(alignment: .leading, spacing: 10) {
            Kicker(text: "Legal")
            OutlineButton(title: "Privacy Policy") { readingPolicy = true }
        }
    }
}
