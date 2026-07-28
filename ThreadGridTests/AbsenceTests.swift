import XCTest

/// Focused absence tests (checklist §14/§15): the app declares no microphone
/// and no tracking anywhere, plus the privacy manifest matches.
final class AbsenceTests: XCTestCase {

    private var appInfo: [String: Any] {
        Bundle.main.infoDictionary ?? [:]
    }

    func testNoMicrophoneUsageDescription() {
        XCTAssertNil(appInfo["NSMicrophoneUsageDescription"], "Mic key must be absent — the app has no audio workflows")
    }

    func testNoUserTrackingUsageDescription() {
        XCTAssertNil(appInfo["NSUserTrackingUsageDescription"], "ATT key must be absent — the app does not track")
    }

    func testRequiredPermissionKeysPresentWithProductCopy() {
        XCTAssertEqual(
            appInfo["NSCameraUsageDescription"] as? String,
            "Take a photo to turn into a stitch chart, or snap your finished piece. Photos stay on this device."
        )
        XCTAssertEqual(
            appInfo["NSPhotoLibraryUsageDescription"] as? String,
            "Pick a photo from your library to convert into a stitch chart. Photos are only read on this device."
        )
        XCTAssertEqual(
            appInfo["NSPhotoLibraryAddUsageDescription"] as? String,
            "Save your stitched result card to Photos so you can print or share it."
        )
    }

    func testPrivacyManifestDeclaresNoTracking() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let data = try Data(contentsOf: url)
        let plist = try XCTUnwrap(try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
        XCTAssertEqual(plist["NSPrivacyTracking"] as? Bool, false)
        let domains = plist["NSPrivacyTrackingDomains"] as? [String] ?? []
        XCTAssertTrue(domains.isEmpty)
        let collected = plist["NSPrivacyCollectedDataTypes"] as? [Any] ?? []
        XCTAssertTrue(collected.isEmpty)
    }
}
