import SwiftUI

/// Every listed game has a playable destination in the hub.
enum MiniGame: String, CaseIterable, Identifiable, Hashable {
    case subnetSlots, cliCrisis, packetRush, cableRescue, portPatrol, handshakeHero, loopBreaker, dhcpDash
    var id: String { rawValue }
    var title: String {
        switch self {
        case .subnetSlots: "Subnet Slots"
        case .cliCrisis: "The CLI Crisis"
        case .packetRush: "Packet Rush"
        case .cableRescue: "Cable Rescue"
        case .portPatrol: "Port Patrol"
        case .handshakeHero: "Handshake Hero"
        case .loopBreaker: "Loop Breaker"
        case .dhcpDash: "DHCP Dash"
        }
    }
    var symbol: String {
        switch self {
        case .subnetSlots: "square.split.2x2.fill"
        case .cliCrisis: "terminal.fill"
        case .packetRush: "arrow.triangle.branch"
        case .cableRescue: "cable.connector"
        case .portPatrol: "checkmark.shield.fill"
        case .handshakeHero: "arrow.left.arrow.right"
        case .loopBreaker: "point.3.connected.trianglepath.dotted"
        case .dhcpDash: "ticket.fill"
        }
    }
    var tint: Color {
        switch self {
        case .subnetSlots: .blue
        case .cliCrisis: .teal
        case .packetRush: .indigo
        case .cableRescue: .orange
        case .portPatrol: .green
        case .handshakeHero: .purple
        case .loopBreaker: .pink
        case .dhcpDash: .cyan
        }
    }
    var topic: String {
        switch self {
        case .subnetSlots: "Subnetting"
        case .cliCrisis: "Command line"
        case .packetRush: "Routing"
        case .cableRescue: "Troubleshooting"
        case .portPatrol: "Firewall"
        case .handshakeHero: "TCP"
        case .loopBreaker: "Topology"
        case .dhcpDash: "Addressing"
        }
    }
    var format: String {
        switch self {
        case .subnetSlots: "5 rounds"
        case .cliCrisis: "5 tasks"
        case .packetRush: "Live arcade"
        case .cableRescue: "Repair puzzle"
        case .portPatrol: "Swipe patrol"
        case .handshakeHero: "Timing"
        case .loopBreaker: "Link puzzle"
        case .dhcpDash: "Lease manager"
        }
    }
    var subtitle: String {
        switch self {
        case .subnetSlots: "Find your way around a subnet."
        case .cliCrisis: "Five small crises. Build the right commands."
        case .packetRush: "Steer traffic. Survive a broken link."
        case .cableRescue: "Find the fault. Bring everyone back online."
        case .portPatrol: "Allow good traffic. Catch the rule breakers."
        case .handshakeHero: "Keep two endpoints talking, even when a packet gets lost."
        case .loopBreaker: "Stop the storm without cutting anyone off."
        case .dhcpDash: "A tiny address pool. A growing device queue."
        }
    }
    var instructions: String {
        switch self {
        case .packetRush: "Choose the most specific live route before each packet reaches the junction."
        case .cableRescue: "Probe the path. Drag a spare cable onto the broken link, or tap the link to replace it."
        case .portPatrol: "Swipe right to allow, left to block. Follow the policy, even when it changes."
        case .handshakeHero: "Choose a sender and a packet. Send inside the green pulse for a timing bonus."
        case .loopBreaker: "Tap links to remove loops. Keep every switch connected, then survive a link failure."
        case .dhcpDash: "Guide each device through Discover, Offer, Request, and ACK. Reclaim expired leases."
        default: subtitle
        }
    }
    var tips: [String] {
        switch self {
        case .packetRush: ["Start the wave for moving traffic. Pause and Send now let you work at your own pace.", "Office /24 beats Campus /16; Campus beats the Internet /0 default route.", "Halfway through, Office goes offline. Its /24 backup takes over. Select a live gate to keep your streak."]
        case .cableRescue: ["Start at Laptop and probe Switch, Router, or Server. A reply means the broken cable is farther along the path.", "You have three probes and three spares per outage. Drag a spare onto a link, or tap that link. A healthy replacement still uses a spare.", "Repair three outages. Unused probes and spare cables earn bonus points. Link lights reflect your observations, not hidden answers."]
        case .portPatrol: ["Office means source addresses in 10.0.0.0/24. Match the protocol, port, and source against the policy.", "Swipe the packet or use Allow and Block. The policy changes halfway through the 18-packet shift.", "Three mistakes or 45 seconds end a timed shift. Pause whenever you need. Turn on Practice before starting to remove the clock."]
        case .handshakeHero: ["Establish TCP with Client SYN, Server SYN-ACK, then Client ACK. Select the sender before tapping a packet.", "Send two DATA segments and acknowledge each from Server. One segment gets lost; Client must retry it before an ACK can arrive.", "The moving pulse is an optional timing bonus, not a deadline. Wrong packets never advance the connection. Reduced Motion replaces it with a static bonus-free lane."]
        case .loopBreaker: ["Active links are solid; standby links are dashed. Tap a link badge to switch it. Red means the link has failed.", "A safe topology connects all five switches with no cycles. For this board, four active links form a spanning tree.", "Test your topology to trigger a link failure. Re-enable a safe backup, then test again. Fewer moves earn more points."]
        case .dhcpDash: ["Follow Discover → Offer → Request → ACK. Choose a free address before sending Offer.", "An active lease belongs to one device. Tap an expired lease to reclaim it, then select that free address for a new offer.", "Serve six devices using three addresses. In this simulation a lease expires after three client arrivals. ACK commits the lease; an offer alone does not allocate it."]
        default: [instructions]
        }
    }
    static func at(_ slot: Int) -> MiniGame {
        let games = allCases
        return games[((slot % games.count) + games.count) % games.count]
    }
}
