import SwiftUI

struct HandshakeHeroView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var game = HandshakeHeroGame()
    @State private var sender = HandshakeHeroGame.Sender.client
    @State private var flightSender = HandshakeHeroGame.Sender.client
    @State private var flightPacket = "SYN"
    @State private var flight = 0.0
    @State private var sending = false
    @State private var event = 0
    private func pulse(at date: Date) -> Double { date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2.2) / 2.2 }
    var body: some View {
        ArcadeGameShell(game: .handshakeHero, feedback: game.score) {
            ArcadeStats(progress: game.connected ? "TCP established · deliver data" : "Establish the connection", score: game.score, detail: "\(game.mistakes) misses")
            if game.finished {
                ArcadeResult(title: "Reliable delivery", detail: "Handshake complete. Both DATA segments acknowledged, including one retransmission.", score: game.score) { game = HandshakeHeroGame(); sender = .client; event = 0; sending = false }
            } else {
                VStack(spacing: 18) {
                    HStack(spacing: 12) {
                        ForEach(HandshakeHeroGame.Sender.allCases) { endpoint in
                            Button { sender = endpoint } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: endpoint == .client ? "laptopcomputer" : "server.rack").font(.title)
                                    Text(endpoint.rawValue).font(.headline)
                                    Text(sender == endpoint ? "Sending from here" : "Tap to send from here").font(.caption).multilineTextAlignment(.center)
                                }.padding(14).frame(maxWidth: .infinity)
                                    .foregroundStyle(sender == endpoint ? Color.purple : .secondary)
                                    .background(sender == endpoint ? Color.purple.opacity(0.12) : RollerStyle.elevated, in: RoundedRectangle(cornerRadius: 16))
                            }.buttonStyle(.plain).accessibilityIdentifier("tcp.sender.\(endpoint.rawValue)")
                                .accessibilityAddTraits(sender == endpoint ? .isSelected : [])
                        }
                    }
                    flightLane
                    Text(game.prompt).font(.system(.headline, design: .monospaced)).accessibilityIdentifier("tcp.prompt")
                    ProgressView(value: Double(game.index), total: Double(HandshakeHeroGame.exchanges.count)).tint(.purple)
                }.padding(16).rollerPanel()
                if reduceMotion {
                    Text("Timing bonus off with Reduce Motion. Send at your own pace.").font(.caption).foregroundStyle(.secondary)
                } else {
                    TimelineView(.animation(minimumInterval: 0.03, paused: scenePhase != .active)) { timeline in
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule().fill(RollerStyle.panel)
                                RoundedRectangle(cornerRadius: 7).fill(.green.opacity(0.28)).frame(width: geometry.size.width * 0.3).offset(x: geometry.size.width * 0.4)
                                Capsule().fill(.purple).frame(width: 8, height: 28).offset(x: (geometry.size.width - 8) * pulse(at: timeline.date))
                            }
                        }.frame(height: 28)
                    }.accessibilityHidden(true)
                    Text("Green pulse = +50 R timing bonus. Every correct packet still counts.").font(.caption).foregroundStyle(.secondary)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                    ForEach(HandshakeHeroGame.Packet.allCases) { packet in
                        Button(packet.rawValue) { send(packet) }
                            .font(.system(.headline, design: .monospaced)).buttonStyle(.bordered).controlSize(.large)
                            .frame(maxWidth: .infinity).disabled(sending).accessibilityIdentifier("tcp.packet.\(packet.rawValue)")
                    }
                }
                ArcadeFeedback(message: game.message, positive: game.connected && !game.needsRetry)
            }
        }
        .task(id: event) {
            guard event > 0 else { return }
            flight = 0
            if reduceMotion { sending = false; return }
            withAnimation(.easeInOut(duration: 0.4)) { flight = 1 }
            do { try await Task.sleep(for: .milliseconds(450)) } catch { sending = false; return }
            sending = false
        }
        .onDisappear { sending = false }
    }
    private var flightLane: some View {
        GeometryReader { geometry in
            ZStack {
                Capsule().fill(.purple.opacity(0.15)).frame(height: 3)
                if sending && !reduceMotion {
                    Text(flightPacket).font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundStyle(.white).padding(8).background(.purple, in: Capsule())
                        .position(x: 28 + (geometry.size.width - 56) * (flightSender == .client ? flight : 1 - flight), y: 20)
                } else {
                    Image(systemName: game.connected ? "link" : "arrow.left.arrow.right").foregroundStyle(.purple).padding(8).background(RollerStyle.panel)
                }
            }
        }.frame(height: 40).accessibilityHidden(true)
    }
    private func send(_ packet: HandshakeHeroGame.Packet) {
        guard !sending else { return }
        let timing = pulse(at: Date())
        game.send(packet, from: sender, wellTimed: !reduceMotion && (0.4...0.7).contains(timing))
        flightSender = sender; flightPacket = packet.rawValue; sending = !reduceMotion; event += 1
    }
}

#Preview { NavigationStack { HandshakeHeroView() } }
