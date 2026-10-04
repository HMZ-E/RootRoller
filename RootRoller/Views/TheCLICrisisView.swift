import SwiftUI

struct TheCLICrisisView: View {
    private let challenges: [CLIChallenge]
    @State private var taskIndex = 0
    @State private var solved = false
    @State private var score = 0
    private var challenge: CLIChallenge { challenges[taskIndex] }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @AppStorage("hapticsEnabled") private var haptics = true
    @State private var selectedTokens: [CommandToken] = []
    @State private var terminalHistory: [TerminalEntry] = []
    @State private var showGuide = false

    init(challenge: CLIChallenge? = nil) { challenges = challenge.map { [$0] } ?? CLIChallenge.campaign }
    private var command: String { selectedTokens.map(\.text).joined(separator: " ") }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(challenge.title).font(.title2.bold()).id("task")
                        Text(challenge.instructions).font(.subheadline).foregroundStyle(.secondary)
                    }
                    ArcadeStats(progress: "Task \(taskIndex + 1) of \(challenges.count)", score: score)
                    terminal
                    if typeSize.isAccessibilitySize && !(solved && taskIndex == challenges.count - 1) { commandBank }
                    if let last = terminalHistory.last {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: last.correct ? "checkmark.circle.fill" : "info.circle.fill")
                                .foregroundStyle(last.correct ? .green : .blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(last.correct ? (taskIndex == 0 ? "Connection complete" : "Task complete") : "Give it another try").font(.headline)
                                Text(last.correct ? challenge.explanation : "Review the task, then build a new command.")
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        .padding(16).frame(maxWidth: .infinity, alignment: .leading).rollerPanel()
                        .id("result")
                        if solved {
                            if taskIndex == challenges.count - 1 {
                                ArcadeResult(title: "CLI session complete", detail: "\(challenges.count) commands built, entirely by tapping.", score: score) {
                                    taskIndex = 0; solved = false; score = 0; terminalHistory = []; selectedTokens = []
                                }.id("sessionResult")
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .onChange(of: taskIndex) { proxy.scrollTo("task", anchor: .top) }
            .onChange(of: terminalHistory.count) {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { proxy.scrollTo(solved && taskIndex == challenges.count - 1 ? "sessionResult" : "result", anchor: .bottom) }
            }
        }
        .background(RollerStyle.background)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !typeSize.isAccessibilitySize && !(solved && taskIndex == challenges.count - 1) { commandBank }
        }
        .navigationTitle("The CLI Crisis")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("How to Play", systemImage: "questionmark.circle") { showGuide = true }
                    .accessibilityIdentifier("cli.guide")
            }
        }
        .sheet(isPresented: $showGuide) { RollerGuideView(guide: .cli) }
        .sensoryFeedback(trigger: selectedTokens.count) { _, _ in haptics ? .selection : nil }
    }

    private var terminal: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "terminal").foregroundStyle(.white.opacity(0.8))
                Text("Terminal").font(.subheadline.weight(.medium)).foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text("Simulated").font(.caption).foregroundStyle(.white.opacity(0.5))
            }
            .padding(16)
            Divider().overlay(.white.opacity(0.1))
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(terminalHistory) { entry in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("$ \(entry.command)").foregroundStyle(.white.opacity(0.9))
                                Text(entry.output).foregroundStyle(entry.correct ? Color(red: 0.52, green: 0.94, blue: 0.70) : .white.opacity(0.7))
                            }
                        }
                        Text("$ \(command) ▌")
                            .foregroundStyle(Color(red: 0.52, green: 0.94, blue: 0.70))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("Current command: \(command.isEmpty ? "empty" : command)")
                            .accessibilityIdentifier("cli.command")
                            .id("currentCommand")
                    }
                    .font(.system(.subheadline, design: .monospaced))
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 150, maxHeight: 230)
                .onChange(of: selectedTokens) { proxy.scrollTo("currentCommand", anchor: .bottom) }
                .onChange(of: terminalHistory.count) { proxy.scrollTo("currentCommand", anchor: .bottom) }
            }
        }
        .background(Color(red: 0.09, green: 0.10, blue: 0.12), in: RoundedRectangle(cornerRadius: 20))
    }

    private var commandBank: some View {
        RollerBottomBar {
            VStack(alignment: .leading, spacing: 14) {
                if solved {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 16) { nextTaskControls }
                        VStack(alignment: .leading, spacing: 12) { nextTaskControls }
                    }
                } else {
                    HStack {
                        Text("Command bank").font(.headline)
                        Spacer()
                        Text("Tap to add").font(.caption).foregroundStyle(.secondary)
                    }
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 210 : 130), spacing: 10)], spacing: 10) {
                            ForEach(challenge.commandBank) { token in
                                Button { selectedTokens.append(token) } label: {
                                    Text(token.text)
                                        .font(.system(.subheadline, design: .monospaced, weight: .medium))
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .padding(.horizontal, 6)
                                        .foregroundStyle(.primary)
                                        .background(RollerStyle.panel, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Add \(token.text) to command")
                                .disabled(solved)
                            }
                        }
                        .padding(.vertical, 1)
                    }
                    .frame(height: typeSize.isAccessibilitySize ? 180 : 150)
                    HStack(spacing: 10) {
                        Button("Undo", systemImage: "delete.left") {
                            guard !selectedTokens.isEmpty else { return }
                            selectedTokens.removeLast()
                        }
                        .disabled(selectedTokens.isEmpty)
                        Button("Clear", systemImage: "trash") { selectedTokens.removeAll() }
                            .disabled(selectedTokens.isEmpty)
                        Spacer(minLength: 0)
                        Button("Run", systemImage: "play.fill", action: runCommand)
                            .font(.headline)
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                            .disabled(selectedTokens.isEmpty || solved)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .modifier(AdaptiveActionLabels())
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("cli.bank")
    }

    @ViewBuilder private var nextTaskControls: some View {
        Label("Task complete", systemImage: "checkmark.circle.fill").font(.headline).foregroundStyle(.green)
        Button("Next task", systemImage: "arrow.right") {
            taskIndex += 1; solved = false; selectedTokens = []; terminalHistory = []
        }.buttonStyle(.borderedProminent).controlSize(.large).accessibilityIdentifier("cli.next")
    }

    private func runCommand() {
        guard !selectedTokens.isEmpty, !solved else { return }
        let isCorrect = selectedTokens.map(\.text) == challenge.expectedCommand
        terminalHistory.append(TerminalEntry(command: command,
            output: isCorrect ? "Success! \(challenge.expectedCommand.joined(separator: " "))\nSimulation complete." : "Command doesn't match the task. Try another sequence.",
            correct: isCorrect))
        if isCorrect { solved = true; score += 100 }
        selectedTokens.removeAll()
    }

    private struct AdaptiveActionLabels: ViewModifier {
        @Environment(\.dynamicTypeSize) private var typeSize
        @ViewBuilder func body(content: Content) -> some View {
            if typeSize.isAccessibilitySize { content.labelStyle(.iconOnly) }
            else { content.labelStyle(.titleAndIcon) }
        }
    }

    private struct TerminalEntry: Identifiable {
        let id = UUID()
        let command: String
        let output: String
        let correct: Bool
    }
}

#Preview { NavigationStack { TheCLICrisisView() } }
#Preview("Dark") { NavigationStack { TheCLICrisisView() }.preferredColorScheme(.dark) }
