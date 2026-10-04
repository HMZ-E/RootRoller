import SwiftUI

struct JackpotHubView: View {
    @State private var path: [MiniGame] = []
    @State private var sheet: HubSheet?

    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Give it a spin.").font(.title2.bold())
                            Text("A little momentum. A new adventure.")
                                .font(.subheadline).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        TactileReelView(compact: geometry.size.height < 650) { game in path.append(game) }

                        VStack(alignment: .leading, spacing: 14) {
                            RollerSectionTitle(title: "Your games", detail: "\(MiniGame.allCases.count) games")
                            ForEach(MiniGame.allCases) { game in gameCard(game) }
                        }

                        Button { sheet = .guide } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "lightbulb")
                                    .font(.title2).foregroundStyle(.orange)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("New to Root Roller?").font(.headline).foregroundStyle(.primary)
                                    Text("Get to know the games.").font(.subheadline).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                            }
                            .padding(18)
                            .rollerPanel()
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("hub.guide")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(maxWidth: 640)
                    .frame(maxWidth: .infinity)
                }
            }
            .background(RollerStyle.background)
            .navigationTitle("Root Roller")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") { sheet = .settings }
                        .accessibilityIdentifier("hub.settings")
                }
            }
            .sheet(item: $sheet) { item in
                switch item {
                case .settings: RollerSettingsView()
                case .guide: RollerGuideView(guide: .hub)
                }
            }
            .navigationDestination(for: MiniGame.self) { game in
                switch game {
                case .cliCrisis: TheCLICrisisView()
                case .subnetSlots: SubnetSlotsView()
                case .packetRush: PacketRushView()
                case .cableRescue: CableRescueView()
                case .portPatrol: PortPatrolView()
                case .handshakeHero: HandshakeHeroView()
                case .loopBreaker: LoopBreakerView()
                case .dhcpDash: DHCPDashView()
                }
            }
        }
        .tint(.blue)
    }

    private func gameCard(_ game: MiniGame) -> some View {
        NavigationLink(value: game) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: game.symbol)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(game.tint.gradient, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text(game.title).font(.headline).foregroundStyle(.primary)
                    Text(game.subtitle).font(.subheadline).foregroundStyle(.secondary)
                    Text("\(game.topic) · \(game.format)").font(.caption).foregroundStyle(game.tint)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                    .padding(.top, 17)
            }
            .padding(18)
            .rollerPanel()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("game.\(game.id)")
    }

    private enum HubSheet: String, Identifiable {
        case settings, guide
        var id: String { rawValue }
    }
}

#Preview { JackpotHubView() }
#Preview("Dark") { JackpotHubView().preferredColorScheme(.dark) }
