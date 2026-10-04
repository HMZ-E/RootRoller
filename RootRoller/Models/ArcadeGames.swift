import Foundation

/// Pure game rules, separate from animation and input. All traffic is simulated.
struct PacketRushGame {
    struct Route: Identifiable {
        let id: Int
        let name: String
        let network: UInt32
        let prefix: Int
        var cidr: String { "\(SubnetChallenge.address(network))/\(prefix)" }
        func matches(_ address: UInt32) -> Bool {
            let mask: UInt32 = prefix == 0 ? 0 : UInt32.max << (32 - prefix)
            return address & mask == network & mask
        }
    }
    static let routes = [
        Route(id: 0, name: "Office", network: 0x0A000100, prefix: 24),
        Route(id: 1, name: "Campus", network: 0x0A000000, prefix: 16),
        Route(id: 2, name: "Internet", network: 0, prefix: 0),
        Route(id: 3, name: "Office backup", network: 0x0A000100, prefix: 24)
    ]
    let packets: [UInt32]
    private(set) var index = 0
    private(set) var delivered = 0
    private(set) var streak = 0
    private(set) var score = 0
    private(set) var message = "The longer matching prefix wins. Choose a gate, then send a packet."
    var finished: Bool { index == packets.count }
    var officeDown: Bool { index >= packets.count / 2 }
    var destination: UInt32 { packets[min(index, packets.count - 1)] }
    var address: String { SubnetChallenge.address(destination) }
    var availableRoutes: [Route] { Self.routes.filter { officeDown ? $0.id != 0 : $0.id != 3 } }
    var correctRoute: Int { availableRoutes.filter { $0.matches(destination) }.max { $0.prefix < $1.prefix }!.id }

    init(packets: [UInt32]? = nil) {
        self.packets = packets ?? (0..<4).flatMap { _ in
            [UInt32(0x0A000100) + UInt32.random(in: 1...254),
             UInt32(0x0A000000) + UInt32.random(in: 512...65_000),
             UInt32(0xC6336400) + UInt32.random(in: 1...254)].shuffled()
        }
        precondition(!self.packets.isEmpty)
    }
    mutating func send(to route: Int) {
        guard !finished else { return }
        let best = correctRoute
        if route == best {
            delivered += 1; streak += 1; score += 100 + min(streak - 1, 5) * 20
            message = "Delivered to \(Self.routes[best].name). /\(Self.routes[best].prefix) is the most specific live match."
        } else {
            streak = 0
            message = "Packet lost. \(Self.routes[best].name) is the most specific live route for \(address)."
        }
        index += 1
        if index == packets.count / 2 { message += " Office link failed! Use its backup for the second half." }
    }
}

struct PatrolPacket {
    let source: String
    let port: Int
    let transport: String
    var service: String {
        switch port { case 443: "HTTPS"; case 22: "SSH"; case 53: "DNS"; case 80: "HTTP"; default: "Other" }
    }
    var office: Bool { source.hasPrefix("10.0.0.") }
}

