import SwiftUI

enum Theme {
    static let bg = Color(hex: 0x080D18)
    static let bgGlow = Color(hex: 0x17233D)
    static let dial = Color(hex: 0x0F1A30)
    static let dialHighlight = Color(hex: 0x1A2A4A)
    static let red = Color(hex: 0xC4333D)
    static let blue = Color(hex: 0x1F4C9E)
    static let lume = Color(hex: 0xE6F0CF)
    static let ink = Color(hex: 0xEEF1F6)
    static let muted = Color(hex: 0x8592AB)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Draws one frame of the game. Angles are in radians, 0 points right and they grow clockwise on screen.
enum GameRenderer {

    static func draw(game: GameModel, in context: inout GraphicsContext, size: CGSize, time: Double) {
        let w = size.width
        let h = size.height
        let r = min(w * 0.45, h * 0.34)
        let center = CGPoint(x: w / 2, y: h * 0.47)

        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .radialGradient(
                Gradient(colors: [Theme.bgGlow, Theme.bg]),
                center: center,
                startRadius: r * 0.5,
                endRadius: max(w, h) * 0.8
            )
        )

        var watch = context
        if game.shake > 0 {
            let amount = CGFloat(game.shake) * r * 0.08
            watch.translateBy(
                x: CGFloat.random(in: -0.5...0.5) * amount,
                y: CGFloat.random(in: -0.5...0.5) * amount
            )
        }

        drawBezel(&watch, center: center, r: r)
        drawDial(&watch, center: center, r: r, game: game)
        drawTarget(&watch, center: center, r: r, game: game, time: time)
        drawPops(&watch, center: center, r: r, game: game, time: time)
        drawHand(&watch, center: center, r: r, game: game)

        if game.flash > 0 {
            var flash = watch
            flash.opacity = game.flash * 0.4
            flash.fill(circle(center, r * 0.84), with: .color(Theme.red))
        }

        drawLabels(&context, size: size, game: game, time: time)
    }

    // MARK: Helpers

    private static func polar(_ c: CGPoint, _ angle: Double, _ radius: CGFloat) -> CGPoint {
        CGPoint(x: c.x + CGFloat(cos(angle)) * radius, y: c.y + CGFloat(sin(angle)) * radius)
    }

