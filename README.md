# Root Roller

A native SwiftUI networking arcade for iPhone and iPad, targeting iOS 17+.

Open `RootRoller.xcodeproj`, select the shared **RootRoller** scheme, and run on
an iOS simulator. The Jackpot Hub lets you choose a game or spin a tactile drum,
then launch its selected game. All eight games are playable; the reel and library
share the same game registry.
For a physical device, select your development team and bundle identifier in
Signing & Capabilities.

## Design

The app uses native navigation, SF typography and symbols, semantic system colors,
and grouped surfaces. It follows the device appearance by default; **Settings**
lets you choose System, Light, or Dark and enable or disable haptic feedback.
These preferences persist between launches. Scores remain local to each game session.

The hub reel has curved game tiles, recessed metal surfaces, textured side grips,
and buttons that visibly press down. Drag it slowly to choose a game, flick to
coast through the slots, or tap **Roll** for a new selection. The **Play game**
button launches the settled game. Selection haptics mark detents and a firmer
impact marks the landing. Optional original click sounds start muted, can be
toggled on the reel or in Settings, and respect the device silent switch.

The drum supports VoiceOver adjustment and keeps a full-size selected-game label
outside the visual tiles. At accessibility text sizes its controls stack. Reduced
Motion skips the spin; display links stop when the hub disappears or the app
becomes inactive. The reel lists playable games from the shared `MiniGame` registry.

Each game includes a **How to Play** sheet. Layouts support Dynamic Type; at
accessibility text sizes, subnet answers become a single column and controls
scroll with the content. Reduced Motion and Reduced Transparency are respected.
The terminal keeps a dark surface in both appearances to make commands easy to read.

The app includes an opaque 1024px icon combining dice pips with a network graph.
Regenerate it on macOS with:

```sh
xcrun swiftc Scripts/GenerateAppIcon.swift -o /tmp/root-roller-icon
/tmp/root-roller-icon
```

Simulator screenshots of the hub, games, Settings, How to Play, session
completion, and both appearances are saved in `Previews/`.

## Subnet Slots

Play five IPv4 broadcast-address challenges with /24–/28 networks. Each round
shows the network, CIDR prefix, usable host count, subnet mask, block size, and
first host. Choose one of four answers to see the correct address and an
explanation of the calculation.

- Correct answers earn 80 Roller points; incorrect answers break the streak.
- A new subnet costs 15 points. Before answering, reroll the current round;
  after answering, the same button advances to the next round.
- Lock the current prefix before spinning to retain it on the next generated
  subnet. A correct answer to that locked spin earns an additional 25 points.
- Answer rewards can only be claimed once. A completed session shows its score
  and offers a fresh session. If points run out, a fresh session is also available.

Each session starts with 1,450 simulated points. Scores and locks are local to
that session; they are not persisted, purchased, or shared between games.

## Mini-games

| Game | What you do | Round twist |
| --- | --- | --- |
| Subnet Slots | Find broadcast addresses in five subnet challenges | Lock a CIDR prefix for a bonus |
| The CLI Crisis | Build five commands from a tappable token bank | DNS, route tracing, loopback, and choosing a resolver |
| Packet Rush | Select gates as packets move through a routing junction | Office fails halfway through; its backup takes over |
| Cable Rescue | Probe devices and drag or tap replacement cables | Three diagnostic probes and three spares per outage |
| Port Patrol | Swipe traffic into Allow or Block | Firewall policy changes halfway through the shift |
| Handshake Hero | Select endpoints and time SYN, ACK, and DATA packets | One DATA segment is lost and must be retransmitted |
| Loop Breaker | Toggle topology links while keeping switches connected | An active link fails after the first safe topology |
| DHCP Dash | Complete DORA exchanges and manage an address pool | Expired leases must be reclaimed to serve six clients |

Every new game has scoring, feedback, a complete session, replay, and a How to
Play sheet. Points belong to each session. No network connections, shell
commands, actual device probes, or address assignments occur.