struct PortPatrolGame {
    let packets: [PatrolPacket]
    private(set) var index = 0
    private(set) var correct = 0
    private(set) var mistakes = 0
    private(set) var streak = 0
    private(set) var score = 0
    private(set) var timedOut = false
    private(set) var message = "Swipe right to allow, left to block. Buttons work too."
    var finished: Bool { index == packets.count || mistakes >= 3 || timedOut }
    var policyChanged: Bool { index >= packets.count / 2 }
    var policy: String { policyChanged ? "Allow TCP 443 from anywhere, and UDP 53 from Office. Block everything else." : "Allow TCP 443 from anywhere, and TCP 22 from Office. Block everything else." }
    var packet: PatrolPacket { packets[min(index, packets.count - 1)] }
    var shouldAllow: Bool {
        (packet.port == 443 && packet.transport == "TCP") ||
        (packet.office && (policyChanged ? packet.port == 53 && packet.transport == "UDP" : packet.port == 22 && packet.transport == "TCP"))
    }
    init(packets: [PatrolPacket]? = nil) {
        let examples = [
            PatrolPacket(source: "10.0.0.24", port: 22, transport: "TCP"),
            PatrolPacket(source: "198.51.100.8", port: 22, transport: "TCP"),
            PatrolPacket(source: "203.0.113.7", port: 443, transport: "TCP"),
            PatrolPacket(source: "10.0.0.82", port: 53, transport: "UDP"),
            PatrolPacket(source: "198.51.100.9", port: 53, transport: "UDP"),
            PatrolPacket(source: "10.0.0.45", port: 80, transport: "TCP"),
            PatrolPacket(source: "203.0.113.18", port: 443, transport: "UDP"),
            PatrolPacket(source: "10.0.0.19", port: 443, transport: "TCP"),
            PatrolPacket(source: "10.0.0.62", port: 22, transport: "TCP")
        ]
        self.packets = packets ?? (examples.shuffled() + examples.shuffled())
        precondition(!self.packets.isEmpty)
    }
    mutating func decide(allow: Bool) {
        guard !finished else { return }
        let expected = shouldAllow
        if allow == expected {
            correct += 1; streak += 1; score += 100 + min(streak - 1, 5) * 20
            message = "Correct. \(packet.transport) \(packet.port) from \(packet.source) is \(expected ? "allowed" : "blocked") by this policy."
        } else {
            mistakes += 1; streak = 0
            message = "Rule missed. This packet should be \(expected ? "allowed" : "blocked"). Check both its source and protocol."
        }
        index += 1
        if index == packets.count / 2 { message = "Policy changed! Office DNS is now allowed; SSH is blocked." }
    }
    mutating func expire() { guard !finished else { return }; timedOut = true; message = "Shift ended. Try practice mode for a round without a clock." }
}

struct CableRescueGame {
    static let devices = ["Laptop", "Switch", "Router", "Server"]
    let faults: [Int]
    private(set) var round = 0
    private(set) var probesLeft = 3
    private(set) var sparesLeft = 3
    private(set) var observations: [Int: Bool] = [0: true]
    private(set) var ruledOut: Set<Int> = []
    private(set) var repaired = false
    private(set) var rescued = 0
    private(set) var score = 0
    private(set) var message = "One cable has failed. Probe devices to narrow it down, then replace the broken link."
    var finished: Bool { (repaired || sparesLeft == 0) && round == faults.count - 1 }
    var roundEnded: Bool { repaired || sparesLeft == 0 }
    init(faults: [Int] = [0, 1, 2].shuffled()) { self.faults = faults; precondition(!faults.isEmpty && faults.allSatisfy { (0..<3).contains($0) }) }
    mutating func probe(_ device: Int) {
        guard !roundEnded, probesLeft > 0, (1..<4).contains(device), observations[device] == nil else { return }
        probesLeft -= 1
        let reachable = device <= faults[round]
        observations[device] = reachable
        message = "\(Self.devices[device]): \(reachable ? "reachable" : "no reply"). The fault is \(reachable ? "farther along the path" : "somewhere before this device")."
    }
    mutating func replace(_ link: Int) {
        guard !roundEnded, (0..<3).contains(link), !ruledOut.contains(link) else { return }
        sparesLeft -= 1
        if link == faults[round] {
            repaired = true; rescued += 1; score += 200 + probesLeft * 30 + sparesLeft * 20
            message = "Network restored. The cable between \(Self.devices[link]) and \(Self.devices[link + 1]) was broken."
        } else {
            ruledOut.insert(link)
            message = "That link was healthy. \(sparesLeft) spare cables left. Use the probe results to isolate the fault."
        }
    }
    mutating func next() {
        guard roundEnded, !finished else { return }
        round += 1; probesLeft = 3; sparesLeft = 3; observations = [0: true]; ruledOut = []; repaired = false
        message = "New outage. One cable is broken; you have three probes and three spares."
    }
}

