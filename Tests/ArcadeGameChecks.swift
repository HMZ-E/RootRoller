import Foundation

@main
struct ArcadeGameChecks {
    static func main() {
        var routing = PacketRushGame(packets: Array(repeating: [UInt32(0x0A0001FE), 0x0A0002FF, 0xCB007107], count: 4).flatMap { $0 })
        for index in 0..<12 {
            precondition(routing.correctRoute == (index % 3 == 0 ? (index >= 6 ? 3 : 0) : index % 3 == 1 ? 1 : 2))
            routing.send(to: routing.correctRoute)
        }
        precondition(routing.finished && routing.delivered == 12 && routing.streak == 12)
        let routeScore = routing.score
        routing.send(to: 1); precondition(routing.score == routeScore)
        var badRoute = PacketRushGame(packets: [0x0A000101, 0x0A000102])
        badRoute.send(to: 1); precondition(badRoute.delivered == 0 && badRoute.streak == 0)
        precondition(badRoute.officeDown && badRoute.correctRoute == 3)
        badRoute.send(to: 0); precondition(badRoute.delivered == 0)
        for _ in 0..<100 {
            let game = PacketRushGame()
            precondition(game.packets.count == 12)
            for packet in game.packets { precondition(PacketRushGame.routes.contains { $0.matches(packet) }) }
        }

        let firewallVectors = [
            PatrolPacket(source: "10.0.0.42", port: 22, transport: "TCP"),
            PatrolPacket(source: "10.0.1.42", port: 22, transport: "TCP"),
            PatrolPacket(source: "203.0.113.42", port: 443, transport: "UDP"),
            PatrolPacket(source: "203.0.113.42", port: 443, transport: "TCP"),
            PatrolPacket(source: "10.0.0.42", port: 53, transport: "UDP"),
            PatrolPacket(source: "10.0.1.42", port: 53, transport: "UDP"),
            PatrolPacket(source: "10.0.0.42", port: 22, transport: "TCP"),
            PatrolPacket(source: "203.0.113.42", port: 443, transport: "TCP")
        ]
        var patrol = PortPatrolGame(packets: firewallVectors)
        for allowed in [true, false, false, true, true, false, false, true] {
            precondition(patrol.shouldAllow == allowed); patrol.decide(allow: allowed)
        }
        precondition(patrol.finished && patrol.correct == 8 && patrol.mistakes == 0)
        let patrolScore = patrol.score; patrol.decide(allow: true); precondition(patrol.score == patrolScore)
        var mistakes = PortPatrolGame(); for _ in 0..<3 { mistakes.decide(allow: !mistakes.shouldAllow) }; precondition(mistakes.finished)
        var timeout = PortPatrolGame(); timeout.expire(); timeout.decide(allow: true); precondition(timeout.finished && timeout.index == 0)

        for fault in 0..<3 {
            var rescue = CableRescueGame(faults: [fault])
            for device in 1..<4 { rescue.probe(device); precondition(rescue.observations[device] == (device <= fault)) }
            precondition(rescue.probesLeft == 0)
            rescue.probe(1); precondition(rescue.probesLeft == 0)
            let healthy = (fault + 1) % 3
            rescue.replace(healthy); precondition(!rescue.repaired && rescue.sparesLeft == 2)
            rescue.replace(healthy); precondition(rescue.sparesLeft == 2)
            rescue.replace(fault); precondition(rescue.repaired && rescue.finished && rescue.rescued == 1)
            let score = rescue.score; rescue.replace(fault); precondition(rescue.score == score)
        }
        var rescue = CableRescueGame(faults: [0, 1, 2])
        for fault in 0..<3 { rescue.replace(fault); if fault < 2 { rescue.next(); precondition(rescue.sparesLeft == 3 && rescue.probesLeft == 3) } }
        precondition(rescue.finished && rescue.rescued == 3)

        precondition(LoopBreakerGame.connected([0, 1, 2, 3]))
        precondition(!LoopBreakerGame.hasLoop([0, 1, 2, 3]))
        precondition(LoopBreakerGame.connected([0, 1, 2, 3, 4]) && LoopBreakerGame.hasLoop([0, 1, 2, 3, 4]))
        precondition(!LoopBreakerGame.connected([0, 1, 5]) && LoopBreakerGame.hasLoop([0, 1, 5]))
        for _ in 0..<100 {
            var loop = LoopBreakerGame()
            loop.confirm(); precondition(loop.stage == 0)
            for link in [4, 5, 6] { loop.toggle(link) }
            precondition(loop.safe); loop.confirm(); precondition(!loop.connected && loop.stage == 1)
            let failed = loop.failedLink!; loop.toggle(failed); precondition(!loop.active.contains(failed))
            loop.toggle(4); precondition(loop.safe); loop.confirm(); precondition(loop.finished && loop.score > 0)
            let finalMoves = loop.moves; loop.toggle(0); precondition(loop.moves == finalMoves)
        }

        var dhcp = DHCPDashGame()
        dhcp.send(.ack); precondition(dhcp.step == .discover && dhcp.client == 0)
        for client in 0..<6 {
            dhcp.send(.discover)
            dhcp.send(.offer); precondition(dhcp.step == .offer)
            if let active = DHCPDashGame.pool.first(where: { dhcp.leases[$0] != nil && !dhcp.expired($0) }) {
                dhcp.select(active); precondition(dhcp.selectedAddress == nil)
            }
            for address in DHCPDashGame.pool where dhcp.expired(address) { dhcp.select(address); precondition(dhcp.leases[address] == nil) }
            let available = DHCPDashGame.pool.first { dhcp.leases[$0] == nil }!
            dhcp.select(available); dhcp.send(.offer); dhcp.send(.request)
            precondition(dhcp.leases[available] == nil)
            dhcp.send(.ack); precondition(dhcp.client == client + 1 && dhcp.leases[available] != nil)
            precondition(Set(dhcp.leases.values.map(\.device)).count == dhcp.leases.count)
        }
        precondition(dhcp.finished)
        let dhcpScore = dhcp.score; dhcp.send(.ack); precondition(dhcp.score == dhcpScore)

        var tcp = HandshakeHeroGame()
        tcp.send(.synAck, from: .client, wellTimed: true); precondition(tcp.index == 0 && tcp.mistakes == 1)
        for step in HandshakeHeroGame.exchanges {
            tcp.send(step.packet, from: step.sender, wellTimed: true)
            if tcp.needsRetry {
                precondition(tcp.index == 3)
                tcp.send(.ack, from: .server, wellTimed: true); precondition(tcp.needsRetry && tcp.index == 3)
                tcp.send(.retry, from: .client, wellTimed: true)
            }
        }
        precondition(tcp.finished && tcp.score == 1050 && tcp.lostOnce)
        let tcpScore = tcp.score; tcp.send(.data, from: .client, wellTimed: true); precondition(tcp.score == tcpScore)
        precondition(CLIChallenge.campaign.count == 5)
        for challenge in CLIChallenge.campaign { precondition(Set(challenge.expectedCommand).isSubset(of: Set(challenge.commandBank.map(\.text)))) }
        print("Passed: routing boundaries/failover, firewall protocol/source/policy changes, fault isolation, 100 topology failures, DHCP ordering/expiry/conflicts, TCP loss/retry, completion guards, and CLI banks.")
    }
}
