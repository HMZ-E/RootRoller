import SwiftUI
import UIKit
import AVFoundation

/// Display-linked motion keeps the drum and its detent feedback in step.
@MainActor
final class ReelMotion: ObservableObject {
    @Published private(set) var position: Double = 0
    @Published private(set) var isMoving = false
    @Published private(set) var selectedGame = MiniGame.subnetSlots
    @Published private(set) var hasRolled = false
    @Published private(set) var landing = 0

    var reduceMotion = false
    private var hapticsEnabled = true
    private var soundsEnabled = false
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let landingFeedback = UIImpactFeedbackGenerator(style: .rigid)
    private var clickPlayer: AVAudioPlayer?
    private var landingPlayer: AVAudioPlayer?
    private var link: CADisplayLink?
    private var proxy: ReelDisplayLinkProxy?
    private var lastFrame: CFTimeInterval = 0
    private var lastFeedback: CFTimeInterval = 0
    private var lastDetent = 0
    private var dragOrigin = 0.0
    private var dragTranslation = 0.0
    private var dragTimestamp: CFTimeInterval = 0
    private var dragVelocity = 0.0
    private var pointsPerSlot = 76.0
    private var phase: Phase?

    private enum Phase {
        case spin(start: Double, target: Double, began: CFTimeInterval)
        case coast(velocity: Double)
        case snap(target: Double, velocity: Double)
    }

    func configure(haptics: Bool, sounds: Bool, reduceMotion: Bool, pointsPerSlot: Double) {
        hapticsEnabled = haptics
        soundsEnabled = sounds
        self.reduceMotion = reduceMotion
        self.pointsPerSlot = pointsPerSlot
        if !sounds { clickPlayer?.stop(); landingPlayer?.stop() }
    }

    func roll() {
        guard !isMoving else { return }
        prepareFeedback()
        let extra = Int.random(in: 1..<MiniGame.allCases.count)
        let target = position.rounded() + Double(MiniGame.allCases.count * 5 + extra)
        if reduceMotion { position = target; finish(); return }
        phase = .spin(start: position, target: target, began: CACurrentMediaTime())
        startFrames()
    }

    func beginDrag() {
        invalidateFrames()
        dragOrigin = position
        dragTranslation = 0
        dragTimestamp = CACurrentMediaTime()
        dragVelocity = 0
        isMoving = true
        prepareFeedback()
    }

    func drag(translation: CGFloat) {
        let now = CACurrentMediaTime()
        let next = Double(translation)
        let dt = max(0.008, now - dragTimestamp)
        let velocity = -(next - dragTranslation) / pointsPerSlot / dt
        dragVelocity = dragVelocity * 0.3 + velocity * 0.7
        dragTranslation = next
        dragTimestamp = now
        position = dragOrigin - next / pointsPerSlot
        tick()
    }

    func endDrag(translation: CGFloat) {
        position = dragOrigin - Double(translation) / pointsPerSlot
        // A finger held still should stop the drum, rather than retain a stale prediction.
        let age = CACurrentMediaTime() - dragTimestamp
        let velocity = max(-22, min(22, dragVelocity * exp(-age / 0.09)))
        if reduceMotion { position = position.rounded(); finish(); return }
        phase = abs(velocity) < 0.65 ? .snap(target: position.rounded(), velocity: 0) : .coast(velocity: velocity)
        startFrames()
    }

    func adjust(by steps: Int) {
        guard !isMoving else { return }
        prepareFeedback()
        let target = position.rounded() + Double(steps)
        if reduceMotion { position = target; finish(); return }
        phase = .snap(target: target, velocity: 0)
        startFrames()
    }

    /// Stop the display link when the hub disappears or the app becomes inactive.
    func stop() {
        invalidateFrames()
        phase = nil
        position = position.rounded()
        normalizePosition()
        selectedGame = MiniGame.at(Int(position))
        lastDetent = Int(position)
        isMoving = false
        clickPlayer?.stop()
        landingPlayer?.stop()
    }

    private func prepareFeedback() {
        if hapticsEnabled { selectionFeedback.prepare(); landingFeedback.prepare() }
        guard soundsEnabled, clickPlayer == nil else { return }
        do {
            // Ambient sound respects the silent switch and other audio playback.
            try AVAudioSession.sharedInstance().setCategory(.ambient)
            clickPlayer = try AVAudioPlayer(data: Self.clickWave(landing: false))
            landingPlayer = try AVAudioPlayer(data: Self.clickWave(landing: true))
            clickPlayer?.volume = 0.24
            landingPlayer?.volume = 0.28
            clickPlayer?.prepareToPlay()
            landingPlayer?.prepareToPlay()
        } catch {
            // The reel remains usable if an audio route cannot be opened.
            clickPlayer = nil
            landingPlayer = nil
        }
    }

