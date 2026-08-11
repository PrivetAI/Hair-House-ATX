import SwiftUI

/// Every colour is written out rather than taken from the system, so the studio looks the
/// same whatever the phone's appearance setting is doing. Cool near-white paper, deep
/// evergreen ink — clean rather than warm, and deliberately not the cream-and-terracotta
/// every salon page wears.
enum Tone {
    static let page = Color(red: 0.969, green: 0.973, blue: 0.969)        // #F7F8F7
    static let card = Color(red: 0.929, green: 0.941, blue: 0.933)        // #EDF0EE
    static let cardLifted = Color(red: 1.0, green: 1.0, blue: 1.0)        // #FFFFFF
    static let letter = Color(red: 0.110, green: 0.149, blue: 0.133)      // #1C2622
    static let letterSoft = Color(red: 0.420, green: 0.467, blue: 0.447)  // #6B7772
    static let accent = Color(red: 0.078, green: 0.314, blue: 0.235)      // #14503C
    static let onAccent = Color(red: 0.969, green: 0.973, blue: 0.969)    // #F7F8F7
    static let rule = Color(red: 0.863, green: 0.886, blue: 0.871)        // #DCE2DE

    /// Rounded, all the way through. A salon that runs on one-guest-at-a-time wants a face
    /// that reads soft without going pastel, and rounded does that where a serif would turn
    /// the place into a boutique and a grotesque would turn it into a clinic.
    static func display(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func copy(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Prices and clock times. This menu runs from $20 to $300 and from 15 minutes to three
    /// hours — the widest spread anywhere in the set — so the figures only line up as a
    /// column if they are monospaced.
    static func figure(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

enum Span {
    static let gutter: CGFloat = 20
    static let corner: CGFloat = 12
    static let rule: CGFloat = 1
    /// Long lines of text stop being readable past roughly this width. The device family is
    /// iPhone, but the app still runs full-screen on an iPad and in landscape, so every
    /// screen caps its column instead of stretching to the glass.
    static let column: CGFloat = 560
}

// MARK: - Drawn marks
//
// Nothing here comes from the system icon set — every mark below is a Canvas, so nothing
// shifts when iOS redraws its own glyphs.

/// The studio door: a plain arch on a floor line. Stands for "the place" without being a
/// house, which is what a home tab usually settles for.
struct DoorMark: View {
    var size: CGFloat = 24
    var color: Color = Tone.accent

    var body: some View {
        Canvas { context, canvas in
            let unit = min(canvas.width, canvas.height)
            let line = max(1.4, unit * 0.08)

            var arch = Path()
            arch.move(to: CGPoint(x: unit * 0.26, y: unit * 0.82))
            arch.addLine(to: CGPoint(x: unit * 0.26, y: unit * 0.46))
            arch.addArc(center: CGPoint(x: unit * 0.5, y: unit * 0.46),
                        radius: unit * 0.24,
                        startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            arch.addLine(to: CGPoint(x: unit * 0.74, y: unit * 0.82))
            context.stroke(arch, with: .color(color),
                           style: StrokeStyle(lineWidth: line, lineJoin: .round))

            var floor = Path()
            floor.move(to: CGPoint(x: unit * 0.16, y: unit * 0.84))
            floor.addLine(to: CGPoint(x: unit * 0.84, y: unit * 0.84))
            context.stroke(floor, with: .color(color),
                           style: StrokeStyle(lineWidth: line, lineCap: .round))

            // The handle. One dot is the whole difference between an arch and a door.
            context.fill(Path(ellipseIn: CGRect(x: unit * 0.6, y: unit * 0.58,
                                                width: unit * 0.08, height: unit * 0.08)),
                         with: .color(color))
        }
        .frame(width: size, height: size)
    }
}

/// Three strands, each falling a little differently. The menu mark.
struct StrandMark: View {
    var size: CGFloat = 24
    var color: Color = Tone.accent

    var body: some View {
        Canvas { context, canvas in
            let unit = min(canvas.width, canvas.height)
            let line = max(1.4, unit * 0.075)

            for strand in 0..<3 {
                let x = unit * (0.28 + Double(strand) * 0.22)
                let sway = unit * (strand == 1 ? 0.13 : 0.09)
                var path = Path()
                path.move(to: CGPoint(x: x, y: unit * 0.16))
                path.addCurve(to: CGPoint(x: x, y: unit * 0.84),
                              control1: CGPoint(x: x + sway, y: unit * 0.4),
                              control2: CGPoint(x: x - sway, y: unit * 0.6))
                context.stroke(path, with: .color(color),
                               style: StrokeStyle(lineWidth: line, lineCap: .round))
            }
        }
        .frame(width: size, height: size)
    }
}

/// A ticket with a notch bitten out of each side — what a held appointment looks like.
struct TicketMark: View {
    var size: CGFloat = 24
    var color: Color = Tone.accent

    var body: some View {
        Canvas { context, canvas in
            let unit = min(canvas.width, canvas.height)
            let line = max(1.4, unit * 0.075)

            let frame = Path(roundedRect: CGRect(x: unit * 0.16, y: unit * 0.28,
                                                 width: unit * 0.68, height: unit * 0.44),
                             cornerRadius: unit * 0.08)
            context.stroke(frame, with: .color(color), lineWidth: line)

            // The two notches, painted in the page colour so they read as bites.
            for side in [unit * 0.16, unit * 0.84] {
                context.fill(Path(ellipseIn: CGRect(x: side - unit * 0.06,
                                                    y: unit * 0.44,
                                                    width: unit * 0.12, height: unit * 0.12)),
                             with: .color(Tone.page))
                var arc = Path()
                arc.addArc(center: CGPoint(x: side, y: unit * 0.5), radius: unit * 0.06,
                           startAngle: .degrees(side < unit * 0.5 ? -90 : 90),
                           endAngle: .degrees(side < unit * 0.5 ? 90 : 270),
                           clockwise: false)
                context.stroke(arc, with: .color(color), lineWidth: line * 0.85)
            }

            var stub = Path()
            stub.move(to: CGPoint(x: unit * 0.5, y: unit * 0.34))
            stub.addLine(to: CGPoint(x: unit * 0.5, y: unit * 0.42))
            stub.move(to: CGPoint(x: unit * 0.5, y: unit * 0.58))
            stub.addLine(to: CGPoint(x: unit * 0.5, y: unit * 0.66))
            context.stroke(stub, with: .color(color),
                           style: StrokeStyle(lineWidth: line * 0.7, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

/// A salon mirror on its stand. The studio tab.
struct MirrorMark: View {
    var size: CGFloat = 24
    var color: Color = Tone.accent

    var body: some View {
        Canvas { context, canvas in
            let unit = min(canvas.width, canvas.height)
            let line = max(1.4, unit * 0.08)

            let glass = Path(ellipseIn: CGRect(x: unit * 0.24, y: unit * 0.12,
                                               width: unit * 0.52, height: unit * 0.58))
            context.stroke(glass, with: .color(color), lineWidth: line)

            // A single highlight streak — enough to read as glass rather than a hoop.
            var glint = Path()
            glint.move(to: CGPoint(x: unit * 0.38, y: unit * 0.44))
            glint.addLine(to: CGPoint(x: unit * 0.48, y: unit * 0.24))
            context.stroke(glint, with: .color(color.opacity(0.55)),
                           style: StrokeStyle(lineWidth: line * 0.8, lineCap: .round))

            var stem = Path()
            stem.move(to: CGPoint(x: unit * 0.5, y: unit * 0.7))
            stem.addLine(to: CGPoint(x: unit * 0.5, y: unit * 0.84))
            context.stroke(stem, with: .color(color), lineWidth: line)

            var foot = Path()
            foot.move(to: CGPoint(x: unit * 0.34, y: unit * 0.86))
            foot.addLine(to: CGPoint(x: unit * 0.66, y: unit * 0.86))
            context.stroke(foot, with: .color(color),
                           style: StrokeStyle(lineWidth: line, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

/// A rosette: a star sitting in a ring with two ribbon tails. The reviews tab. A bare star
/// would collide with the little ones used in the rating rows — the ring and the tails make
/// it an object at 22pt rather than a very large version of the same thing.
struct RosetteMark: View {
    var size: CGFloat = 24
    var color: Color = Tone.accent

    var body: some View {
        Canvas { context, canvas in
            let unit = min(canvas.width, canvas.height)
            let line = max(1.4, unit * 0.075)
            let centre = CGPoint(x: unit * 0.5, y: unit * 0.42)

            context.stroke(Path(ellipseIn: CGRect(x: centre.x - unit * 0.32,
                                                  y: centre.y - unit * 0.32,
                                                  width: unit * 0.64, height: unit * 0.64)),
                           with: .color(color), lineWidth: line)

            var star = Path()
            for step in 0..<10 {
                let radius = unit * (step % 2 == 0 ? 0.19 : 0.08)
                let angle = -Double.pi / 2 + Double(step) * Double.pi / 5
                let point = CGPoint(x: centre.x + CGFloat(cos(angle)) * radius,
                                    y: centre.y + CGFloat(sin(angle)) * radius)
                if step == 0 { star.move(to: point) } else { star.addLine(to: point) }
            }
            star.closeSubpath()
            context.fill(star, with: .color(color))

            // The two tails. Without them the mark is a coin; with them it is an award.
            var tails = Path()
            tails.move(to: CGPoint(x: unit * 0.38, y: unit * 0.7))
            tails.addLine(to: CGPoint(x: unit * 0.33, y: unit * 0.88))
            tails.move(to: CGPoint(x: unit * 0.62, y: unit * 0.7))
            tails.addLine(to: CGPoint(x: unit * 0.67, y: unit * 0.88))
            context.stroke(tails, with: .color(color),
                           style: StrokeStyle(lineWidth: line * 0.85, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

/// The pin dropped on the studio's own map. The mark off the splash screen — an evergreen
/// ring around a solid centre — rather than a balloon lifted from MapKit, so the one thing
/// drawn on the map still belongs to this app.
struct PinMark: View {
    var size: CGFloat = 26

    var body: some View {
        Canvas { context, canvas in
            let unit = min(canvas.width, canvas.height)
            // A white disc under the ring: the map underneath is busy, and the mark has to
            // hold its shape over a road as well as over a block of park.
            context.fill(Path(ellipseIn: CGRect(x: 0, y: 0, width: unit, height: unit)),
                         with: .color(Tone.cardLifted))
            context.stroke(Path(ellipseIn: CGRect(x: unit * 0.09, y: unit * 0.09,
                                                  width: unit * 0.82, height: unit * 0.82)),
                           with: .color(Tone.accent), lineWidth: max(1.6, unit * 0.09))
            context.fill(Path(ellipseIn: CGRect(x: unit * 0.33, y: unit * 0.33,
                                                width: unit * 0.34, height: unit * 0.34)),
                         with: .color(Tone.accent))
        }
        .frame(width: size, height: size)
    }
}

/// A small cross, drawn rather than lifted from the system set.
struct CloseMark: View {
    var size: CGFloat = 16
    var color: Color = Tone.letterSoft

    var body: some View {
        Canvas { context, canvas in
            let unit = min(canvas.width, canvas.height)
            let inset = unit * 0.25
            var path = Path()
            path.move(to: CGPoint(x: inset, y: inset))
            path.addLine(to: CGPoint(x: unit - inset, y: unit - inset))
            path.move(to: CGPoint(x: unit - inset, y: inset))
            path.addLine(to: CGPoint(x: inset, y: unit - inset))
            context.stroke(path, with: .color(color),
                           style: StrokeStyle(lineWidth: max(1.3, unit * 0.11), lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

struct StarMark: View {
    let filled: Bool
    var size: CGFloat = 13

    var body: some View {
        Canvas { context, canvas in
            let unit = min(canvas.width, canvas.height)
            let centre = CGPoint(x: unit / 2, y: unit / 2)
            let outer = unit * 0.48
            let inner = outer * 0.42

            var path = Path()
            for step in 0..<10 {
                let radius = step % 2 == 0 ? outer : inner
                let angle = -Double.pi / 2 + Double(step) * Double.pi / 5
                let point = CGPoint(x: centre.x + CGFloat(cos(angle)) * radius,
                                    y: centre.y + CGFloat(sin(angle)) * radius)
                if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()

            if filled {
                context.fill(path, with: .color(Tone.accent))
            } else {
                context.stroke(path, with: .color(Tone.accent.opacity(0.45)), lineWidth: 1)
            }
        }
        .frame(width: size, height: size)
    }
}

struct StarRow: View {
    let value: Double

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { index in
                StarMark(filled: value >= Double(index) - 0.25)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(String(format: "%.1f", value)) out of 5")
    }
}

/// Long soft strands drifting across the page, dialled almost all the way down. Stands in
/// for photography the studio has not sent, without pretending to be a photograph.
struct StrandField: View {
    var spacing: CGFloat = 26
    var opacity: Double = 0.07

    var body: some View {
        Canvas { context, size in
            let tint = Tone.accent.opacity(opacity)
            var y: CGFloat = -spacing
            var index = 0
            while y < size.height + spacing {
                let sway = size.width * (index % 2 == 0 ? 0.06 : 0.1)
                var path = Path()
                path.move(to: CGPoint(x: -10, y: y))
                path.addCurve(to: CGPoint(x: size.width + 10, y: y + spacing * 0.35),
                              control1: CGPoint(x: size.width * 0.33, y: y + sway),
                              control2: CGPoint(x: size.width * 0.66, y: y - sway))
                context.stroke(path, with: .color(tint), lineWidth: 1)
                y += spacing
                index += 1
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Shared chrome

struct Kicker: View {
    let text: String
    var tint: Color = Tone.letterSoft

    var body: some View {
        Text(text.uppercased())
            .font(Tone.figure(11, .semibold))
            .tracking(1.4)
            .foregroundColor(tint)
    }
}

struct Hairline: View {
    var body: some View {
        Rectangle().fill(Tone.rule).frame(height: Span.rule)
    }
}

struct Card<Content: View>: View {
    var lifted = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(lifted ? Tone.cardLifted : Tone.card)
            .overlay(
                RoundedRectangle(cornerRadius: Span.corner)
                    .stroke(Tone.rule, lineWidth: Span.rule)
            )
            .clipShape(RoundedRectangle(cornerRadius: Span.corner))
    }
}

struct SolidButton: View {
    let title: String
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Tone.copy(16, .semibold))
                .foregroundColor(Tone.onAccent)
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity)
                .background(Tone.accent.opacity(isEnabled ? 1 : 0.3))
                .clipShape(RoundedRectangle(cornerRadius: Span.corner))
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
    }
}

struct OutlineButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Tone.copy(15, .medium))
                .foregroundColor(Tone.accent)
                .padding(.vertical, 13)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: Span.corner)
                        .stroke(Tone.accent.opacity(0.4), lineWidth: Span.rule)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Every screen sits on the page, scrolls, and keeps its text column to a readable width so
/// an iPad or a landscape phone gets a page rather than a stretched line.
struct Screen<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                content
            }
            .padding(.horizontal, Span.gutter)
            .padding(.top, 10)
            .padding(.bottom, 36)
            .frame(maxWidth: Span.column, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Tone.page.ignoresSafeArea())
    }
}
