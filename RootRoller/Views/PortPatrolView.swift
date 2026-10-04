import SwiftUI

struct PortPatrolView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var game = PortPatrolGame()
    @State private var running = false
    @State private var started = false
    @State private var practice = false
    @State private var secondsLeft = 45.0
    @State private var drag = CGSize.zero
    var body: some View {
        ArcadeGameShell(game: .portPatrol, feedback: game.score, showIntro: !started) {
            ArcadeStats(progress: "\(game.correct) cleared · \(game.mistakes)/3 mistakes", score: game.score, detail: practice ? "Practice" : "\(Int(ceil(secondsLeft)))s")
            if game.finished {
                ArcadeResult(title: game.index == game.packets.count ? "Shift complete" : "Shift ended", detail: "\(game.correct) correct decisions. \(game.message)", score: game.score) { restart() }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Label(game.policyChanged ? "Updated policy" : "Firewall policy", systemImage: "checkmark.shield.fill").font(.headline).foregroundStyle(.green)
                    Text(game.policy).font(.subheadline).fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("patrol.policy")
                    Text("Office = 10.0.0.0/24").font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary)
                }.padding(18).rollerPanel()
                packetCard
                    .offset(x: reduceMotion ? 0 : drag.width)
                    .rotationEffect(.degrees(reduceMotion ? 0 : Double(drag.width / 25)))
                    .gesture(DragGesture(minimumDistance: 15).onChanged { value in
                        guard running else { return }; drag = value.translation
                    }.onEnded { value in
                        if running && abs(value.translation.width) > 65 && abs(value.translation.width) > abs(value.translation.height) { decide(value.translation.width > 0) }
                        withAnimation(reduceMotion ? nil : .spring(duration: 0.25)) { drag = .zero }
                    })
                if !started { Toggle("Practice · no time limit", isOn: $practice).font(.subheadline).accessibilityIdentifier("patrol.practice") }
                if typeSize.isAccessibilitySize { patrolControls }
                ArcadeFeedback(message: game.message)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !game.finished && !typeSize.isAccessibilitySize {
                RollerBottomBar { patrolControls }
            }
        }
        .task {
            var last = Date()
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
                let now = Date(), delta = min(0.2, now.timeIntervalSince(last)); last = now
                guard running, !practice, scenePhase == .active, !game.finished else { continue }
                secondsLeft = max(0, secondsLeft - delta)
                if secondsLeft == 0 { game.expire(); running = false }
            }
        }
        .onDisappear { running = false }
        .onChange(of: scenePhase) { if scenePhase != .active { running = false } }
    }
    private var packetCard: some View {
        VStack(spacing: 12) {
            if !started {
                Image(systemName: game.packet.port == 443 ? "lock.shield.fill" : "shippingbox.fill").font(.system(size: 42)).foregroundStyle(.green).accessibilityHidden(true)
            }
            Text("\(game.packet.transport) · \(game.packet.port)").font(.system(.title, design: .monospaced).bold()).accessibilityIdentifier("patrol.packet")
            Text(game.packet.service).font(.headline)
            Text(game.packet.source).font(.system(.subheadline, design: .monospaced)).foregroundStyle(.secondary).accessibilityIdentifier("patrol.source")
            Text("← Block     Allow →").font(.caption).foregroundStyle(.secondary)
        }.padding(24).frame(maxWidth: .infinity).rollerPanel()
        .overlay { RoundedRectangle(cornerRadius: 22).strokeBorder(drag.width < -30 ? Color.red : drag.width > 30 ? .green : .clear, lineWidth: 2) }
    }
    private var patrolControls: some View {
        VStack(spacing: 12) {
            if started {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) { decisionControls }
                    VStack(spacing: 10) { decisionControls }
                }
            } else {
                Button("Start shift", systemImage: "play.fill") { started = true; running = true }
                    .buttonStyle(.borderedProminent).controlSize(.large).accessibilityIdentifier("patrol.start")
            }
        }
    }
    @ViewBuilder private var decisionControls: some View {
        Button("Block", systemImage: "xmark.shield.fill") { decide(false) }.tint(.red)
            .buttonStyle(.borderedProminent).controlSize(.large).disabled(!running).accessibilityIdentifier("patrol.block")
        Button("Allow", systemImage: "checkmark.shield.fill") { decide(true) }.tint(.green)
            .buttonStyle(.borderedProminent).controlSize(.large).disabled(!running).accessibilityIdentifier("patrol.allow")
        Button(running ? "Pause shift" : "Resume shift", systemImage: running ? "pause.fill" : "play.fill") { running.toggle() }
            .labelStyle(.iconOnly).buttonStyle(.bordered).controlSize(.large).accessibilityIdentifier("patrol.start")
    }
    private func decide(_ allow: Bool) {
        guard running, !game.finished else { return }
        game.decide(allow: allow); drag = .zero
        if game.finished { running = false }
    }
    private func restart() { game = PortPatrolGame(); secondsLeft = 45; running = false; started = false; drag = .zero }
}

#Preview { NavigationStack { PortPatrolView() } }