    private func startFrames() {
        invalidateFrames()
        isMoving = true
        lastFrame = CACurrentMediaTime()
        let target = ReelDisplayLinkProxy(owner: self)
        let displayLink = CADisplayLink(target: target, selector: #selector(ReelDisplayLinkProxy.frame(_:)))
        displayLink.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 120, preferred: 60)
        displayLink.add(to: .main, forMode: .common)
        proxy = target
        link = displayLink
    }

    private func invalidateFrames() {
        link?.invalidate()
        link = nil
        proxy = nil
    }

    fileprivate func advance(_ displayLink: CADisplayLink) {
        let now = displayLink.timestamp
        let dt = max(0.001, min(0.033, now - lastFrame))
        lastFrame = now
        switch phase {
        case let .spin(start, target, began):
            let t = min(1, max(0, (now - began) / 1.7))
            position = start + (target + 0.1 - start) * (1 - pow(1 - t, 3.3))
            if t == 1 { phase = .snap(target: target, velocity: 0) }
        case let .coast(initialVelocity):
            let velocity = initialVelocity * exp(-3.5 * dt)
            position += velocity * dt
            phase = abs(velocity) < 0.65
                ? .snap(target: (position + velocity * 0.08).rounded(), velocity: velocity)
                : .coast(velocity: velocity)
        case let .snap(target, initialVelocity):
            var velocity = initialVelocity + (target - position) * 185 * dt
            velocity *= exp(-19 * dt)
            position += velocity * dt
            if abs(target - position) < 0.002 && abs(velocity) < 0.025 {
                position = target
                finish()
                return
            }
            phase = .snap(target: target, velocity: velocity)
        case nil:
            stop()
            return
        }
        tick()
    }

    private func tick() {
        let detent = Int(position.rounded())
        guard detent != lastDetent else { return }
        lastDetent = detent
        let now = CACurrentMediaTime()
        guard now - lastFeedback > 0.045 else { return }
        lastFeedback = now
        if hapticsEnabled { selectionFeedback.selectionChanged(); selectionFeedback.prepare() }
        if soundsEnabled { clickPlayer?.currentTime = 0; clickPlayer?.play() }
    }

    private func finish() {
        invalidateFrames()
        phase = nil
        position = position.rounded()
        normalizePosition()
        selectedGame = MiniGame.at(Int(position))
        lastDetent = Int(position)
        hasRolled = true
        isMoving = false
        landing += 1
        if hapticsEnabled { landingFeedback.impactOccurred(intensity: 0.55) }
        if soundsEnabled { landingPlayer?.currentTime = 0; landingPlayer?.play() }
    }

    private func normalizePosition() {
        position = Double(((Int(position) % MiniGame.allCases.count) + MiniGame.allCases.count) % MiniGame.allCases.count)
    }

    /// A short, original PCM click avoids a dependency on external sound assets.
    private static func clickWave(landing: Bool) -> Data {
        let sampleRate = 22_050
        let duration = landing ? 0.05 : 0.018
        let count = Int(Double(sampleRate) * duration)
        var samples = Data(capacity: count * 2)
        var noise: UInt32 = 0x726F6C6C
        for index in 0..<count {
            noise = noise &* 1_664_525 &+ 1_013_904_223
            let random = Double(noise) / Double(UInt32.max) * 2 - 1
            let t = Double(index) / Double(sampleRate)
            let envelope = exp(-t / (landing ? 0.009 : 0.003)) * min(1, t / 0.0008)
            let tone = sin(2 * .pi * (landing ? 190 : 950) * t)
            let value = Int16((tone * 0.55 + random * 0.3) * envelope * 20_000)
            samples.appendLittleEndian(UInt16(bitPattern: value))
        }
        var wave = Data()
        wave.append(contentsOf: "RIFF".utf8)
        wave.appendLittleEndian(UInt32(36 + samples.count))
        wave.append(contentsOf: "WAVEfmt ".utf8)
        wave.appendLittleEndian(UInt32(16))
        wave.appendLittleEndian(UInt16(1))
        wave.appendLittleEndian(UInt16(1))
        wave.appendLittleEndian(UInt32(sampleRate))
        wave.appendLittleEndian(UInt32(sampleRate * 2))
        wave.appendLittleEndian(UInt16(2))
        wave.appendLittleEndian(UInt16(16))
        wave.append(contentsOf: "data".utf8)
        wave.appendLittleEndian(UInt32(samples.count))
        wave.append(samples)
        return wave
    }
}

@MainActor
private final class ReelDisplayLinkProxy: NSObject {
    weak var owner: ReelMotion?
    init(owner: ReelMotion) { self.owner = owner }
    @objc func frame(_ link: CADisplayLink) {
        guard let owner else { link.invalidate(); return }
        owner.advance(link)
    }
}

private extension Data {
    mutating func appendLittleEndian<T: FixedWidthInteger>(_ value: T) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { append(contentsOf: $0) }
    }
}
