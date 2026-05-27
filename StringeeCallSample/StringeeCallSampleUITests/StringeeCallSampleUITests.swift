import XCTest

final class StringeeCallSampleUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testConnectStartVoiceCallAndEnd() throws {
        let app = launchFakeApp()

        type("token-user-a", into: app.textFields["accessTokenTextField"])
        app.buttons["connectButton"].tap()

        XCTAssertTrue(app.staticTexts["Connected as demo-user"].waitForExistence(timeout: 2))

        type("user-b", into: app.textFields["calleeTextField"])
        app.buttons["startCallButton"].tap()

        XCTAssertTrue(app.staticTexts["Calling user-b"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["endCallButton"].exists)

        app.buttons["endCallButton"].tap()
        XCTAssertTrue(app.buttons["startCallButton"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testStartVideoCallShowsVideoSurfacesAndCameraControl() throws {
        let app = launchFakeApp()
        connect(app)

        app.segmentedControls["callKindSegmentedControl"].buttons["Video"].tap()
        type("user-b", into: app.textFields["calleeTextField"])
        app.buttons["startCallButton"].tap()

        XCTAssertTrue(app.otherElements["remoteVideoContainer"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.otherElements["localVideoContainer"].exists)
        XCTAssertTrue(app.buttons["cameraButton"].exists)
    }

    @MainActor
    func testIncomingCallCanBeAnsweredAndRejected() throws {
        let app = launchFakeApp()
        connect(app)

        app.buttons["simulateIncomingVoiceButton"].tap()
        XCTAssertTrue(app.staticTexts["Incoming call from demo-caller"].waitForExistence(timeout: 2))

        app.buttons["answerCallButton"].tap()
        XCTAssertTrue(app.buttons["endCallButton"].waitForExistence(timeout: 2))
        app.buttons["endCallButton"].tap()

        app.buttons["simulateIncomingVideoButton"].tap()
        XCTAssertTrue(app.staticTexts["Incoming call from demo-caller"].waitForExistence(timeout: 2))
        app.buttons["rejectCallButton"].tap()
        XCTAssertTrue(app.buttons["startCallButton"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testSimulatedVoIPPushCanBeAnswered() throws {
        let app = launchFakeApp()
        connect(app)

        app.buttons["simulateVoIPPushButton"].tap()
        XCTAssertTrue(app.staticTexts["Incoming call from demo-caller"].waitForExistence(timeout: 2))

        app.buttons["answerCallButton"].tap()
        XCTAssertTrue(app.buttons["endCallButton"].waitForExistence(timeout: 2))
        app.buttons["endCallButton"].tap()
        XCTAssertTrue(app.buttons["startCallButton"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            _ = launchFakeApp()
        }
    }

    @MainActor
    private func launchFakeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-fake-stringee"]
        app.launch()
        return app
    }

    @MainActor
    private func connect(_ app: XCUIApplication) {
        type("token-user-a", into: app.textFields["accessTokenTextField"])
        app.buttons["connectButton"].tap()
        XCTAssertTrue(app.staticTexts["Connected as demo-user"].waitForExistence(timeout: 2))
    }

    @MainActor
    private func type(_ text: String, into field: XCUIElement) {
        XCTAssertTrue(field.waitForExistence(timeout: 2))
        XCTAssertTrue(field.isHittable)
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let clearButton = field.buttons["Clear text"]
        if clearButton.exists {
            clearButton.tap()
        }
        field.typeText(text)
    }
}
