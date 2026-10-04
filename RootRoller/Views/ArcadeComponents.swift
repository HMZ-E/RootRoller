import SwiftUI

struct ArcadeGameShell<Content: View>: View {
    let game: MiniGame
    var feedback = 0
    var showIntro = true
    @ViewBuilder let content: Content
    @State private var showGuide = false
    @AppStorage("hapticsEnabled") private var haptics = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if showIntro {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(game.topic, systemImage: game.symbol).font(.caption.weight(.semibold)).foregroundStyle(game.tint)
                        Text(game.instructions).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                }
                content
            }
            .padding(20).frame(maxWidth: 640).frame(maxWidth: .infinity)
        }
        .background(RollerStyle.background)
        .navigationTitle(game.title).navigationBarTitleDisplayMode(.inline)
        .tint(game.tint)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("How to Play", systemImage: "questionmark.circle") { showGuide = true }
            }
        }
        .sheet(isPresented: $showGuide) { ArcadeGuideView(game: game) }
        .sensoryFeedback(trigger: feedback) { _, _ in haptics ? .selection : nil }
    }
}

struct ArcadeStats: View {
    let progress: String
    let score: Int
    var detail: String = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                Text(progress).fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading)
                Text("\(score) R").bold().fixedSize()
            }
            if !detail.isEmpty { Text(detail).font(.caption).fixedSize(horizontal: false, vertical: true) }
        }
        .font(.subheadline).foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }
}

struct ArcadeFeedback: View {
    let message: String
    var positive = false
    var body: some View {
        Label {
            Text(message).font(.subheadline).fixedSize(horizontal: false, vertical: true)
        } icon: { Image(systemName: positive ? "checkmark.circle.fill" : "info.circle.fill").foregroundStyle(positive ? .green : .secondary) }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).rollerPanel(radius: 18)
        .accessibilityIdentifier("arcade.feedback")
    }
}

struct ArcadeResult: View {
    let title: String
    let detail: String
    let score: Int
    let restart: () -> Void
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "flag.checkered.circle.fill").font(.system(size: 46)).foregroundStyle(.green).accessibilityHidden(true)
            Text(title).font(.title2.bold()).multilineTextAlignment(.center).accessibilityIdentifier("arcade.result")
            Text(detail).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Text("\(score) R").font(.title.bold())
            Button("Play again", systemImage: "arrow.clockwise", action: restart)
                .buttonStyle(.borderedProminent).controlSize(.large).accessibilityIdentifier("arcade.restart")
        }
        .padding(24).frame(maxWidth: .infinity).rollerPanel()
    }
}

private struct ArcadeGuideView: View {
    let game: MiniGame
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appAppearance") private var appearance = AppAppearance.system.rawValue
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image(systemName: game.symbol).font(.system(size: 36)).foregroundStyle(game.tint)
                    Text(game.title).font(.largeTitle.bold())
                    ForEach(Array(game.tips.enumerated()), id: \.offset) { index, tip in
                        HStack(alignment: .top, spacing: 14) {
                            Text("\(index + 1)").font(.headline).foregroundStyle(game.tint).frame(width: 30, height: 30).background(game.tint.opacity(0.12), in: Circle())
                            Text(tip).font(.body).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }.padding(24).frame(maxWidth: 640).frame(maxWidth: .infinity)
            }
            .background(RollerStyle.background).navigationTitle("How to Play").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .preferredColorScheme((AppAppearance(rawValue: appearance) ?? .system).colorScheme)
    }
}
