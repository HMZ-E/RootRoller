import Foundation

/// A networking task, its available tokens, and the correct token sequence.
struct CLIChallenge: Identifiable {
    let id: UUID
    let title: String
    let instructions: String
    let commandBank: [CommandToken]
    let expectedCommand: [String]
    let explanation: String

    init(
        id: UUID = UUID(),
        title: String,
        instructions: String,
        commandBank: [CommandToken],
        expectedCommand: [String],
        explanation: String = "You built the right command."
    ) {
        self.id = id
        self.title = title
        self.instructions = instructions
        self.commandBank = commandBank
        self.expectedCommand = expectedCommand
        self.explanation = explanation
    }

    static let connectivityCheck = CLIChallenge(
        title: "Check connectivity",
        instructions: "Build a command to send exactly 4 ping requests to 192.168.1.1. Tap the command pieces in order, then tap Run.",
        commandBank: [
            CommandToken(text: "ping"),
            CommandToken(text: "-c"),
            CommandToken(text: "4"),
            CommandToken(text: "192.168.1.1"),
            CommandToken(text: "nslookup"),
            CommandToken(text: "8.8.8.8"),
            CommandToken(text: "traceroute"),
            CommandToken(text: "-t")
        ],
        expectedCommand: ["ping", "-c", "4", "192.168.1.1"],
        explanation: "The -c option limits ping to four requests. A reply would show the host can be reached; this terminal is a simulation."
    )
    static let campaign: [CLIChallenge] = [
        .connectivityCheck,
        CLIChallenge(title: "Find the address", instructions: "Look up the DNS records for example.com using nslookup.",
                     commandBank: ["nslookup", "example.com", "ping", "-c", "4", "traceroute"].map { CommandToken(text: $0) },
                     expectedCommand: ["nslookup", "example.com"], explanation: "nslookup asks DNS for a name's address. DNS lookup and connectivity testing answer different questions."),
        CLIChallenge(title: "Trace the path", instructions: "Trace the route to 203.0.113.10 using traceroute.",
                     commandBank: ["traceroute", "203.0.113.10", "ping", "nslookup", "-c", "4"].map { CommandToken(text: $0) },
                     expectedCommand: ["traceroute", "203.0.113.10"], explanation: "traceroute explores the hops toward a destination. This documentation address and every hop here are simulated."),
        CLIChallenge(title: "Check the local stack", instructions: "Send exactly one ping request to the loopback address 127.0.0.1.",
                     commandBank: ["ping", "-c", "1", "127.0.0.1", "192.168.1.1", "4", "traceroute", "localhost"].map { CommandToken(text: $0) },
                     expectedCommand: ["ping", "-c", "1", "127.0.0.1"], explanation: "127.0.0.1 loops back to this device. A loopback test does not prove the external network is reachable."),
        CLIChallenge(title: "Choose the resolver", instructions: "Use nslookup to look up example.com through DNS server 8.8.8.8.",
                     commandBank: ["nslookup", "example.com", "8.8.8.8", "ping", "-c", "4", "traceroute", "127.0.0.1"].map { CommandToken(text: $0) },
                     expectedCommand: ["nslookup", "example.com", "8.8.8.8"], explanation: "The final argument chooses a DNS server. The game checks the syntax locally and sends no DNS request.")
    ]
}