struct LoopBreakerGame {
    struct Link: Identifiable {
        let id: Int
        let a: Int
        let b: Int
        var title: String { "\(String(UnicodeScalar(65 + a)!))–\(String(UnicodeScalar(65 + b)!))" }
    }
    static let links = [Link(id: 0, a: 0, b: 1), Link(id: 1, a: 1, b: 2), Link(id: 2, a: 2, b: 3), Link(id: 3, a: 3, b: 4), Link(id: 4, a: 4, b: 0), Link(id: 5, a: 0, b: 2), Link(id: 6, a: 0, b: 3)]
    private(set) var active: Set<Int> = Set(0..<7)
    private(set) var failedLink: Int?
    private(set) var stage = 0
    private(set) var moves = 0
    private(set) var finished = false
    private(set) var message = "Tap links to disable them. Keep all five switches connected without a loop."
    var connected: Bool { Self.connected(active) }
    var hasLoop: Bool { Self.hasLoop(active) }
    var safe: Bool { connected && !hasLoop }
    var score: Int { finished ? max(100, 700 - moves * 25) : 0 }

    static func connected(_ active: Set<Int>) -> Bool {
        var visited: Set<Int> = [0]
        var frontier = [0]
        while let node = frontier.popLast() {
            for edge in links where active.contains(edge.id) && (edge.a == node || edge.b == node) {
                let neighbor = edge.a == node ? edge.b : edge.a
                if visited.insert(neighbor).inserted { frontier.append(neighbor) }
            }
        }
        return visited.count == 5
    }
    static func hasLoop(_ active: Set<Int>) -> Bool {
        var parents = Array(0..<5)
        func root(_ node: Int) -> Int { var n = node; while parents[n] != n { n = parents[n] }; return n }
        for edge in links where active.contains(edge.id) {
            let a = root(edge.a), b = root(edge.b)
            if a == b { return true }
            parents[a] = b
        }
        return false
    }
    mutating func toggle(_ link: Int) {
        guard !finished, Self.links.contains(where: { $0.id == link }), link != failedLink else { return }
        if active.contains(link) { active.remove(link) } else { active.insert(link) }
        moves += 1
        message = !connected ? "A switch is isolated. Restore a path before sending traffic." : hasLoop ? "A loop remains. Remove redundant paths while keeping every switch connected." : "All five switches connected, no loops. Send the test traffic."
    }
    mutating func confirm() {
        guard !finished, safe else { return }
        if stage == 0 {
            stage = 1; failedLink = active.sorted().randomElement()!; active.remove(failedLink!)
            message = "Link \(Self.links[failedLink!].title) failed. Restore a safe backup path, then test again."
        } else { finished = true; message = "Traffic flows safely, even after a link failure. Every switch has a path and no packets loop." }
    }
}

