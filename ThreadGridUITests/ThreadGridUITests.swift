import XCTest

/// End-to-end smoke: the checklist's L1 create path (ACC-001/002/003/012),
/// driven through the deterministic Simulator capture seam (checklist §12).
final class ThreadGridUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTabSwitchingRendersEveryRoot() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Create"].waitForExistence(timeout: 8))
        app.tabBars.buttons["Create"].tap()
        XCTAssertTrue(app.staticTexts["Start a new pattern"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Stitch"].tap()
        XCTAssertTrue(
            app.staticTexts["Nothing on the hoop yet"].waitForExistence(timeout: 5)
                || app.staticTexts["Pick a chart to stitch"].waitForExistence(timeout: 1)
        )

        app.tabBars.buttons["Threads"].tap()
        XCTAssertTrue(app.navigationBars["Threads"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Charts"].tap()
        XCTAssertTrue(app.tabBars.buttons["Charts"].isSelected)
    }

    @MainActor
    func testCreateChartThroughCameraSeam() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-syntheticCapture"]
        app.launch()

        // Empty library → CTA; non-empty → go straight to the Create tab.
        let emptyCTA = app.buttons["Create your first chart"]
        if emptyCTA.waitForExistence(timeout: 5) {
            emptyCTA.tap()
        } else {
            app.tabBars.buttons["Create"].tap()
        }

        // Camera permission prompt (JIT, record-bound) — accept if shown.
        addUIInterruptionMonitor(withDescription: "Camera permission") { alert in
            for label in ["Allow", "OK", "Allow Full Access"] {
                if alert.buttons[label].exists {
                    alert.buttons[label].tap()
                    return true
                }
            }
            return false
        }

        let takePhoto = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Take a photo'")).firstMatch
        XCTAssertTrue(takePhoto.waitForExistence(timeout: 8))
        takePhoto.tap()
        app.tap() // nudge the interruption monitor

        // Deterministic permission handling: poll for the JIT alert directly.
        let allowButton = app.alerts.buttons["Allow"]
        if allowButton.waitForExistence(timeout: 5) {
            allowButton.tap()
        }

        // Deterministic capture seam: synthetic photo binds to the wizard.
        // (If a device routes to the hardware picker instead, capture through it.)
        let usePhoto = app.buttons["Use this photo"]
        if !usePhoto.waitForExistence(timeout: 8) {
            let shutter = app.buttons["PhotoCapture"]
            XCTAssertTrue(shutter.waitForExistence(timeout: 5), "expected synthetic seam or camera picker")
            shutter.tap()
            let useCaptured = app.buttons["Use Photo"]
            XCTAssertTrue(useCaptured.waitForExistence(timeout: 5))
            useCaptured.tap()
        } else {
            usePhoto.tap()
        }

        // Tuning: sliders re-render the preview; continue when ready.
        let continueButton = app.buttons["Looks good, continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 15))
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()

        // Naming sheet.
        let nameField = app.textFields["Chart name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Smoke Fox")
        app.buttons["Save chart"].tap()

        // Saved chart appears (detail opens via cross-tab handoff).
        let saved = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Smoke Fox'")).firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: 15))
    }
}
