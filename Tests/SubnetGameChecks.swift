import Foundation

@main
struct SubnetGameChecks {
    static func main() {
        let base: UInt32 = (192 << 24) | (168 << 16) | (10 << 8)
        for (prefix, hosts, last, mask) in [
            (24, 254, 255, "255.255.255.0"),
            (25, 126, 127, "255.255.255.128"),
            (26, 62, 63, "255.255.255.192"),
            (27, 30, 31, "255.255.255.224"),
            (28, 14, 15, "255.255.255.240")
        ] {
            let challenge = SubnetChallenge(network: base, prefix: prefix)
            precondition(challenge.usableHosts == UInt32(hosts))
            precondition(challenge.broadcast == base + UInt32(last))
            precondition(SubnetChallenge.address(challenge.mask) == mask)
            precondition(Set(challenge.answers).count == 4)
            precondition(challenge.answers.contains(challenge.broadcast))
            precondition(challenge.answers.contains { $0 > challenge.broadcast })
            precondition(challenge.answers.contains(challenge.lastHost))
        }
        let unaligned = SubnetChallenge(network: base + 79, prefix: 26)
        precondition(unaligned.network == base + 64)
        precondition(unaligned.broadcast == base + 127)

        for _ in 0..<1_000 {
            let challenge = SubnetChallenge.random()
            precondition(challenge.network & challenge.mask == challenge.network)
            precondition(challenge.firstHost < challenge.lastHost)
            precondition(challenge.lastHost < challenge.broadcast)
            precondition(Set(challenge.answers).count == 4)
        }

        var game = SubnetGame()
        game.answer(UInt32.max)
        precondition(!game.answered)
        game.toggleLock()
        let locked = game.challenge.prefix
        let previous = game.challenge.cidr
        precondition(game.spin())
        precondition(game.balance == 1_435 && game.challenge.prefix == locked)
        precondition(game.challenge.cidr != previous && game.bonusEligible)
        game.answer(game.challenge.broadcast)
        precondition(game.balance == 1_540 && game.streak == 1 && game.earned == 105)
        game.answer(game.challenge.broadcast)
        precondition(game.balance == 1_540 && game.correctCount == 1)
        for round in 2...5 {
            precondition(game.spin())
            precondition(game.round == round)
            game.answer(game.challenge.broadcast)
        }
        precondition(game.finished && game.correctCount == 5 && game.earned == 525)
        precondition(!game.spin())

        var wrong = SubnetGame()
        wrong.answer(wrong.challenge.lastHost)
        precondition(wrong.answered && !wrong.correct && wrong.balance == 1_450 && wrong.streak == 0)
        precondition(wrong.spin() && wrong.round == 2 && !wrong.answered)
        wrong.answer(wrong.challenge.broadcast)
        precondition(wrong.earned == 80 && wrong.streak == 1)
        precondition(wrong.spin())
        wrong.answer(wrong.challenge.lastHost)
        precondition(wrong.streak == 0)

        var exhausted = SubnetGame()
        for _ in 0..<96 { precondition(exhausted.spin()) }
        precondition(exhausted.balance == 10 && !exhausted.canSpin)
        precondition(!exhausted.spin() && exhausted.balance == 10)
        print("Passed: subnet vectors, 1,000 generated challenges, scoring, locking, round progression, duplicate-answer protection, and point exhaustion.")
    }
}
