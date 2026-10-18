import XCTest

final class POCKETUITests:XCTestCase {
    override func setUpWithError() throws {continueAfterFailure=false;XCUIDevice.shared.orientation = .portrait}
    func testLearnOpensAWorkingInstrument() throws {
        let app=XCUIApplication();app.launchArguments=["-preview","learn"];app.launch()
        XCTAssertTrue(app.buttons["Continue learning"].waitForExistence(timeout:10))
        app.buttons["Continue learning"].tap()
        let pads=app.buttons["Go straight to the pads"]
        for _ in 0..<4 {if pads.isHittable {break};app.swipeUp()}
        XCTAssertTrue(pads.isHittable);pads.tap()
        XCTAssertTrue(app.buttons["Pad 1, Kick"].waitForExistence(timeout:5))
        XCTAssertTrue(app.staticTexts["AUDIO READY"].exists)
        app.buttons["Start practice"].tap()
        XCTAssertTrue(app.buttons["Stop"].waitForExistence(timeout:3))
        app.buttons["Pad 1, Kick"].tap()
        app.buttons["Stop"].tap()
        XCTAssertTrue(app.buttons["Start practice"].exists)
    }
    func testRecordReplayAndLandscapePadTargets() throws {
        let app=XCUIApplication();app.launchArguments=["-preview","play"];app.launch()
        XCTAssertTrue(app.buttons["Record a take"].waitForExistence(timeout:10))
        app.buttons["Record a take"].tap()
        sleep(5)
        app.buttons["Pad 1, Kick"].tap();app.buttons["Pad 6, Snare"].tap();app.buttons["Pad 8, Closed hi-hat"].tap()
        app.buttons["Stop"].tap()
        let saved=app.buttons.matching(NSPredicate(format:"label BEGINSWITH %@","Saved takes")).firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout:3));saved.tap()
        let replay=app.buttons["Replay Free play"]
        XCTAssertTrue(replay.waitForExistence(timeout:3));replay.tap()
        XCTAssertTrue(app.buttons["Stop"].waitForExistence(timeout:3));app.buttons["Stop"].tap()
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(1)
        let pad=app.buttons["Pad 1, Kick"]
        XCTAssertGreaterThanOrEqual(pad.frame.height,44);XCTAssertGreaterThanOrEqual(pad.frame.width,44)
        XCTAssertTrue(app.buttons["Pad 16, Low tom"].isHittable)
        let screen=XCTAttachment(screenshot:app.screenshot());screen.name="Landscape instrument";screen.lifetime = .keepAlways;add(screen)
    }
}
