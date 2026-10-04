import SwiftUI

struct PacketRushView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var game = PacketRushGame()
    @State private var selectedRoute = 0
    @State private var lockedRoute: Int?
    @State private var progress = 0.0
    @State private var running = false
    @State private var started = false

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 700
            ArcadeGameShell(game: .packetRush, feedback: game.score, showIntro: !started) {
                ArcadeStats(progress: "Packet \(min(game.index + 1, game.packets.count)) of \(game.packets.count)", score: game.score, detail: "Streak \(game.streak)")
                if game.finished {
                    ArcadeResult(title: "Wave complete", detail: "\(game.delivered) of \(game.packets.count) packets delivered", score: game.score) {
                        game = PacketRushGame(); selectedRoute = 0; progress = 0; lockedRoute = nil; running = false; started = false
                    }
                } else {
                    VStack(spacing: compact ? 8 : 12) {
                        Label(game.officeDown ? "Office link down · backup live" : "All primary routes online", systemImage: game.officeDown ? "exclamationmark.triangle.fill" : "network")
                            .font(.caption.weight(.semibold)).foregroundStyle(game.officeDown ? .orange : .secondary)
                        Text(game.address).font(.system(.title2, design: .monospaced).bold()).accessibilityIdentifier("packet.destination")
                        if !compact { Text("Incoming destination").font(.caption).foregroundStyle(.secondary) }
                        network(height: compact ? 100 : 160)
                        ProgressView(value: progress).tint(.indigo).accessibilityLabel("Packet travel").accessibilityValue("\(Int(progress * 100)) percent")
                    }.padding(18).rollerPanel()
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(PacketRushGame.routes) { route in
                            let live = game.availableRoutes.contains { $0.id == route.id }
                            Button { selectedRoute = route.id } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Label(route.name, systemImage: selectedRoute == route.id ? "checkmark.circle.fill" : "arrow.up.right")
                                        .font(.subheadline.weight(.semibold))
                                    Text(route.cidr).font(.system(.caption, design: .monospaced))
                                    if !live { Text(route.id == 3 ? "Standby" : "Offline").font(.caption2) }
                                }
                                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading).padding(12)
                                .foregroundStyle(live ? Color.primary : Color.secondary)
                                .background(selectedRoute == route.id && live ? Color.indigo.opacity(0.14) : RollerStyle.panel, in: RoundedRectangle(cornerRadius: 16))
                                .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(selectedRoute == route.id && live ? Color.indigo : .clear, lineWidth: 2) }
                            }
                            .buttonStyle(.plain).disabled(!live)
                            .accessibilityIdentifier("packet.route.\(route.id)").accessibilityAddTraits(selectedRoute == route.id ? .isSelected : [])
                        }
                    }
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) { waveControls }
                        VStack(spacing: 12) { waveControls }
                    }
                }
                ArcadeFeedback(message: game.message, positive: game.finished && game.delivered == game.packets.count)
            }
        }
        .task {
            var last = Date()
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(50)) } catch { return }
                let now = Date(), delta = min(0.1, now.timeIntervalSince(last)); last = now
                guard running, scenePhase == .active, !game.finished else { continue }
                progress += delta / (game.officeDown ? 2.6 : 3.5)
                if progress >= 0.55 && lockedRoute == nil { lockedRoute = selectedRoute }
                if progress >= 1 { deliver() }
            }
        }
        .onDisappear { running = false }
        .onChange(of: scenePhase) { if scenePhase != .active { running = false } }
    }
    @ViewBuilder private var waveControls: some View {
        Button(running ? "Pause" : progress == 0 && game.index == 0 ? "Start wave" : "Resume", systemImage: running ? "pause.fill" : "play.fill") { started = true; running.toggle() }
            .buttonStyle(.borderedProminent).controlSize(.large).frame(maxWidth: .infinity).accessibilityIdentifier("packet.start")
        Button("Send now", systemImage: "paperplane.fill", action: deliver)
            .buttonStyle(.bordered).controlSize(.large).frame(maxWidth: .infinity).accessibilityIdentifier("packet.send")
    }
    private func network(height: CGFloat) -> some View {
        GeometryReader { geometry in
            let start = CGPoint(x: 12, y: height * 0.5)
            let junction = CGPoint(x: geometry.size.width * 0.43, y: height * 0.5)
            let gate = lockedRoute ?? selectedRoute
            let end = CGPoint(x: geometry.size.width - 22, y: height * (gate == 0 || gate == 3 ? 0.15 : gate == 1 ? 0.5 : 0.87))
            ZStack {
                Canvas { context, size in
                    for y in [height * 0.15, height * 0.5, height * 0.87] {
                        var path = Path(); path.move(to: start); path.addLine(to: junction); path.addLine(to: CGPoint(x: size.width - 22, y: y))
                        context.stroke(path, with: .color(.secondary.opacity(0.2)), lineWidth: 3)
                    }
                    var selected = Path(); selected.move(to: start); selected.addLine(to: junction); selected.addLine(to: end)
                    context.stroke(selected, with: .color(.indigo), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                }
                Image(systemName: "arrow.triangle.branch").font(.title2).foregroundStyle(.indigo)
                    .padding(12).background(RollerStyle.elevated, in: RoundedRectangle(cornerRadius: 14)).position(junction)
                ForEach(Array(["Office", "Campus", "Internet"].enumerated()), id: \.offset) { index, label in
                    Text(label).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                        .position(x: geometry.size.width - 30, y: height * [0.15, 0.5, 0.87][index] - 12)
                }
                Image(systemName: "shippingbox.fill").foregroundStyle(.indigo).font(.title3)
                    .position(packetPosition(start: start, junction: junction, end: end))
            }
        }.frame(height: height).accessibilityHidden(true)
    }
    private func packetPosition(start: CGPoint, junction: CGPoint, end: CGPoint) -> CGPoint {
        guard !reduceMotion else { return start }
        let a = progress < 0.55 ? start : junction, b = progress < 0.55 ? junction : end
        let t = progress < 0.55 ? progress / 0.55 : (progress - 0.55) / 0.45
        return CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }
    private func deliver() {
        guard !game.finished else { return }
        game.send(to: lockedRoute ?? selectedRoute); progress = 0; lockedRoute = nil
        if game.finished { running = false }
        if game.officeDown && selectedRoute == 0 { selectedRoute = 3 }
    }
}

#Preview { NavigationStack { PacketRushView() } }
