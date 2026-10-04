import SwiftUI

/// Semantic colors follow the device's appearance, contrast, and accessibility settings.
enum RollerStyle {
    static let background = Color(uiColor: .systemGroupedBackground)
    static let panel = Color(uiColor: .secondarySystemGroupedBackground)
    static let elevated = Color(uiColor: .tertiarySystemGroupedBackground)
    static let blue = Color.blue
    static let mint = Color.green
    static let muted = Color.secondary
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

extension View {
    func rollerPanel(radius: CGFloat = 22) -> some View {
        background(RollerStyle.panel, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

struct RollerButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var prominent = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(prominent ? Color.white : RollerStyle.blue)
            .background(prominent ? RollerStyle.blue : RollerStyle.blue.opacity(0.10),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.4)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
    }
}

struct RollerSectionTitle: View {
    let title: String
    var detail: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.title3.weight(.bold))
            Spacer()
            if let detail { Text(detail).font(.subheadline).foregroundStyle(.secondary) }
        }
        .accessibilityAddTraits(.isHeader)
    }
}

struct RollerBottomBar<Content: View>: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
            .background {
                if reduceTransparency {
                    Color(uiColor: .systemBackground)
                } else {
                    Rectangle().fill(.bar)
                }
            }
            .overlay(alignment: .top) { Divider() }
    }
}

struct RollerSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appAppearance") private var appearance = AppAppearance.system.rawValue
    @AppStorage("hapticsEnabled") private var haptics = true
    @AppStorage("reelSoundsEnabled") private var reelSounds = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(AppAppearance.allCases) { option in
                            Text(option.title).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("settings.appearance")
                }
                Section {
                    Toggle("Haptic feedback", isOn: $haptics)
                        .tint(.green)
                        .accessibilityIdentifier("settings.haptics")
                    Toggle("Reel click sounds", isOn: $reelSounds)
                        .tint(.green)
                        .accessibilityIdentifier("settings.reelSounds")
                } header: {
                    Text("Play")
                } footer: {
                    Text("Feel the reel click through each slot and settle into place. Reel sounds start muted and respect the silent switch.")
                }
                Section("About") {
                    Label("Root Roller", systemImage: "network")
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    Text("Small games for learning networking, one challenge at a time.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .preferredColorScheme((AppAppearance(rawValue: appearance) ?? .system).colorScheme)
    }
}

enum RollerGuide: String, Identifiable {
    case hub, subnet, cli
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .hub: "dice.fill"
        case .subnet: "square.split.2x2.fill"
        case .cli: "terminal.fill"
        }
    }
    var title: String {
        switch self {
        case .hub: "A little practice.\nA stronger network."
        case .subnet: "Every address\nhas its place."
        case .cli: "The command line.\nWithout the keyboard."
        }
    }
    var steps: [(String, String)] {
        switch self {
        case .hub:
            [("Choose a game", "Explore eight games: steer packets, repair cables, patrol a firewall, build commands, and keep networks running."),
             ("Give it a spin", "Drag the drum slowly or flick it to spin. Use Roll to choose another game, then tap Play game to begin."),
             ("Learn as you play", "Each game gives you feedback to help you understand the answer.")]
        case .subnet:
            [("Read your subnet", "The network, prefix, and host count describe a group of IPv4 addresses."),
             ("Find the broadcast", "Choose the last address in that group. A correct answer earns 80 R."),
             ("Spin or hold", "A new subnet costs 15 R. Hold a prefix before spinning to keep it. Solve that locked spin for 25 extra R."),
             ("Finish five rounds", "Review each answer, then move to the next round. Points reset when you start a new session.")]
        case .cli:
            [("Read the task", "Find out which command you need to build."),
             ("Tap the pieces", "Add tokens from the command bank in order. Undo removes the last token; Clear starts over."),
             ("Run your command", "Check your answer and review the terminal feedback. All commands are simulated."),
             ("Finish the session", "Each correct command earns 100 R once. Tap Next task to keep going, then replay the five-task session.")]
        }
    }
}

struct RollerGuideView: View {
    @AppStorage("appAppearance") private var appearance = AppAppearance.system.rawValue
    @Environment(\.dismiss) private var dismiss
    let guide: RollerGuide

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Image(systemName: guide.symbol)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(.blue)
                        .frame(width: 76, height: 76)
                        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 22))
                        .accessibilityHidden(true)
                    Text(guide.title).font(.largeTitle.bold())
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 14) {
                                Text("\(index + 1)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.blue)
                                    .frame(width: 28, height: 28)
                                    .background(.blue.opacity(0.1), in: Circle())
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(step.0).font(.headline)
                                    Text(step.1).font(.subheadline).foregroundStyle(.secondary)
                                }
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: 600, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("How to Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .preferredColorScheme((AppAppearance(rawValue: appearance) ?? .system).colorScheme)
    }
}
