import SwiftUI

struct LoopBreakerView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var game = LoopBreakerGame()
    private let nodes = [CGPoint(x: 0.5, y: 0.12), CGPoint(x: 0.88, y: 0.38), CGPoint(x: 0.75, y: 0.82), CGPoint(x: 0.25, y: 0.82), CGPoint(x: 0.12, y: 0.38)]
    var body: some View {
        ArcadeGameShell(game: .loopBreaker, feedback: game.moves) {
            ArcadeStats(progress: game.stage == 0 ? "Stop the broadcast storm" : "Restore the backup path", score: game.score, detail: "\(game.moves) moves")
            if game.finished {
                ArcadeResult(title: "Storm stopped", detail: "Five switches connected. A safe backup restored.", score: game.score) { game = LoopBreakerGame() }
            } else {
                network
                if typeSize.isAccessibilitySize {
                    VStack(spacing: 10) {
                        ForEach(LoopBreakerGame.links) { link in
                            Button { game.toggle(link.id) } label: {
                                HStack { Text("Link \(link.title)"); Spacer(); Text(link.id == game.failedLink ? "Failed" : game.active.contains(link.id) ? "Live" : "Standby") }
                            }.buttonStyle(.bordered).disabled(link.id == game.failedLink).accessibilityIdentifier("loop.link.\(link.id)")
                        }
                    }
                }
                Label(game.safe ? "All connected · no loops" : game.connected ? "All connected · loop detected" : "Disconnected · restore a path", systemImage: game.safe ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.headline).foregroundStyle(game.safe ? .green : .orange).accessibilityIdentifier("loop.status")
                Button(game.stage == 0 ? "Test traffic" : "Test backup", systemImage: "paperplane.fill") { game.confirm() }
                    .buttonStyle(.borderedProminent).controlSize(.large).disabled(!game.safe).accessibilityIdentifier("loop.test")
                Text("Solid = live · Dashed = standby · Red = failed").font(.caption).foregroundStyle(.secondary)
                ArcadeFeedback(message: game.message, positive: game.safe)
            }
        }
    }
    private var network: some View {
        GeometryReader { geometry in
            ZStack {
                Canvas { context, size in
                    for link in LoopBreakerGame.links {
                        var path = Path(); path.move(to: point(link.a, size)); path.addLine(to: point(link.b, size))
                        let failed = link.id == game.failedLink, active = game.active.contains(link.id)
                        context.stroke(path, with: .color(failed ? .red : active ? .indigo : .secondary.opacity(0.3)), style: StrokeStyle(lineWidth: active ? 4 : 2, lineCap: .round, dash: active ? [] : [5, 6]))
                    }
                }
                ForEach(0..<5, id: \.self) { index in
                    VStack(spacing: 3) {
                        Image(systemName: "switch.2").font(.system(size: 18))
                        Text(String(UnicodeScalar(65 + index)!)).font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.primary).frame(width: 46, height: 50).background(RollerStyle.panel, in: RoundedRectangle(cornerRadius: 13))
                    .overlay { RoundedRectangle(cornerRadius: 13).strokeBorder(.pink.opacity(0.3)) }
                    .position(point(index, geometry.size)).accessibilityHidden(true)
                }
                ForEach(LoopBreakerGame.links) { link in
                    let a = point(link.a, geometry.size), b = point(link.b, geometry.size)
                    Button { game.toggle(link.id) } label: {
                        Text(link.title).font(.system(size: 10, weight: .semibold)).foregroundStyle(link.id == game.failedLink ? .red : .primary)
                            .padding(6).background(RollerStyle.panel, in: Capsule())
                            .overlay { Capsule().strokeBorder(link.id == game.failedLink ? Color.red.opacity(0.5) : .pink.opacity(0.3)) }
                            .frame(width: 48, height: 44).contentShape(Rectangle())
                    }.buttonStyle(.plain).disabled(link.id == game.failedLink)
                        .position(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
                        .accessibilityLabel("Link \(link.title)")
                        .accessibilityValue(link.id == game.failedLink ? "Failed" : game.active.contains(link.id) ? "Live" : "Standby")
                        .accessibilityHint("Tap to toggle the link.")
                        .accessibilityIdentifier("loop.link.\(link.id)")
                }
            }
        }
        .frame(height: 290).rollerPanel().accessibilityHidden(typeSize.isAccessibilitySize)
    }
    private func point(_ index: Int, _ size: CGSize) -> CGPoint { CGPoint(x: nodes[index].x * size.width, y: nodes[index].y * size.height) }
}

#Preview { NavigationStack { LoopBreakerView() } }
