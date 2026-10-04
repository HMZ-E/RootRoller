import SwiftUI

struct SubnetSlotsView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @AppStorage("hapticsEnabled") private var haptics = true
    @State private var game = SubnetGame()
    @State private var spinning = false
    @State private var showGuide = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    progress.id("top")
                    subnet
                    if game.finished { summary.id("summary") }
                    challenge
                    answerBank
                    if game.answered { feedback.id("feedback") }
                    if typeSize.isAccessibilitySize { controlContent.padding(18).rollerPanel() }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .onChange(of: game.selectedAnswer) {
                guard game.answered else { return }
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                    proxy.scrollTo(game.finished ? "summary" : "feedback", anchor: game.finished ? .top : .bottom)
                }
            }
            .onChange(of: game.challenge.id) { proxy.scrollTo("top", anchor: .top) }
        }
        .background(RollerStyle.background)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !typeSize.isAccessibilitySize { controls }
        }
        .navigationTitle("Subnet Slots")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("How to Play", systemImage: "questionmark.circle") { showGuide = true }
                    .accessibilityIdentifier("subnet.guide")
            }
        }
        .sheet(isPresented: $showGuide) { RollerGuideView(guide: .subnet) }
        .sensoryFeedback(trigger: game.selectedAnswer) { _, answer in
            guard haptics && answer != nil else { return nil }
            return game.correct ? .success : .error
        }
        .task(id: spinning) {
            guard spinning else { return }
            do { try await Task.sleep(for: .milliseconds(320)) } catch { return }
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { spinning = false }
        }
    }

    private var progress: some View {
        VStack(spacing: 10) {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    roundLabel
                    streakLabel
                }.frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack { roundLabel; Spacer(); streakLabel }
            }
            ProgressView(value: Double(game.round - (game.answered ? 0 : 1)), total: Double(SubnetGame.totalRounds))
                .tint(.blue)
                .accessibilityLabel("Session progress")
        }
    }

    private var roundLabel: some View {
        Text("Round \(game.round) of \(SubnetGame.totalRounds)").font(.subheadline.weight(.medium))
    }

    private var streakLabel: some View {
        Label("\(game.streak) streak", systemImage: "flame.fill")
            .font(.subheadline)
            .foregroundStyle(game.streak > 0 ? .orange : .secondary)
    }

    private var subnet: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Your subnet", systemImage: "network")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("IPv4").font(.caption.weight(.medium)).foregroundStyle(.tertiary)
            }
            Text(displayCIDR)
                .font(.system(.title2, design: .monospaced, weight: .semibold))
                .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
                .minimumScaleFactor(typeSize.isAccessibilitySize ? 1 : 0.75)
                .accessibilityIdentifier("subnet.cidr")
                .accessibilityLabel(game.challenge.cidr)
                .contentTransition(.numericText())

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { subnetMetrics }
                VStack(spacing: 10) { subnetMetrics }
            }
            .blur(radius: spinning && !reduceMotion ? 2 : 0)
            .accessibilityElement(children: .combine)

            VStack(spacing: 10) {
                parameter("Subnet mask", value: SubnetChallenge.address(game.challenge.mask))
                Divider()
                parameter("First host", value: SubnetChallenge.address(game.challenge.firstHost))
            }
        }
        .padding(16)
        .rollerPanel(radius: 24)
    }

    private var displayCIDR: String {
        guard typeSize.isAccessibilitySize else { return game.challenge.cidr }
        let octets = SubnetChallenge.address(game.challenge.network).split(separator: ".")
        return octets.prefix(2).joined(separator: ".") + ".\n" + octets.suffix(2).joined(separator: ".") + "/\(game.challenge.prefix)"
    }

    @ViewBuilder private var subnetMetrics: some View {
        metric("Prefix", value: "/\(game.challenge.prefix)", accent: .blue)
        metric("Usable hosts", value: "\(game.challenge.usableHosts)", accent: .teal)
        metric("Addresses", value: "\(game.challenge.blockSize)", accent: .indigo)
    }

    private func metric(_ label: String, value: String, accent: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(accent)
                .contentTransition(.numericText())
            Text(label).font(.caption).foregroundStyle(.secondary).fixedSize()
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
    }

    private func parameter(_ label: String, value: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                Text(label).font(.footnote).foregroundStyle(.secondary).fixedSize()
                Spacer(minLength: 0)
                Text(value).font(.system(.footnote, design: .monospaced)).fixedSize()
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(label).font(.footnote).foregroundStyle(.secondary)
                Text(value).font(.system(.footnote, design: .monospaced))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    private var challenge: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Find the broadcast address")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                Text("+\(game.reward) R").font(.caption.weight(.semibold)).foregroundStyle(.blue).fixedSize()
            }
            Text("Choose the last address in this subnet.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private var answerBank: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 12) {
            ForEach(Array(game.challenge.answers.enumerated()), id: \.element) { index, answer in
                let isAnswer = game.answered && answer == game.challenge.broadcast
                let isWrong = game.selectedAnswer == answer && !game.correct
                let accent: Color = isAnswer ? .green : isWrong ? .red : .blue
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { game.answer(answer) }
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(String(UnicodeScalar(65 + index)!))
                                .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: isAnswer ? "checkmark.circle.fill" : isWrong ? "xmark.circle.fill" : "circle")
                                .foregroundStyle(isAnswer || isWrong ? accent : Color(uiColor: .tertiaryLabel))
                        }
                        Text(".\(answer & 255)")
                            .font(.system(.title2, design: .monospaced, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text(SubnetChallenge.address(answer))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1).minimumScaleFactor(0.75)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RollerStyle.panel, in: RoundedRectangle(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isAnswer || isWrong ? accent.opacity(0.07) : .clear)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(isAnswer || isWrong ? accent.opacity(0.6) : .clear, lineWidth: 1.5)
                    }
                }
                .buttonStyle(.plain)
                .disabled(game.answered || spinning)
                .accessibilityIdentifier("answer.\(SubnetChallenge.address(answer))")
                .accessibilityLabel("Answer \(String(UnicodeScalar(65 + index)!)): \(SubnetChallenge.address(answer))\(isAnswer ? ", correct" : isWrong ? ", incorrect" : "")")
            }
        }
    }

    private var feedback: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: game.correct ? "checkmark.circle.fill" : "info.circle.fill")
                    .foregroundStyle(game.correct ? .green : .blue)
                Text(game.correct ? "Correct. +\(game.reward) R" : "Not quite. Let's work it out.")
                    .font(.headline)
            }
            Text("A /\(game.challenge.prefix) has \(game.challenge.blockSize) addresses. Starting at .\(game.challenge.network & 255), count \(game.challenge.blockSize - 1) more to find the broadcast: .\(game.challenge.broadcast & 255).")
                .font(.subheadline).foregroundStyle(.secondary)
            Divider()
            parameter("Broadcast", value: SubnetChallenge.address(game.challenge.broadcast))
            parameter("Last usable host", value: SubnetChallenge.address(game.challenge.lastHost))
        }
        .padding(18)
        .rollerPanel()
        .accessibilityElement(children: .combine)
    }

    private var summary: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().stroke(.blue.opacity(0.10), lineWidth: 6)
                Circle().trim(from: 0, to: CGFloat(game.correctCount) / 5)
                    .stroke(.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(game.correctCount)/5").font(.title2.weight(.semibold))
            }
            .frame(width: 76, height: 76)
            .accessibilityHidden(true)
            VStack(spacing: 6) {
                Text("Session complete").font(.subheadline).foregroundStyle(.secondary)
                Text("\(game.correctCount) of 5 subnets solved").font(.title2.bold())
                Text("You earned \(game.earned) R this session.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .rollerPanel(radius: 24)
    }

    private var controls: some View {
        RollerBottomBar { controlContent }
    }

    private var balance: some View {
        Label("\(game.balance.formatted()) R", systemImage: "circle.circle")
            .font(.subheadline.weight(.medium))
            .accessibilityLabel("Session balance: \(game.balance) Roller points")
    }

    private var prefixLock: some View {
        Button { game.toggleLock() } label: {
            Label("\(game.lockedPrefix == nil ? "Hold" : "Holding") /\(game.lockedPrefix ?? game.challenge.prefix)",
                  systemImage: game.lockedPrefix == nil ? "lock.open" : "lock.fill")
                .font(.subheadline)
                .padding(.vertical, 10)
        }
        .accessibilityIdentifier("subnet.lock")
        .accessibilityLabel("\(game.lockedPrefix == nil ? "Lock" : "Unlock") CIDR prefix for the next spin")
        .accessibilityHint("A correct answer after a locked spin earns 25 bonus points.")
        .disabled(spinning)
    }

    private var controlContent: some View {
        VStack(spacing: 10) {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    balance
                    if !game.answered { prefixLock }
                }.frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack { balance; Spacer(); if !game.answered { prefixLock } }
            }
            Button {
                if game.finished {
                    game = SubnetGame()
                } else {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.16)) {
                        if game.spin() { spinning = true }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if !typeSize.isAccessibilitySize {
                        Image(systemName: game.finished ? "arrow.counterclockwise" : game.answered ? "arrow.right" : "arrow.triangle.2.circlepath")
                    }
                    Text(game.finished ? "Play a new session" : game.answered ? "Next round" : typeSize.isAccessibilitySize ? "Spin" : "Spin a new subnet")
                    if !game.finished { Text("· 15 R").font(.subheadline) }
                }
                .padding(.horizontal, 12)
            }
            .accessibilityIdentifier("subnet.spin")
            .buttonStyle(RollerButtonStyle(prominent: true))
            .disabled(spinning || (!game.finished && !game.canSpin))
            if !game.canSpin && !game.finished {
                Button("Start a new session") { game = SubnetGame() }
                    .font(.subheadline).frame(minHeight: 44)
                Text("Not enough points to spin again.").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

#Preview { NavigationStack { SubnetSlotsView() } }
#Preview("Dark") { NavigationStack { SubnetSlotsView() }.preferredColorScheme(.dark) }