Packet Rush has live moving traffic plus **Pause** and **Send now** for paced
play. Port Patrol has a 45-second shift, a three-mistake limit, and an untimed
**Practice** option. Its decision and pause controls stay in the bottom bar at
standard text sizes. Both pause when leaving the screen or backgrounding the app.
Handshake Hero has an optional timing bonus with no deadline. Reduced Motion
stops decorative packet travel and disables the moving timing lane. Cable Rescue
supports dragging a spare cable or tapping the destination link. Topology links
have an additional full-size control list at accessibility text sizes.

The CLI Crisis progresses through five simulated commands: a four-request ping,
a DNS lookup, traceroute, a loopback ping, and a lookup through a chosen resolver.
**Undo**, **Clear**, and **Run** edit and check the token sequence. Correct tasks
award 100 R once; **Next task** advances the session. Input remains entirely
based on taps, with no text fields or keyboards.

Protocol lessons are simplified gameplay models informed by the primary
specifications: [IPv4 forwarding](https://www.rfc-editor.org/rfc/rfc1812.html),
[TCP](https://www.rfc-editor.org/rfc/rfc9293.html), and
[DHCP](https://www.rfc-editor.org/rfc/rfc2131.html). DHCP lease lifetime is counted
in client arrivals for the game; real DHCP leases use time.

## Structure

```text
RootRoller/
  RootRollerApp.swift
  RootRollerStyle.swift           Shared palette, panels, buttons, and labels
  Models/
    CommandToken.swift
    CLIChallenge.swift
    SubnetGame.swift              IPv4 arithmetic and session rules
    MiniGame.swift                Playable game registry
    ReelMotion.swift              Drum physics, haptics, and original click sounds
    ArcadeGames.swift             Pure rules for six new games
  Views/
    JackpotHubView.swift
    TactileReelView.swift          Curved drum, grips, lens, and pressable controls
    TheCLICrisisView.swift
    SubnetSlotsView.swift
    ArcadeComponents.swift        Shared session UI, results, and guides
    PacketRushView.swift
    CableRescueView.swift
    PortPatrolView.swift
    HandshakeHeroView.swift
    LoopBreakerView.swift
    DHCPDashView.swift
  Assets.xcassets/
Tests/
  SubnetGameChecks.swift          Standalone subnet model checks
  ArcadeGameChecks.swift          Routing, firewall, cable, TCP, topology, DHCP checks
  RootRollerUITests.swift         Simulator gameplay and tap-input checks
```

## Validation

Build without device signing:

```sh
xcodebuild -project RootRoller.xcodeproj -scheme RootRoller \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

Run the model checks:

```sh
xcrun swiftc RootRoller/Models/SubnetGame.swift Tests/SubnetGameChecks.swift \
  -o /tmp/root-roller-game-checks
/tmp/root-roller-game-checks
```

Run the arcade model checks:

```sh
xcrun swiftc RootRoller/Models/SubnetGame.swift RootRoller/Models/ArcadeGames.swift \
  RootRoller/Models/CommandToken.swift RootRoller/Models/CLIChallenge.swift \
  Tests/ArcadeGameChecks.swift -o /tmp/root-roller-arcade-checks
/tmp/root-roller-arcade-checks
```

Run the shared scheme's UI tests in Xcode with **Product > Test**, or with
`xcodebuild test` and an available iOS simulator destination. The tests play
through a five-round subnet session, restart it, and build a CLI command by
tapping its tokens. New session tests play through all six additional games and
the five-task CLI campaign, then verify replay. Input checks cover real cable
drag-and-drop and both firewall swipe directions. The suite also checks reel rolling,
slow drags, momentum flicks, selected-game navigation, persistent sound preferences, light and dark appearances, Settings,
the guide sheet, and accessibility text sizes. Screenshots are retained in the
test results.

The app has no third-party dependencies.
