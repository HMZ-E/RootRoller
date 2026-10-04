import SwiftUI

struct DHCPDashView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var game = DHCPDashGame()
    var body: some View {
        ArcadeGameShell(game: .dhcpDash, feedback: game.score) {
            ArcadeStats(progress: "\(game.client) of 6 devices served", score: game.score, detail: "3-address pool")
            if game.finished {
                ArcadeResult(title: "Everyone online", detail: "Six devices served without an address conflict.", score: game.score) { game = DHCPDashGame() }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: ["laptopcomputer", "iphone", "printer.fill", "gamecontroller.fill", "video.fill", "ipad"][game.client])
                        .font(.system(size: 40)).foregroundStyle(.cyan).accessibilityHidden(true)
                    Text(game.device).font(.title2.bold())
                    Text(game.prompt).font(.subheadline).multilineTextAlignment(.center).foregroundStyle(.secondary).accessibilityIdentifier("dhcp.prompt")
                }.padding(20).frame(maxWidth: .infinity).rollerPanel()
                LazyVGrid(columns: typeSize.isAccessibilitySize ? [GridItem(.flexible())] : [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(DHCPDashGame.Step.allCases) { step in
                        Button { game.send(step) } label: {
                            Label(step.title, systemImage: step.rawValue < game.step.rawValue ? "checkmark.circle.fill" : "\(step.rawValue + 1).circle")
                                .font(.subheadline.weight(.semibold)).padding(12).frame(maxWidth: .infinity, minHeight: 48)
                                .foregroundStyle(.primary)
                                .background(step == game.step ? Color.cyan.opacity(0.12) : RollerStyle.panel, in: RoundedRectangle(cornerRadius: 14))
                        }.buttonStyle(.plain).accessibilityIdentifier("dhcp.step.\(step.rawValue)")
                    }
                }
                RollerSectionTitle(title: "Address pool", detail: "Arrival \(game.client + 1)")
                VStack(spacing: 10) {
                    ForEach(DHCPDashGame.pool, id: \.self) { address in
                        let expired = game.expired(address), lease = game.leases[address]
                        Button { game.select(address) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: expired ? "arrow.clockwise.circle.fill" : lease == nil ? "circle.dotted" : "lock.fill").foregroundStyle(expired ? .orange : lease == nil ? .cyan : .secondary)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(address).font(.system(.headline, design: .monospaced))
                                    Text(expired ? "Expired · tap to reclaim" : lease.map { "\($0.device) · expires at arrival \($0.expiresAt + 1)" } ?? (game.selectedAddress == address ? "Selected for offer" : "Free · tap to offer"))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 0)
                                if game.selectedAddress == address { Image(systemName: "checkmark.circle.fill").foregroundStyle(.cyan) }
                            }.padding(14).frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                                .background(RollerStyle.panel, in: RoundedRectangle(cornerRadius: 16))
                                .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(game.selectedAddress == address ? Color.cyan : .clear, lineWidth: 2) }
                        }.buttonStyle(.plain).accessibilityIdentifier("dhcp.address.\(address)")
                    }
                }
                ArcadeFeedback(message: game.message)
            }
        }
    }
}

#Preview { NavigationStack { DHCPDashView() } }
