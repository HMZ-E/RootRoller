import XCTest
import UIKit

final class RootRollerUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testTactileReelRollAndPlay() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-appAppearance", "light", "-reelSoundsEnabled", "NO"]
        app.launch()
        let selection = app.staticTexts["hub.selection"]
        XCTAssertTrue(selection.waitForExistence(timeout: 10))
        let initial = selection.label
        let roll = app.buttons["hub.roll"]
        reveal(roll, in: app)
        attach("Tactile Reel Light")
        roll.tap()
        let changed = NSPredicate(format: "label != %@", initial)
        expectation(for: changed, evaluatedWith: selection)
        waitForExpectations(timeout: 8)
        XCTAssertTrue(roll.isEnabled)
        let selected = selection.label
        app.buttons["hub.quickPlay"].tap()
        XCTAssertTrue(app.navigationBars[selected].waitForExistence(timeout: 5))
    }

    func testTactileReelDrag() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-appAppearance", "light", "-reelSoundsEnabled", "NO"]
        app.launch()
        let reel = app.descendants(matching: .any)["hub.reel"]
        XCTAssertTrue(reel.waitForExistence(timeout: 10))
        let initial = app.staticTexts["hub.selection"].label
        let start = reel.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65))
        let end = reel.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.30))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.35)
        let changed = NSPredicate(format: "label != %@", initial)
        expectation(for: changed, evaluatedWith: app.staticTexts["hub.selection"])
        waitForExpectations(timeout: 8)
        XCTAssertTrue(app.buttons["hub.roll"].isEnabled)
        attach("Tactile Reel After Drag")
        app.buttons["hub.quickPlay"].tap()
        XCTAssertTrue(app.navigationBars["The CLI Crisis"].waitForExistence(timeout: 5))
    }

    func testTactileReelLargeText() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-appAppearance", "light", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.staticTexts["hub.selection"].waitForExistence(timeout: 10))
        attach("Tactile Reel Large Text")
        let roll = app.buttons["hub.roll"]
        reveal(roll, in: app)
        roll.tap()
        let settled = NSPredicate(format: "enabled == true AND label CONTAINS %@", "Roll again")
        expectation(for: settled, evaluatedWith: app.buttons["hub.roll"])
        waitForExpectations(timeout: 8)
        let play = app.buttons["hub.quickPlay"]
        reveal(play, in: app)
        let selected = app.staticTexts["hub.selection"].label
        play.tap()
        XCTAssertTrue(app.navigationBars[selected].waitForExistence(timeout: 5))
    }

    func testReelSoundPreference() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-appAppearance", "light"]
        app.launch()
        let sound = app.buttons["hub.reelSound"]
        XCTAssertTrue(sound.waitForExistence(timeout: 10))
        if sound.label == "Mute reel sounds" { sound.tap() }
        app.buttons["hub.settings"].tap()
        let toggle = app.switches["settings.reelSounds"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        XCTAssertEqual(toggle.value as? String, "0")
        // The accessibility switch includes its row; target the visible thumb.
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.5)).tap()
        XCTAssertEqual(toggle.value as? String, "1")
        app.buttons["Done"].tap()
        expectation(for: NSPredicate(format: "label == %@", "Mute reel sounds"), evaluatedWith: sound)
        waitForExpectations(timeout: 3)
        app.terminate()
        app.launch()
        XCTAssertTrue(sound.waitForExistence(timeout: 10))
        XCTAssertEqual(sound.label, "Mute reel sounds")
        sound.tap()
        app.buttons["hub.settings"].tap()
        XCTAssertEqual(toggle.value as? String, "0")
        attach("Reel Settings")
    }

    func testTactileReelFlick() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-appAppearance", "light", "-reelSoundsEnabled", "NO"]
        app.launch()
        let reel = app.descendants(matching: .any)["hub.reel"]
        XCTAssertTrue(reel.waitForExistence(timeout: 10))
        let start = reel.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        let end = reel.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        start.press(forDuration: 0.01, thenDragTo: end, withVelocity: .fast, thenHoldForDuration: 0)
        let settled = NSPredicate(format: "enabled == true AND label CONTAINS %@", "Roll again")
        expectation(for: settled, evaluatedWith: app.buttons["hub.roll"])
        waitForExpectations(timeout: 8)
        let selected = app.staticTexts["hub.selection"].label
        XCTAssertTrue(["Subnet Slots", "The CLI Crisis", "Packet Rush", "Cable Rescue", "Port Patrol", "Handshake Hero", "Loop Breaker", "DHCP Dash"].contains(selected))
        attach("Tactile Reel After Flick")
        app.buttons["hub.quickPlay"].tap()
        XCTAssertTrue(app.navigationBars[selected].waitForExistence(timeout: 5))
    }

    func testSubnetSession() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-appAppearance", "light"]
        app.launch()
        attach("Jackpot Hub")
        openGame("game.subnetSlots", in: app)
        XCTAssertTrue(app.staticTexts["Subnet Slots"].waitForExistence(timeout: 5))
        attach("Subnet Slots")
        for round in 1...5 {
            XCTAssertTrue(app.staticTexts["Round \(round) of 5"].exists)
            if !app.staticTexts["subnet.cidr"].exists { app.scrollViews.firstMatch.swipeUp() }
            XCTAssertTrue(app.staticTexts["subnet.cidr"].waitForExistence(timeout: 5))
            let cidr = app.staticTexts["subnet.cidr"].label.split(separator: "/")
            XCTAssertEqual(cidr.count, 2)
            let octets = cidr[0].split(separator: ".").map { UInt32($0)! }
            let network = octets.reduce(UInt32(0)) { ($0 << 8) | $1 }
            let broadcast = network + (UInt32(1) << (32 - Int(cidr[1])!)) - 1
            let address = [24, 16, 8, 0].map { String((broadcast >> $0) & 255) }.joined(separator: ".")
            let answer = app.buttons["answer.\(address)"]
            for _ in 0..<3 {
                if answer.isHittable && answer.frame.maxY < app.buttons["subnet.lock"].frame.minY - 8 { break }
                app.scrollViews.firstMatch.swipeUp()
            }
            XCTAssertTrue(answer.waitForExistence(timeout: 3))
            answer.tap()
            let spin = app.buttons["subnet.spin"]
            let nextLabel = NSPredicate(format: "label CONTAINS %@", round == 5 ? "Play a new session" : "Next round")
            expectation(for: nextLabel, evaluatedWith: spin)
            waitForExpectations(timeout: 5)
            if round < 5 {
                spin.tap()
                let enabled = NSPredicate(format: "enabled == true")
                expectation(for: enabled, evaluatedWith: spin)
                waitForExpectations(timeout: 5)
            }
        }
        attach("After fifth answer")
        XCTAssertTrue(app.staticTexts["5 of 5 subnets solved"].waitForExistence(timeout: 5), app.debugDescription)
        attach("Session result")
        app.buttons["subnet.spin"].tap()
        XCTAssertTrue(app.staticTexts["Round 1 of 5"].exists)
    }

    func testCLIUsesTapInput() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-appAppearance", "light"]
        app.launch()
        openGame("game.cliCrisis", in: app)
        for token in ["ping", "-c", "4", "192.168.1.1"] {
            app.buttons["Add \(token) to command"].tap()
        }
        XCTAssertEqual(app.staticTexts["cli.command"].label, "Current command: ping -c 4 192.168.1.1")
        XCTAssertEqual(app.textFields.count, 0)
        attach("The CLI Crisis")
        app.buttons["Run"].tap()
        XCTAssertTrue(app.staticTexts["Connection complete"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["cli.command"].label, "Current command: empty")
    }

    func testDarkAppearance() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-appAppearance", "dark"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Root Roller"].waitForExistence(timeout: 10))
        attach("Jackpot Hub Dark")
        openGame("game.subnetSlots", in: app)
        XCTAssertTrue(app.staticTexts["subnet.cidr"].waitForExistence(timeout: 5))
        attach("Subnet Slots Dark")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        openGame("game.cliCrisis", in: app)
        XCTAssertTrue(app.staticTexts["cli.command"].waitForExistence(timeout: 5))
        attach("The CLI Crisis Dark")
    }

    func testSettingsAndGuide() throws {
        let app = XCUIApplication()
        app.launch()
        let settings = app.buttons["hub.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 10))
        settings.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        app.buttons["Light"].tap()
        XCTAssertTrue(app.buttons["Light"].isSelected)
        XCTAssertGreaterThan(sheetBackgroundBrightness(), 0.8)
        attach("Settings")
        app.buttons["Dark"].tap()
        XCTAssertTrue(app.buttons["Dark"].isSelected)
        XCTAssertLessThan(sheetBackgroundBrightness(), 0.2)
        attach("Settings Dark")
        app.buttons["System"].tap()
        app.buttons["Done"].tap()
        let guide = app.buttons["hub.guide"]
        for _ in 0..<5 {
            if guide.exists && guide.isHittable { break }
            scrollHubUp(app)
        }
        guide.tap()
        XCTAssertTrue(app.navigationBars["How to Play"].waitForExistence(timeout: 5))
        attach("How to Play")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Root Roller"].exists)
    }

    func testAccessibilityText() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-appAppearance", "light", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        openGame("game.subnetSlots", in: app)
        XCTAssertTrue(app.staticTexts["Round 1 of 5"].waitForExistence(timeout: 5))
        attach("Subnet Slots Large Text")
        let answer = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "answer.")).firstMatch
        for _ in 0..<12 {
            if answer.exists && answer.isHittable { break }
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(answer.exists, app.debugDescription)
        answer.tap()
        let spin = app.buttons["subnet.spin"]
        for _ in 0..<8 {
            if spin.exists && spin.isHittable { break }
            app.scrollViews.firstMatch.swipeUp()
        }
        let next = NSPredicate(format: "label CONTAINS %@", "Next round")
        expectation(for: next, evaluatedWith: app.buttons["subnet.spin"])
        waitForExpectations(timeout: 5)
    }


    func testPacketRushSession() throws {
        let app = arcadeApp(); openGame("game.packetRush", in: app)
        XCTAssertTrue(app.staticTexts["packet.destination"].waitForExistence(timeout: 5))
        attach("Packet Rush")
        for index in 0..<12 {
            let address = app.staticTexts["packet.destination"].label
            let route = address.hasPrefix("10.0.1.") ? (index >= 6 ? 3 : 0) : address.hasPrefix("10.0.") ? 1 : 2
            tapArcade(app.buttons["packet.route.\(route)"], in: app)
            tapArcade(app.buttons["packet.send"], in: app)
        }
        XCTAssertTrue(app.staticTexts["arcade.result"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["12 of 12 packets delivered"].exists)
        attach("Packet Rush Complete")
        tapArcade(app.buttons["arcade.restart"], in: app)
        XCTAssertTrue(app.staticTexts["packet.destination"].exists)
        tapArcade(app.buttons["packet.start"], in: app)
        XCTAssertTrue(app.buttons["packet.start"].label.contains("Pause"))
        tapArcade(app.buttons["packet.start"], in: app)
        XCTAssertTrue(app.buttons["packet.start"].label.contains("Resume"))
    }

    func testCableRescueSession() throws {
        let app = arcadeApp(); openGame("game.cableRescue", in: app)
        XCTAssertTrue(app.buttons["cable.probe.1"].waitForExistence(timeout: 5))
        attach("Cable Rescue")
        for round in 0..<3 {
            tapArcade(app.buttons["cable.probe.1"], in: app)
            var fault = 0
            if app.staticTexts["cable.status.1"].label == "Reachable" {
                tapArcade(app.buttons["cable.probe.2"], in: app)
                fault = app.staticTexts["cable.status.2"].label == "Reachable" ? 2 : 1
            }
            tapArcade(app.buttons["cable.link.\(fault)"], in: app)
            if round < 2 { tapArcade(app.buttons["cable.next"], in: app) }
        }
        XCTAssertTrue(app.staticTexts["arcade.result"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["3 of 3 networks restored"].exists)
        tapArcade(app.buttons["arcade.restart"], in: app)
        XCTAssertTrue(app.buttons["cable.probe.1"].exists)
    }


    func testCableDragRepair() throws {
        let app = arcadeApp(); openGame("game.cableRescue", in: app)
        XCTAssertTrue(app.buttons["cable.probe.1"].waitForExistence(timeout: 5))
        app.buttons["cable.probe.1"].tap()
        var fault = 0
        if app.staticTexts["cable.status.1"].label == "Reachable" {
            app.buttons["cable.probe.2"].tap()
            fault = app.staticTexts["cable.status.2"].label == "Reachable" ? 2 : 1
        }
        let source = app.descendants(matching: .any)["cable.spare"]
        let target = app.buttons["cable.link.\(fault)"]
        XCTAssertTrue(source.isHittable)
        source.press(forDuration: 0.7, thenDragTo: target)
        XCTAssertTrue(app.buttons["cable.next"].waitForExistence(timeout: 5))
    }

    func testPortPatrolSession() throws {
        let app = arcadeApp(); openGame("game.portPatrol", in: app)
        XCTAssertTrue(app.switches["patrol.practice"].waitForExistence(timeout: 5))
        let practice = app.switches["patrol.practice"]
        revealArcade(practice, in: app)
        practice.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.5)).tap()
        XCTAssertEqual(practice.value as? String, "1")
        tapArcade(app.buttons["patrol.start"], in: app)
        attach("Port Patrol")
        for index in 0..<18 {
            let packet = app.staticTexts["patrol.packet"].label
            let office = app.staticTexts["patrol.source"].label.hasPrefix("10.0.0.")
            let allow = packet == "TCP · 443" || (office && (index < 9 ? packet == "TCP · 22" : packet == "UDP · 53"))
            tapArcade(app.buttons[allow ? "patrol.allow" : "patrol.block"], in: app)
        }
        XCTAssertTrue(app.staticTexts["arcade.result"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["arcade.result"].label, "Shift complete")
        tapArcade(app.buttons["arcade.restart"], in: app)
        XCTAssertTrue(app.buttons["patrol.start"].exists)
    }


    func testPortPatrolSwipeInput() throws {
        let app = arcadeApp(); openGame("game.portPatrol", in: app)
        tapArcade(app.buttons["patrol.start"], in: app)
        for right in [true, false] {
            let packet = app.staticTexts["patrol.packet"]
            revealArcade(packet, in: app)
            let oldSource = app.staticTexts["patrol.source"].label
            let start = packet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: right ? 0.92 : 0.08, dy: packet.frame.midY / app.frame.height))
            start.press(forDuration: 0.01, thenDragTo: end)
            expectation(for: NSPredicate(format: "label != %@", oldSource), evaluatedWith: app.staticTexts["patrol.source"])
            waitForExpectations(timeout: 5)
        }
        attach("Port Patrol Swipe Input")
    }

    func testLoopBreakerSession() throws {
        let app = arcadeApp(); openGame("game.loopBreaker", in: app)
        XCTAssertTrue(app.buttons["loop.link.4"].waitForExistence(timeout: 5))
        attach("Loop Breaker")
        XCTAssertFalse(app.buttons["loop.test"].isEnabled)
        for link in [4, 5, 6] { tapArcade(app.buttons["loop.link.\(link)"], in: app) }
        tapArcade(app.buttons["loop.test"], in: app)
        XCTAssertFalse(app.buttons["loop.test"].isEnabled)
        tapArcade(app.buttons["loop.link.4"], in: app)
        tapArcade(app.buttons["loop.test"], in: app)
        XCTAssertTrue(app.staticTexts["arcade.result"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["arcade.result"].label, "Storm stopped")
        tapArcade(app.buttons["arcade.restart"], in: app)
        XCTAssertFalse(app.buttons["loop.test"].isEnabled)
    }

    func testDHCPDashSession() throws {
        let app = arcadeApp(); openGame("game.dhcpDash", in: app)
        XCTAssertTrue(app.buttons["dhcp.step.0"].waitForExistence(timeout: 5))
        attach("DHCP Dash")
        let pool = ["10.0.0.10", "10.0.0.11", "10.0.0.12"]
        for client in 0..<6 {
            tapArcade(app.buttons["dhcp.step.0"], in: app)
            let address = app.buttons["dhcp.address.\(pool[client % 3])"]
            if client >= 3 { tapArcade(address, in: app) }
            tapArcade(address, in: app)
            for step in 1...3 { tapArcade(app.buttons["dhcp.step.\(step)"], in: app) }
        }
        XCTAssertTrue(app.staticTexts["arcade.result"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["arcade.result"].label, "Everyone online")
        tapArcade(app.buttons["arcade.restart"], in: app)
        XCTAssertTrue(app.buttons["dhcp.step.0"].exists)
    }

    func testHandshakeHeroSession() throws {
        let app = arcadeApp(); openGame("game.handshakeHero", in: app)
        XCTAssertTrue(app.buttons["tcp.packet.SYN"].waitForExistence(timeout: 5))
        attach("Handshake Hero")
        for (sender, packet) in [("Client", "SYN"), ("Server", "SYN-ACK"), ("Client", "ACK"), ("Client", "DATA"), ("Client", "RETRY"), ("Server", "ACK"), ("Client", "DATA"), ("Server", "ACK")] {
            tapArcade(app.buttons["tcp.sender.\(sender)"], in: app)
            let action = app.buttons["tcp.packet.\(packet)"]
            expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: action)
            waitForExpectations(timeout: 5)
            tapArcade(action, in: app)
        }
        XCTAssertTrue(app.staticTexts["arcade.result"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["arcade.result"].label, "Reliable delivery")
        tapArcade(app.buttons["arcade.restart"], in: app)
        XCTAssertEqual(app.staticTexts["tcp.prompt"].label, "Client → SYN")
    }

    func testCLIFiveTaskSession() throws {
        let app = arcadeApp(); openGame("game.cliCrisis", in: app)
        let commands = [["ping", "-c", "4", "192.168.1.1"], ["nslookup", "example.com"], ["traceroute", "203.0.113.10"], ["ping", "-c", "1", "127.0.0.1"], ["nslookup", "example.com", "8.8.8.8"]]
        for (index, tokens) in commands.enumerated() {
            for token in tokens { app.buttons["Add \(token) to command"].tap() }
            app.buttons["Run"].tap()
            XCTAssertEqual(app.textFields.count, 0)
            if index < 4 { tapArcade(app.buttons["cli.next"], in: app) }
        }
        revealArcade(app.staticTexts["arcade.result"], in: app)
        XCTAssertEqual(app.staticTexts["arcade.result"].label, "CLI session complete")
        tapArcade(app.buttons["arcade.restart"], in: app)
        XCTAssertTrue(app.staticTexts["Check connectivity"].exists)
    }


    func testArcadeDarkLayouts() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-appAppearance", "dark", "-reelSoundsEnabled", "NO"]
        app.launch()
        for (id, title, control) in [("packetRush", "Packet Rush", "packet.start"), ("cableRescue", "Cable Rescue", "cable.probe.1"), ("portPatrol", "Port Patrol", "patrol.start"), ("handshakeHero", "Handshake Hero", "tcp.packet.SYN"), ("loopBreaker", "Loop Breaker", "loop.link.4"), ("dhcpDash", "DHCP Dash", "dhcp.step.0")] {
            openGame("game.\(id)", in: app)
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 5))
            XCTAssertTrue(app.buttons[control].exists)
            attach("\(title) Dark")
            revealArcade(app.buttons[control], in: app)
            XCTAssertTrue(app.buttons[control].isHittable)
            app.buttons["How to Play"].tap()
            XCTAssertTrue(app.navigationBars["How to Play"].waitForExistence(timeout: 5))
            app.buttons["Done"].tap()
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }

    func testArcadeLargeTextLayouts() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-appAppearance", "light", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        for (id, title, control) in [("packetRush", "Packet Rush", "packet.start"), ("cableRescue", "Cable Rescue", "cable.probe.1"), ("portPatrol", "Port Patrol", "patrol.start"), ("handshakeHero", "Handshake Hero", "tcp.packet.SYN"), ("loopBreaker", "Loop Breaker", "loop.link.4"), ("dhcpDash", "DHCP Dash", "dhcp.step.0")] {
            openGame("game.\(id)", in: app)
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 5))
            revealArcade(app.buttons[control], in: app)
            XCTAssertTrue(app.buttons[control].isHittable)
            attach("\(title) Large Text")
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }

    private func arcadeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-appAppearance", "light", "-reelSoundsEnabled", "NO"]
        app.launch()
        return app
    }

    private func tapArcade(_ element: XCUIElement, in app: XCUIApplication) {
        revealArcade(element, in: app)
        element.tap()
    }

    private func revealArcade(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<12 {
            let bank = app.otherElements["cli.bank"]
            let bottom = bank.exists && !element.identifier.hasPrefix("cli.next") ? bank.frame.minY - 8 : app.frame.maxY - 8
            if element.exists && element.isHittable && element.frame.minY > app.navigationBars.firstMatch.frame.maxY && element.frame.maxY < bottom { return }
            if element.exists && element.frame.minY < app.navigationBars.firstMatch.frame.maxY { app.scrollViews.firstMatch.swipeDown() }
            else { app.scrollViews.firstMatch.swipeUp() }
        }
        XCTAssertTrue(element.isHittable, app.debugDescription)
    }

    private func openGame(_ identifier: String, in app: XCUIApplication) {
        XCTAssertTrue(app.navigationBars["Root Roller"].waitForExistence(timeout: 10))
        let button = app.buttons[identifier]
        for _ in 0..<16 {
            if button.exists && button.isHittable && button.frame.midY < app.frame.maxY - 40 { break }
            scrollHubUp(app)
        }
        XCTAssertTrue(button.exists)
        button.tap()
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<10 {
            if element.exists && element.isHittable && element.frame.maxY < app.frame.maxY - 35 { return }
            scrollHubUp(app)
        }
        XCTAssertTrue(element.isHittable, app.debugDescription)
    }

    // The center of the hub contains the draggable drum; scroll from its gutter.
    private func scrollHubUp(_ app: XCUIApplication) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.80))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.25))
        start.press(forDuration: 0.01, thenDragTo: end)
    }

    /// Sample the Form's empty left gutter to verify appearance actually renders.
    private func sheetBackgroundBrightness() -> Double {
        let image = XCUIScreen.main.screenshot().image.cgImage!
        var pixel = [UInt8](repeating: 0, count: 4)
        pixel.withUnsafeMutableBytes { bytes in
            let context = CGContext(data: bytes.baseAddress, width: 1, height: 1,
                                    bitsPerComponent: 8, bytesPerRow: 4,
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.interpolationQuality = .none
            context.draw(image, in: CGRect(x: -10, y: -image.height / 2, width: image.width, height: image.height))
        }
        return (Double(pixel[0]) + Double(pixel[1]) + Double(pixel[2])) / (3 * 255)
    }

    private func attach(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
