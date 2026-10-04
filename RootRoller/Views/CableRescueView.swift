import SwiftUI

struct CableRescueView: View {
    @State private var game = CableRescueGame()
    @State private var dropTarget: Int?
    var body: some View {
        ArcadeGameShell(game: .cableRescue, feedback: game.score) {
            ArcadeStats(progress: "Outage \(game.round + 1) of \(game.faults.count)", score: game.score, detail: "\(game.probesLeft) probes · \(game.sparesLeft) spares")
            if game.finished {
                ArcadeResult(title: "Rescue complete", detail: "\(game.rescued) of \(game.faults.count) networks restored", score: game.score) { game = CableRescueGame() }
            } else {
                VStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { device in
                        deviceRow(device)
                        if device < 3 { cable(device) }
                    }
                }.padding(18).rollerPanel()
                if !game.roundEnded {
                    Label("Spare cable · drag to a link", systemImage: "cable.connector")
                        .font(.headline).foregroundStyle(.orange).padding(16).frame(maxWidth: .infinity)
                        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                        .draggable("root-roller-spare-cable").accessibilityIdentifier("cable.spare").accessibilityHint("You can also tap a link to replace its cable.")
                } else {
                    Button("Next outage", systemImage: "arrow.right") { game.next() }
                        .buttonStyle(.borderedProminent).controlSize(.large).accessibilityIdentifier("cable.next")
                }
                ArcadeFeedback(message: game.message, positive: game.repaired)
            }
        }
    }
    private func deviceRow(_ device: Int) -> some View {
        let observed = game.repaired ? true : game.observations[device]
        return HStack(spacing: 12) {
            Image(systemName: ["laptopcomputer", "switch.2", "network", "server.rack"][device])
                .font(.title2).foregroundStyle(observed == true ? Color.green : observed == false ? .orange : .secondary)
                .frame(width: 42, height: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(CableRescueGame.devices[device]).font(.headline)
                Text(observed == true ? "Reachable" : observed == false ? "No reply" : "Not tested").font(.caption).foregroundStyle(.secondary).accessibilityIdentifier("cable.status.\(device)")
            }
            Spacer()
            if device > 0 {
                Button("Probe") { game.probe(device) }
                    .font(.subheadline.weight(.semibold)).buttonStyle(.bordered).controlSize(.regular)
                    .disabled(game.roundEnded || game.probesLeft == 0 || game.observations[device] != nil)
                    .accessibilityLabel("Probe \(CableRescueGame.devices[device])").accessibilityIdentifier("cable.probe.\(device)")
            }
        }.padding(.vertical, 4)
    }
    private func cable(_ link: Int) -> some View {
        Button { game.replace(link) } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 2).fill(game.repaired ? .green : game.ruledOut.contains(link) ? .blue : .secondary.opacity(0.35)).frame(width: 4, height: 32).frame(width: 42)
                Label(game.repaired ? "Link restored" : game.ruledOut.contains(link) ? "Healthy cable" : "Replace cable", systemImage: "cable.connector")
                    .font(.caption.weight(.semibold)).foregroundStyle(game.repaired ? .green : .orange)
                Spacer()
            }.frame(minHeight: 44).contentShape(Rectangle())
                .background(dropTarget == link ? Color.orange.opacity(0.14) : .clear, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain).disabled(game.roundEnded || game.ruledOut.contains(link))
        .accessibilityLabel("Replace \(CableRescueGame.devices[link]) to \(CableRescueGame.devices[link + 1]) cable")
        .accessibilityIdentifier("cable.link.\(link)")
        .dropDestination(for: String.self) { items, _ in
            guard items.contains("root-roller-spare-cable"), !game.roundEnded else { return false }
            game.replace(link); return true
        } isTargeted: { targeted in
            if targeted { dropTarget = link }
            else if dropTarget == link { dropTarget = nil }
        }
    }
}

#Preview { NavigationStack { CableRescueView() } }