    private static func circle(_ c: CGPoint, _ radius: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: c.x - radius, y: c.y - radius, width: radius * 2, height: radius * 2))
    }

    private static func arc(_ c: CGPoint, _ radius: CGFloat, from a0: Double, to a1: Double) -> Path {
        var p = Path()
        p.addArc(center: c, radius: radius, startAngle: .radians(a0), endAngle: .radians(a1), clockwise: false)
        return p
    }

    private static func triangle(at p: CGPoint, size s: CGFloat) -> Path {
        var t = Path()
        t.move(to: CGPoint(x: p.x, y: p.y + s))
        t.addLine(to: CGPoint(x: p.x - s, y: p.y - s * 0.8))
        t.addLine(to: CGPoint(x: p.x + s, y: p.y - s * 0.8))
        t.closeSubpath()
        return t
    }

    private static func numberFont(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        Font.system(size: size, weight: weight).width(.condensed)
    }

    // MARK: Watch parts

    private static func drawBezel(_ ctx: inout GraphicsContext, center: CGPoint, r: CGFloat) {
        let bezelRadius = r * 0.92
        let bezelWidth = r * 0.16
        ctx.stroke(arc(center, bezelRadius, from: Double.pi, to: 2 * Double.pi), with: .color(Theme.red), lineWidth: bezelWidth)
        ctx.stroke(arc(center, bezelRadius, from: 0, to: Double.pi), with: .color(Theme.blue), lineWidth: bezelWidth)
        ctx.stroke(circle(center, r), with: .color(.black.opacity(0.45)), lineWidth: max(1, r * 0.008))

        // 24 hour scale
        for hour in 0..<24 {
            let a = Double(hour) / 24 * 2 * Double.pi - Double.pi / 2
            let p = polar(center, a, bezelRadius)
            if hour == 0 {
                ctx.fill(triangle(at: p, size: r * 0.055), with: .color(Theme.ink))
            } else if hour % 2 == 0 {
                var label = ctx
                label.translateBy(x: p.x, y: p.y)
                label.rotate(by: .radians(a + Double.pi / 2))
                let text = Text("\(hour)")
                    .font(numberFont(r * 0.085, .semibold))
                    .foregroundColor(Theme.ink)
                label.draw(text, at: .zero, anchor: .center)
            } else {
                ctx.fill(circle(p, r * 0.012), with: .color(Theme.ink))
            }
        }
    }

    private static func drawDial(_ ctx: inout GraphicsContext, center: CGPoint, r: CGFloat, game: GameModel) {
        let dialRadius = r * 0.84
        ctx.fill(
            circle(center, dialRadius),
            with: .radialGradient(
                Gradient(colors: [Theme.dialHighlight, Theme.dial]),
                center: CGPoint(x: center.x, y: center.y - dialRadius * 0.4),
                startRadius: dialRadius * 0.1,
                endRadius: dialRadius
            )
        )

        // Minute track
        var small = Path()
        var big = Path()
        for i in 0..<60 {
            let a = Double(i) / 60 * 2 * Double.pi - Double.pi / 2
            let isBig = i % 5 == 0
            let outer = polar(center, a, r * 0.81)
            let inner = polar(center, a, r * (isBig ? 0.735 : 0.765))
            if isBig {
                big.move(to: outer)
                big.addLine(to: inner)
            } else {
                small.move(to: outer)
                small.addLine(to: inner)
            }
        }
        ctx.stroke(small, with: .color(Theme.muted), lineWidth: r * 0.006)
        ctx.stroke(big, with: .color(Theme.muted), lineWidth: r * 0.012)

        // Hour markers, dimmed so the target stands out
        var markers = ctx
        markers.opacity = 0.5
        for hour in 0..<12 {
            let a = Double(hour) / 12 * 2 * Double.pi - Double.pi / 2
            let p = polar(center, a, r * 0.65)
            if hour == 0 {
                markers.fill(triangle(at: p, size: r * 0.05), with: .color(Theme.lume))
            } else {
                markers.fill(circle(p, r * (hour % 3 == 0 ? 0.04 : 0.032)), with: .color(Theme.lume))
            }
        }

        // Score and best, printed on the dial
        let scale = 1 + CGFloat(game.pop) * 0.18
        let scoreValue = game.state == .ready ? game.best : game.score
        let scoreText = Text("\(scoreValue)")
            .font(numberFont(r * 0.3 * scale, .bold))
            .foregroundColor(Theme.ink)
        ctx.draw(scoreText, at: CGPoint(x: center.x, y: center.y - r * 0.32), anchor: .center)

        let bestLabel = game.state == .ready ? "BEST" : "BEST \(game.best)"
        let bestText = Text(bestLabel)
            .font(numberFont(r * 0.075, .medium))
            .foregroundColor(Theme.muted)
        ctx.draw(bestText, at: CGPoint(x: center.x, y: center.y + r * 0.34), anchor: .center)
    }

    private static func drawTarget(_ ctx: inout GraphicsContext, center: CGPoint, r: CGFloat, game: GameModel, time: Double) {
        guard game.state != .ready else { return }
        var glow = ctx
        glow.opacity = game.state == .over ? 0.35 : 0.75 + 0.25 * sin(time / 0.14)
        glow.addFilter(.shadow(color: Theme.lume, radius: r * 0.06))
        glow.stroke(
            arc(center, r * 0.755, from: game.target - game.tolerance, to: game.target + game.tolerance),
            with: .color(Theme.lume),
            lineWidth: r * 0.1
        )
    }

    private static func drawPops(_ ctx: inout GraphicsContext, center: CGPoint, r: CGFloat, game: GameModel, time: Double) {
        for p in game.pops {
            let k = CGFloat(min(1, max(0, (time - p.born) / 0.45)))
            var ring = ctx
            ring.opacity = Double(1 - k)
            let at = polar(center, p.angle, r * 0.755)
            ring.stroke(
                circle(at, r * (0.05 + k * 0.16)),
                with: .color(Theme.lume),
                lineWidth: r * 0.02 * (1 - k) + 1
            )
        }
    }

    private static func drawHand(_ ctx: inout GraphicsContext, center: CGPoint, r: CGFloat, game: GameModel) {
        let length = r * 0.76
        let tail = r * 0.2
        let width = r * 0.032

        var hand = ctx
        hand.translateBy(x: center.x, y: center.y)
        hand.rotate(by: .radians(game.hand))

        var shape = Path()
        shape.move(to: CGPoint(x: -tail, y: -width * 0.8))
        shape.addLine(to: CGPoint(x: length - width * 3, y: -width))
        shape.addLine(to: CGPoint(x: length, y: 0))
        shape.addLine(to: CGPoint(x: length - width * 3, y: width))
        shape.addLine(to: CGPoint(x: -tail, y: width * 0.8))
        shape.closeSubpath()

        var shadowed = hand
        shadowed.addFilter(.shadow(color: .black.opacity(0.5), radius: r * 0.02, x: 0, y: r * 0.015))
        shadowed.fill(shape, with: .color(Theme.ink))

        // Lume inlay near the tip
        hand.fill(
            Path(CGRect(x: length * 0.45, y: -width * 0.45, width: length * 0.38, height: width * 0.9)),
            with: .color(Theme.lume)
        )

        // Pivot
        ctx.fill(circle(center, r * 0.055), with: .color(Theme.red))
        ctx.fill(circle(center, r * 0.018), with: .color(Theme.ink))
    }

    // MARK: Text around the watch

    private static func drawLabels(_ ctx: inout GraphicsContext, size: CGSize, game: GameModel, time: Double) {
        let midX = size.width / 2
        let bottom = size.height

        let wordmark = Text("TICK")
            .font(numberFont(26, .bold))
            .kerning(13)
            .foregroundColor(Theme.ink.opacity(0.9))
        ctx.draw(wordmark, at: CGPoint(x: midX + 6.5, y: 34), anchor: .center)

        let blink = 0.65 + 0.35 * cos(time * 2 * Double.pi / 1.4)

        switch game.state {
        case .ready:
            let line = Text("Tap when the hand hits the glowing marker.")
                .font(.system(size: 16))
                .foregroundColor(Theme.ink)
            ctx.draw(line, at: CGPoint(x: midX, y: bottom - 62), anchor: .center)
            var hint = ctx
            hint.opacity = blink
            hint.draw(
                Text("Tap anywhere to start").font(.system(size: 14)).foregroundColor(Theme.muted),
                at: CGPoint(x: midX, y: bottom - 36),
                anchor: .center
            )

        case .playing:
            break

        case .over:
            let eyebrowLabel: String
            let eyebrowColor: Color
            if game.isNewBest {
                eyebrowLabel = "NEW BEST"
                eyebrowColor = Theme.lume
            } else {
                eyebrowLabel = game.missReason == .early ? "TOO EARLY" : "TOO LATE"
                eyebrowColor = Theme.red
            }
            let eyebrow = Text(eyebrowLabel)
                .font(numberFont(18, .bold))
                .kerning(3.5)
                .foregroundColor(eyebrowColor)
            ctx.draw(eyebrow, at: CGPoint(x: midX, y: bottom - 90), anchor: .center)

            let ticks = game.score == 1 ? "1 tick" : "\(game.score) ticks"
            ctx.draw(
                Text(ticks).font(.system(size: 17)).foregroundColor(Theme.ink),
                at: CGPoint(x: midX, y: bottom - 62),
                anchor: .center
            )
            var hint = ctx
            hint.opacity = blink
            hint.draw(
                Text("Tap to try again").font(.system(size: 14)).foregroundColor(Theme.muted),
                at: CGPoint(x: midX, y: bottom - 36),
                anchor: .center
            )
        }
    }
}
