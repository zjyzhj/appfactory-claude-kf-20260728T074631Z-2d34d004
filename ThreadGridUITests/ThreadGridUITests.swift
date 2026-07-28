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

    /// Checklist §9 export-route smoke: seed a purchase-funded ledger, export a
    /// printable PDF through the real UI route, then read back the persisted
    /// store.json and assert the ExportRecord carries the funding
    /// storekitTransactionId (bug b-14320aed1ab3).
    @MainActor
    func testPDFExportRouteRecordsFundingTransaction() throws {
        try Self.seedAppContainerWithPurchaseFundedState()

        let app = XCUIApplication()
        app.launch()

        // Seeded chart card opens the detail (card label combines title + meta).
        let card = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Smoke Sampler'")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10), "seeded chart should appear in the library")
        card.tap()

        // Detail → export sheet → printable PDF row.
        let exportButton = app.buttons["Export"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 8))
        exportButton.tap()

        let pdfRow = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Printable Chart PDF'")).firstMatch
        XCTAssertTrue(pdfRow.waitForExistence(timeout: 8))
        pdfRow.tap()

        // PDF renders on a detached task; success banner appears under the share sheet.
        XCTAssertTrue(
            app.staticTexts["Your printable chart is ready."].waitForExistence(timeout: 20),
            "PDF export route should reach the success state"
        )

        // Read back the persisted state: the new ExportRecord must trace to the
        // seeded purchase transaction.
        let storeURL = try Self.appStoreFileURL()
        let data = try Data(contentsOf: storeURL)
        let persisted = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let records = try XCTUnwrap(persisted["exportRecords"] as? [[String: Any]])
        let pdfRecord = records.last(where: { $0["kind"] as? String == "printable_pdf" })
        XCTAssertEqual(
            pdfRecord?["storekitTransactionId"] as? String,
            "smoke-funding-txn-001",
            "PDF export record must carry the funding StoreKit transaction id"
        )
        let ledger = try XCTUnwrap(persisted["ledger"] as? [String: Any])
        XCTAssertEqual(ledger["balance"] as? Int, 209, "1 credit deducted after successful render")

        // Keep the post-export store.json as a test attachment for QA readback.
        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")
        attachment.name = "store-after-pdf-export.json"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

extension ThreadGridUITests {
    /// Seeded state: one active chart plus a ledger whose newest purchase
    /// (storekitTransactionId "smoke-funding-txn-001") funds the next spend.
    /// Generated with the app's own Codable models (Chart/Credits).
    static let seedStoreJSON = """
    {
      "activeChartId" : null,
      "charts" : [
        {
          "cells" : "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
          "createdAt" : "2026-07-28T12:00:00Z",
          "heightCells" : 9,
          "id" : "1A2B3C4D-5E6F-4A5B-8C9D-0E1F2A3B4C5D",
          "maxColors" : 4,
          "palette" : [
            {
              "colorIndex" : 0,
              "dmcCode" : "Blanc",
              "stitchCount" : 108,
              "symbol" : "·"
            }
          ],
          "status" : "active",
          "stitchedCellIndices" : [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46],
          "title" : "Smoke Sampler",
          "updatedAt" : "2026-07-28T12:00:00Z",
          "widthCells" : 12
        }
      ],
      "exportRecords" : [],
      "hasGrantedInitialCredits" : true,
      "ledger" : {
        "balance" : 210,
        "transactions" : [
          {
            "amount" : 100,
            "createdAt" : "2026-07-28T12:00:00Z",
            "id" : "2A2B3C4D-5E6F-4A5B-8C9D-0E1F2A3B4C5D",
            "kind" : "grant",
            "note" : "Welcome credits"
          },
          {
            "amount" : 110,
            "createdAt" : "2026-07-28T12:00:00Z",
            "id" : "3A2B3C4D-5E6F-4A5B-8C9D-0E1F2A3B4C5D",
            "kind" : "purchase",
            "note" : "Credit pack",
            "storekitTransactionId" : "smoke-funding-txn-001"
          }
        ]
      },
      "stash" : {}
    }
    """

    /// Locates the ThreadGrid app data container on this Simulator by scanning
    /// sibling containers of the test runner (Simulator does not enforce the
    /// data-container sandbox between same-user processes).
    static func appContainerURL() throws -> URL {
        let fileManager = FileManager.default
        let applicationsDir = URL(fileURLWithPath: NSHomeDirectory()).deletingLastPathComponent()
        let candidates = try fileManager.contentsOfDirectory(at: applicationsDir, includingPropertiesForKeys: nil)
        for dir in candidates {
            let metadataURL = dir.appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist")
            guard let metadata = NSDictionary(contentsOf: metadataURL),
                  metadata["MCMMetadataIdentifier"] as? String == "com.threadgrid.atelier" else { continue }
            return dir
        }
        throw XCTSkip("ThreadGrid app container not found next to \(applicationsDir.path)")
    }

    static func appStoreFileURL() throws -> URL {
        try appContainerURL()
            .appendingPathComponent("Library/Application Support/ThreadGrid", isDirectory: true)
            .appendingPathComponent("store.json")
    }

    static func seedAppContainerWithPurchaseFundedState() throws {
        let storeURL = try appStoreFileURL()
        try FileManager.default.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try seedStoreJSON.write(to: storeURL, atomically: true, encoding: .utf8)
    }
}
