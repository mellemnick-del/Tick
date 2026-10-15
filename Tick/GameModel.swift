import Foundation
import UIKit
import AudioToolbox

/// All the game rules. The view calls `step(to:)` every frame and `tap()` on every touch.
final class GameModel {
    enum State { case ready, playing, over }
    enum MissReason { case early, late }

    struct Pop {
        let angle: Double
        let born: Double
    }

    // Tuning knobs (same values as the web prototype)
    private let startSpeed = 2.0       // radians per second
    private let speedStep = 0.075
    private let maxSpeed = 5.4
    private let startTolerance = 0.19  // half width of the marker, radians
    private let minTolerance = 0.11
    private let grace = 0.025          // a little forgiveness beyond the drawn marker

    private(set) var state: State = .ready
    private(set) var score = 0
    private(set) var best: Int
    private(set) var hand = -Double.pi / 2
    private(set) var tolerance = 0.19
    private(set) var target = 0.0
    private(set) var missReason: MissReason = .late
    private(set) var isNewBest = false
    private(set) var flash = 0.0
    private(set) var shake = 0.0
    private(set) var pop = 0.0
    private(set) var pops: [Pop] = []

    private var direction = 1.0
    private var speed = 2.0
    private var remaining = 0.0
    private var lastTime: Double?
    private var now = 0.0
    private var overAt = 0.0

    private let bestKey = "tick.best"
    private let hitHaptic = UIImpactFeedbackGenerator(style: .rigid)
    private let missHaptic = UINotificationFeedbackGenerator()

    init() {
        best = UserDefaults.standard.integer(forKey: bestKey)
    }

    // MARK: Input

    func tap() {
        switch state {
        case .ready:
            start()
        case .over:
            if now - overAt > 0.55 { start() }
        case .playing:
            if abs(remaining) <= tolerance + grace {
                hit()
            } else {
                miss(remaining > 0 ? .early : .late)
            }
        }
    }

    // MARK: Frame update

    func step(to time: Double) {
        now = time
        guard let last = lastTime else {
            lastTime = time
            return
        }
        lastTime = time
        let dt = min(0.05, max(0, time - last))

        switch state {
        case .ready:
            // Ticks like a seconds hand while waiting
            hand = -Double.pi / 2 + floor(time) * (2 * Double.pi) / 60
        case .playing:
            hand += direction * speed * dt
            remaining -= speed * dt
            if remaining < -(tolerance + grace) { miss(.late) }
        case .over:
            break
        }

        pop = max(0, pop - dt * 5)
        flash = max(0, flash - dt * 2.2)
        shake = max(0, shake - dt * 3.5)
        pops.removeAll { time - $0.born > 0.45 }
    }

    // MARK: Rules

    private func start() {
        state = .playing
        score = 0
        direction = 1
        speed = startSpeed
        tolerance = startTolerance
        hand = -Double.pi / 2
        isNewBest = false
        newTarget()
        hitHaptic.prepare()
    }

    private func newTarget() {
        let gap = (0.5 + Double.random(in: 0..<1) * 1.1) * Double.pi
        remaining = gap
        target = hand + direction * gap
    }

    private func hit() {
        score += 1
        pops.append(Pop(angle: target, born: now))
        direction *= -1
        speed = min(maxSpeed, startSpeed + Double(score) * speedStep)
        tolerance = max(minTolerance, startTolerance - Double(score) * 0.0025)
        pop = 1
        hitHaptic.impactOccurred()
        hitHaptic.prepare()
        AudioServicesPlaySystemSound(1104)
        newTarget()
    }

    private func miss(_ reason: MissReason) {
        state = .over
        missReason = reason
        flash = 1
        shake = 1
        overAt = now
        if score > best {
            best = score
            isNewBest = true
            UserDefaults.standard.set(best, forKey: bestKey)
        }
        missHaptic.notificationOccurred(.error)
    }
}
