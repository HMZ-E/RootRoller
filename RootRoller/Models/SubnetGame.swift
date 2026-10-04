import Foundation

/// IPv4 subnet arithmetic for the game's /24–/28 challenge range.
struct SubnetChallenge: Identifiable {
    let id = UUID()
    let network: UInt32
    let prefix: Int
    let answers: [UInt32]

    var blockSize: UInt32 { 1 << (32 - prefix) }
    var broadcast: UInt32 { network + blockSize - 1 }
    var firstHost: UInt32 { network + 1 }
    var lastHost: UInt32 { broadcast - 1 }
    var usableHosts: UInt32 { blockSize - 2 }
    var mask: UInt32 { UInt32.max << (32 - prefix) }
    var cidr: String { "\(Self.address(network))/\(prefix)" }

    init(network: UInt32, prefix: Int, shuffleAnswers: Bool = true) {
        precondition((24...28).contains(prefix))
        let mask = UInt32.max << (32 - prefix)
        self.network = network & mask
        self.prefix = prefix
        let block: UInt32 = 1 << (32 - prefix)
        let base = network & mask
        // Plausible mistakes: the last usable host and broadcasts for different block sizes.
        let options = [base + block - 1, base + block - 2, base + block / 2 - 1, base + block * 2 - 1]
        answers = shuffleAnswers ? options.shuffled() : options
    }

    static func address(_ value: UInt32) -> String {
        [24, 16, 8, 0].map { String((value >> $0) & 255) }.joined(separator: ".")
    }

    static func random(prefix: Int? = nil, excluding previous: SubnetChallenge? = nil) -> SubnetChallenge {
        var result: SubnetChallenge
        repeat {
            let chosenPrefix = prefix ?? Int.random(in: 24...28)
            let base: UInt32 = (192 << 24) | (168 << 16) | (UInt32.random(in: 1...30) << 8)
            let block: UInt32 = 1 << (32 - chosenPrefix)
            let offset = UInt32.random(in: 0..<(256 / block)) * block
            result = SubnetChallenge(network: base + offset, prefix: chosenPrefix)
        } while result.cidr == previous?.cidr
        return result
    }
}

/// Session state lives independently of the views, so rewards cannot be claimed twice.
struct SubnetGame {
    static let totalRounds = 5
    static let spinCost = 15
    var challenge: SubnetChallenge = .random()
    private(set) var balance = 1_450
    private(set) var round = 1
    private(set) var streak = 0
    private(set) var correctCount = 0
    private(set) var earned = 0
    private(set) var selectedAnswer: UInt32?
    var lockedPrefix: Int?
    private(set) var bonusEligible = false

    var answered: Bool { selectedAnswer != nil }
    var correct: Bool { selectedAnswer == challenge.broadcast }
    var finished: Bool { answered && round == Self.totalRounds }
    var reward: Int { 80 + (bonusEligible ? 25 : 0) }
    var canSpin: Bool { !finished && balance >= Self.spinCost }

    mutating func toggleLock() {
        guard !answered else { return }
        lockedPrefix = lockedPrefix == nil ? challenge.prefix : nil
    }

    @discardableResult
    mutating func spin() -> Bool {
        guard canSpin else { return false }
        if answered { round += 1 }
        balance -= Self.spinCost
        challenge = .random(prefix: lockedPrefix, excluding: challenge)
        selectedAnswer = nil
        bonusEligible = lockedPrefix != nil
        return true
    }

    mutating func answer(_ address: UInt32) {
        guard !answered, challenge.answers.contains(address) else { return }
        selectedAnswer = address
        if correct {
            streak += 1
            correctCount += 1
            balance += reward
            earned += reward
        } else {
            streak = 0
        }
    }
}