struct DHCPDashGame {
    enum Step: Int, CaseIterable, Identifiable {
        case discover, offer, request, ack
        var id: Int { rawValue }
        var title: String { ["Discover", "Offer", "Request", "ACK"][rawValue] }
    }
    struct Lease {
        let device: String
        let expiresAt: Int
    }
    static let devices = ["Laptop", "Phone", "Printer", "Console", "Camera", "Tablet"]
    static let pool = ["10.0.0.10", "10.0.0.11", "10.0.0.12"]
    private(set) var client = 0
    private(set) var step = Step.discover
    private(set) var selectedAddress: String?
    private(set) var leases: [String: Lease] = [:]
    private(set) var score = 0
    private(set) var message = "A new device needs an address. Begin with Discover."
    var finished: Bool { client == Self.devices.count }
    var device: String { Self.devices[min(client, Self.devices.count - 1)] }
    var prompt: String {
        if finished { return "Every device received an address." }
        switch step {
        case .discover: return "\(device) broadcasts to find a DHCP server."
        case .offer: return "Choose a free address, then send Offer from the server."
        case .request: return "\(device) requests the offered address."
        case .ack: return "The server acknowledges the lease."
        }
    }
    func expired(_ address: String) -> Bool { leases[address].map { client >= $0.expiresAt } ?? false }
    mutating func select(_ address: String) {
        guard !finished, Self.pool.contains(address) else { return }
        if let lease = leases[address] {
            if expired(address) {
                leases.removeValue(forKey: address)
                message = "Expired lease reclaimed. \(address) is available again."
            } else { message = "\(address) belongs to \(lease.device). Never offer an active lease to another client."; score = max(0, score - 20) }
            return
        }
        guard step == .offer else { message = "Wait for Discover before choosing an offer."; return }
        selectedAddress = address; message = "\(address) selected. Send Offer to \(device)."
    }
    mutating func send(_ action: Step) {
        guard !finished else { return }
        guard action == step else { message = "Out of order. \(step.title) comes next in Discover → Offer → Request → ACK."; score = max(0, score - 20); return }
        if action == .offer {
            guard let address = selectedAddress, leases[address] == nil else { message = "Choose a free address. Reclaim an expired lease if the pool is full."; return }
        }
        if action == .ack {
            guard let address = selectedAddress, leases[address] == nil else { return }
            leases[address] = Lease(device: device, expiresAt: client + 3)
            client += 1; score += 150; step = .discover; selectedAddress = nil
            message = finished ? "All six devices served without an address conflict." : "Lease confirmed. \(device) just arrived. Older leases may now be expired."
        } else { score += 25; step = Step(rawValue: step.rawValue + 1)!; message = prompt }
    }
}

struct HandshakeHeroGame {
    enum Sender: String, CaseIterable, Identifiable { case client = "Client", server = "Server"; var id: String { rawValue } }
    enum Packet: String, CaseIterable, Identifiable { case syn = "SYN", synAck = "SYN-ACK", ack = "ACK", data = "DATA", retry = "RETRY"; var id: String { rawValue } }
    struct Exchange { let sender: Sender; let packet: Packet }
    static let exchanges = [Exchange(sender: .client, packet: .syn), Exchange(sender: .server, packet: .synAck), Exchange(sender: .client, packet: .ack), Exchange(sender: .client, packet: .data), Exchange(sender: .server, packet: .ack), Exchange(sender: .client, packet: .data), Exchange(sender: .server, packet: .ack)]
    private(set) var index = 0
    private(set) var needsRetry = false
    private(set) var lostOnce = false
    private(set) var score = 0
    private(set) var mistakes = 0
    private(set) var message = "Client starts the conversation with SYN. Select its endpoint, then send the packet."
    var finished: Bool { index == Self.exchanges.count }
    var expected: Exchange { needsRetry ? Exchange(sender: .client, packet: .retry) : Self.exchanges[min(index, Self.exchanges.count - 1)] }
    var connected: Bool { index >= 3 }
    var prompt: String { finished ? "Both data packets acknowledged." : "\(expected.sender.rawValue) → \(expected.packet.rawValue)" }
    mutating func send(_ packet: Packet, from sender: Sender, wellTimed: Bool) {
        guard !finished else { return }
        guard packet == expected.packet, sender == expected.sender else {
            mistakes += 1; message = "The other endpoint is waiting. Send \(expected.packet.rawValue) from \(expected.sender.rawValue)."; return
        }
        if index == 3 && !lostOnce {
            lostOnce = true; needsRetry = true
            message = "DATA was lost before it reached Server. No ACK arrived. Use RETRY from Client to resend that segment."
            return
        }
        needsRetry = false; index += 1; score += wellTimed ? 150 : 100
        message = finished ? "Reliable delivery! The handshake completed and both data segments were acknowledged." : wellTimed ? "Perfect timing. \(prompt) comes next." : "Delivered. \(prompt) comes next."
    }
}
