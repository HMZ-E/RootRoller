import SwiftUI

struct TactileReelView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hapticsEnabled") private var haptics = true
    @AppStorage("reelSoundsEnabled") private var sounds = false
    @StateObject private var motion = ReelMotion()
    @State private var dragging = false
    var compact = false
    let onPlay: (MiniGame) -> Void

    private var palette: ReelPalette { ReelPalette(dark: colorScheme == .dark) }

    var body: some View {
        VStack(spacing: compact ? 12 : 16) {
            header
            drum
            Label("Drag slowly. Flick to spin.", systemImage: "arrow.up.and.down")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            selection
            if typeSize.isAccessibilitySize {
                VStack(spacing: 14) { controls }
            } else {
                HStack(spacing: 12) { controls }
            }
        }
        .padding(16)
        .padding(.bottom, 6)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(LinearGradient(colors: [palette.shellTop, palette.shellBottom], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay { RoundedRectangle(cornerRadius: 30).strokeBorder(palette.glint, lineWidth: 1) }
                .shadow(color: palette.buttonBase, radius: 0, y: 3)
                .shadow(color: palette.shadow, radius: 12, y: 14)
        }
        .onAppear { configure() }
        .onDisappear { motion.stop(); dragging = false }
        .onChange(of: sounds) { configure() }
        .onChange(of: compact) { motion.stop(); dragging = false; configure() }
        .onChange(of: haptics) { configure() }
        .onChange(of: reduceMotion) { motion.stop(); dragging = false; configure() }
        .onChange(of: scenePhase) {
            if scenePhase != .active { motion.stop(); dragging = false }
        }
    }

    private var header: some View {
        HStack {
            Label("THE ROLLER", systemImage: "arrow.clockwise")
                .font(.caption.weight(.semibold))
                .tracking(1.1)
                .foregroundStyle(.secondary)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .accessibilityHidden(true)
            Spacer()
            Button { sounds.toggle() } label: {
                Image(systemName: sounds ? "speaker.wave.2" : "speaker.slash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(TactileSoundStyle())
            .accessibilityLabel(sounds ? "Mute reel sounds" : "Enable reel sounds")
            .accessibilityValue(sounds ? "On" : "Off")
            .accessibilityIdentifier("hub.reelSound")
        }
        .padding(.leading, 6)
    }

    private var drum: some View {
        GeometryReader { geometry in
            let center = geometry.size.height / 2
            let radius = center - (compact ? 7 : 13)
            let base = Int(motion.position.rounded())
            ZStack {
                LinearGradient(colors: [palette.drumTop, palette.drumMiddle, palette.drumBottom], startPoint: .top, endPoint: .bottom)
                ForEach(-3...3, id: \.self) { offset in
                    let slot = base + offset
                    let angle = (Double(slot) - motion.position) * 34
                    let radians = angle * .pi / 180
                    let cosine = cos(radians)
                    ReelFace(game: MiniGame.at(slot), angle: angle, palette: palette)
                        .frame(width: max(0, geometry.size.width - 44), height: compact ? 60 : 82)
                        .rotation3DEffect(.degrees(-angle), axis: (x: 1, y: 0, z: 0), perspective: 0.35)
                        .scaleEffect(x: 1 - min(0.07, abs(angle) / 1500), y: 1)
                        .brightness((cosine - 1) * 0.28)
                        .opacity(abs(angle) > 89 ? 0 : 1)
                        .position(x: geometry.size.width / 2, y: center + sin(radians) * radius)
                        .zIndex(cosine * 10)
                }
                edgeShade(top: true)
                edgeShade(top: false)
                HStack {
                    ReelGrip(position: motion.position, palette: palette)
                    Spacer()
                    ReelGrip(position: motion.position, palette: palette)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
                .zIndex(20)
                lens
                    .frame(width: max(0, geometry.size.width - 14), height: compact ? 76 : 96)
                    .position(x: geometry.size.width / 2, y: center)
                    .zIndex(21)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(palette.occlusion.opacity(0.3), lineWidth: 1)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: compact ? 210 : 270)
        .contentShape(Rectangle())
        .highPriorityGesture(dragGesture)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Game roller")
        .accessibilityValue(motion.isMoving ? "Rolling" : motion.selectedGame.title)
        .accessibilityHint("Adjust up or down to choose a game, or use the Roll button.")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: motion.adjust(by: 1)
            case .decrement: motion.adjust(by: -1)
            @unknown default: break
            }
        }
        .accessibilityIdentifier("hub.reel")
    }

    private func edgeShade(top: Bool) -> some View {
        VStack(spacing: 0) {
            if !top { Spacer(minLength: 0) }
            LinearGradient(colors: top ? [palette.occlusion, .clear] : [.clear, palette.occlusion], startPoint: .top, endPoint: .bottom)
                .frame(height: 48)
            if top { Spacer(minLength: 0) }
        }
        .allowsHitTesting(false)
        .zIndex(19)
    }

    private var lens: some View {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
            .fill(palette.lensTint)
            .overlay {
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(contrast == .increased ? Color.blue : palette.lensBorder, lineWidth: contrast == .increased ? 2 : 1.5)
            }
            .overlay {
                HStack {
                    Capsule().fill(.blue).frame(width: 4, height: 28)
                    Spacer()
                    Capsule().fill(.blue).frame(width: 4, height: 28)
                }
                .padding(.horizontal, 4)
            }
            .shadow(color: palette.shadow, radius: 3, y: 3)
            .allowsHitTesting(false)
    }

    private var selection: some View {
        VStack(spacing: 4) {
            Text(motion.selectedGame.title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("hub.selection")
            Text(motion.isMoving ? "Rolling…" : "\(motion.selectedGame.topic) · \(motion.selectedGame.format)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("hub.reelStatus")
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var controls: some View {
        Button { motion.roll() } label: {
            Label(motion.hasRolled ? "Roll again" : "Roll", systemImage: "arrow.clockwise")
        }
        .buttonStyle(TactileControlStyle(prominent: false))
        .disabled(motion.isMoving)
        .accessibilityIdentifier("hub.roll")
        .accessibilityHint("Spin the drum to choose another game.")

        Button { onPlay(motion.selectedGame) } label: {
            Label("Play game", systemImage: "play.fill")
        }
        .buttonStyle(TactileControlStyle(prominent: true))
        .disabled(motion.isMoving)
        .accessibilityIdentifier("hub.quickPlay")
        .accessibilityHint("Open \(motion.selectedGame.title).")
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                if !dragging { dragging = true; motion.beginDrag() }
                motion.drag(translation: value.translation.height)
            }
            .onEnded { value in
                dragging = false
                guard scenePhase == .active else { motion.stop(); return }
                motion.endDrag(translation: value.translation.height)
            }
    }

    private func configure() {
        motion.configure(haptics: haptics, sounds: sounds, reduceMotion: reduceMotion, pointsPerSlot: compact ? 58 : 76)
    }
}

private struct ReelFace: View {
    let game: MiniGame
    let angle: Double
    let palette: ReelPalette

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: game.symbol)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(game.tint)
                .frame(width: 40, height: 40)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [palette.faceTop, game.tint.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(palette.glint, lineWidth: 1) }
                        .shadow(color: palette.shadow, radius: 2, y: 2)
                }
            VStack(alignment: .leading, spacing: 4) {
                Text(game.title)
                    .font(.system(size: 17, weight: .semibold))
                    .lineLimit(1).minimumScaleFactor(0.75)
                Text("\(game.topic) · \(game.format)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            .opacity(max(0, min(1, (68 - abs(angle)) / 12)))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 12)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(LinearGradient(colors: [palette.faceTop, palette.faceBottom], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(palette.glint, lineWidth: 1) }
                .shadow(color: palette.shadow, radius: 3, y: 3)
        }
        .accessibilityHidden(true)
    }
}

private struct ReelGrip: View {
    let position: Double
    let palette: ReelPalette

    var body: some View {
        Canvas { context, size in
            let shift = (position * 11).truncatingRemainder(dividingBy: 6)
            for y in stride(from: -6.0, through: Double(size.height) + 6, by: 6) {
                context.fill(Path(CGRect(x: 0, y: y + shift, width: size.width, height: 3)), with: .color(palette.gripDark))
                context.fill(Path(CGRect(x: 0, y: y + shift + 3, width: size.width, height: 2)), with: .color(palette.gripLight))
            }
        }
        .frame(width: 8)
        .clipShape(Capsule())
        .opacity(0.8)
        .allowsHitTesting(false)
    }
}

private struct TactileControlStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let prominent: Bool

    func makeBody(configuration: Configuration) -> some View {
        let colors = ReelPalette(dark: scheme == .dark)
        let pressed = configuration.isPressed && enabled
        configuration.label
            .font(.headline)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 26)
            .padding(.horizontal, 10)
            .padding(.vertical, 14)
            .foregroundStyle(prominent ? Color.white : Color.primary)
            .background {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(LinearGradient(colors: prominent ? [colors.blueTop, colors.blueBottom] : [colors.faceTop, colors.faceBottom], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay { RoundedRectangle(cornerRadius: 17).strokeBorder(colors.glint, lineWidth: 1) }
                    .shadow(color: prominent ? colors.blueBase : colors.buttonBase, radius: 0, y: pressed ? 1 : 4)
                    .shadow(color: colors.shadow, radius: pressed ? 2 : 5, y: pressed ? 2 : 7)
            }
            .offset(y: pressed && !reduceMotion ? 3 : 0)
            .opacity(enabled ? 1 : 0.55)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.1), value: pressed)
    }
}

private struct TactileSoundStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let palette = ReelPalette(dark: scheme == .dark)
        configuration.label
            .background {
                Circle().fill(LinearGradient(colors: [palette.shellTop, palette.shellBottom], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay { Circle().strokeBorder(palette.glint, lineWidth: 1) }
                    .shadow(color: palette.buttonBase, radius: 0, y: configuration.isPressed ? 0 : 2)
                    .shadow(color: palette.shadow, radius: 3, y: 3)
            }
            .offset(y: configuration.isPressed && !reduceMotion ? 2 : 0)
    }
}

private struct ReelPalette {
    let dark: Bool
    var shellTop: Color { dark ? Color(red: 0.21, green: 0.23, blue: 0.27) : Color(red: 0.98, green: 0.985, blue: 1) }
    var shellBottom: Color { dark ? Color(red: 0.13, green: 0.15, blue: 0.18) : Color(red: 0.86, green: 0.88, blue: 0.92) }
    var faceTop: Color { dark ? Color(red: 0.32, green: 0.36, blue: 0.43) : Color(red: 0.99, green: 0.995, blue: 1) }
    var faceBottom: Color { dark ? Color(red: 0.19, green: 0.22, blue: 0.28) : Color(red: 0.86, green: 0.89, blue: 0.94) }
    var drumTop: Color { dark ? Color(red: 0.16, green: 0.19, blue: 0.23) : Color(red: 0.83, green: 0.87, blue: 0.92) }
    var drumMiddle: Color { dark ? Color(red: 0.24, green: 0.27, blue: 0.33) : Color(red: 0.98, green: 0.985, blue: 1) }
    var drumBottom: Color { dark ? Color(red: 0.12, green: 0.15, blue: 0.19) : Color(red: 0.79, green: 0.84, blue: 0.90) }
    var gripDark: Color { dark ? Color.black.opacity(0.75) : Color(red: 0.50, green: 0.57, blue: 0.67) }
    var gripLight: Color { dark ? Color(red: 0.38, green: 0.44, blue: 0.53) : Color(red: 0.93, green: 0.96, blue: 1) }
    var glint: Color { .white.opacity(dark ? 0.13 : 0.8) }
    var lensTint: Color { .blue.opacity(dark ? 0.025 : 0.012) }
    var lensBorder: Color { dark ? Color(red: 0.67, green: 0.80, blue: 0.96).opacity(0.5) : Color.white }
    var shadow: Color { .black.opacity(dark ? 0.34 : 0.15) }
    var occlusion: Color { .black.opacity(dark ? 0.68 : 0.34) }
    var buttonBase: Color { dark ? Color(red: 0.06, green: 0.08, blue: 0.11) : Color(red: 0.64, green: 0.69, blue: 0.77) }
    var blueTop: Color { Color(red: 0.20, green: 0.55, blue: 1) }
    var blueBottom: Color { Color(red: 0, green: 0.37, blue: 0.86) }
    var blueBase: Color { Color(red: 0, green: 0.25, blue: 0.59) }
}

#Preview {
    TactileReelView { _ in }
        .padding(24)
        .background(RollerStyle.background)
}
#Preview("Dark") {
    TactileReelView { _ in }
        .padding(24)
        .background(RollerStyle.background)
        .preferredColorScheme(.dark)
}
