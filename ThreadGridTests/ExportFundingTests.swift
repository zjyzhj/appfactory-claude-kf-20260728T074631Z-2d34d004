import XCTest
import Foundation
@testable import ThreadGrid

/// Focused coverage for checklist §9: ExportRecord persists the StoreKit
/// transaction that funded the deduction (bug b-14320aed1ab3).
final class ExportFundingTests: XCTestCase {

    @MainActor
    private func makeStore() -> AppStore {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        return AppStore(localStore: LocalStore(baseDirectory: tempDir))
    }

    @MainActor
    func testPurchaseFundedPDFExportCarriesStorekitTransactionId() {
        let store = makeStore()
        // Fresh store auto-grants the welcome balance; add a purchase on top.
        store.creditPurchase(amount: 110, storekitTransactionId: "txn-funding-1")

        let fundingId = store.fundingStorekitTransactionIdForNextSpend
        XCTAssertEqual(fundingId, "txn-funding-1")

        // Mirror ChartExportView.exportPDF: capture funding id, then consume.
        store.consumeCredits(CreditCatalog.printablePDFCost, note: "Printable PDF · test")
        store.recordExport(chartId: UUID(), kind: .printablePDF, storekitTransactionId: fundingId)

        let record = store.exportRecords.last
        XCTAssertEqual(record?.kind, .printablePDF)
        XCTAssertEqual(record?.storekitTransactionId, "txn-funding-1")
    }

    @MainActor
    func testGrantFundedSpendHasNoStorekitTransactionId() {
        let store = makeStore()
        // Only the initial grant exists, so the next spend is grant-funded.
        XCTAssertNil(store.fundingStorekitTransactionIdForNextSpend)

        store.consumeCredits(CreditCatalog.printablePDFCost, note: "Printable PDF · test")
        store.recordExport(
            chartId: UUID(),
            kind: .printablePDF,
            storekitTransactionId: store.fundingStorekitTransactionIdForNextSpend
        )
        XCTAssertNil(store.exportRecords.last?.storekitTransactionId)
    }

    @MainActor
    func testFreeImageCardExportRecordsWithoutTransactionId() {
        let store = makeStore()
        store.creditPurchase(amount: 110, storekitTransactionId: "txn-funding-2")
        // Result card is free: no deduction, no funding attribution.
        store.recordExport(chartId: UUID(), kind: .imageCard)
        XCTAssertNil(store.exportRecords.last?.storekitTransactionId)
    }

    func testFundingFallsBackToNilOncePurchasedCreditsAreSpent() {
        var ledger = CreditLedger()
        ledger.apply(CreditTxn(kind: .grant, amount: 100, note: "Welcome credits", storekitTransactionId: nil))
        ledger.apply(CreditTxn(kind: .purchase, amount: 1, note: "Credit pack", storekitTransactionId: "txn-funding-3"))
        XCTAssertEqual(ledger.fundingStorekitTransactionIdForNextSpend, "txn-funding-3")
        ledger.apply(CreditTxn(kind: .consume, amount: -1, note: "PDF", storekitTransactionId: nil))
        // Purchased balance exhausted; remaining grant credits fund the next spend.
        XCTAssertNil(ledger.fundingStorekitTransactionIdForNextSpend)
    }

    func testLegacyExportRecordWithoutTransactionIdStillDecodes() throws {
        // Shape persisted before storekitTransactionId existed.
        let legacyJSON = """
        {
            "id": "4C6F6C8C-7E2D-4C2C-9E7C-6F0E0E9B2E11",
            "chartId": "8A6F6C8C-7E2D-4C2C-9E7C-6F0E0E9B2E22",
            "kind": "printable_pdf",
            "createdAt": "2026-07-28T10:00:00Z"
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let record = try decoder.decode(ExportRecord.self, from: legacyJSON)
        XCTAssertEqual(record.kind, .printablePDF)
        XCTAssertNil(record.storekitTransactionId)
    }

    func testLegacyPersistedStateWithoutTransactionIdStillDecodes() throws {
        // Full pre-patch store.json: exportRecords entries lack the new field.
        let legacyJSON = """
        {
            "charts": [],
            "stash": {},
            "ledger": { "balance": 99, "transactions": [] },
            "exportRecords": [
                {
                    "id": "4C6F6C8C-7E2D-4C2C-9E7C-6F0E0E9B2E11",
                    "chartId": "8A6F6C8C-7E2D-4C2C-9E7C-6F0E0E9B2E22",
                    "kind": "image_card",
                    "createdAt": "2026-07-28T10:00:00Z"
                }
            ],
            "activeChartId": null,
            "hasGrantedInitialCredits": true
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let state = try decoder.decode(PersistedState.self, from: legacyJSON)
        XCTAssertEqual(state.exportRecords.count, 1)
        XCTAssertNil(state.exportRecords.first?.storekitTransactionId)
    }
}
