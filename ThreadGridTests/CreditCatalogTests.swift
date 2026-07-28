import XCTest
@testable import ThreadGrid

final class CreditCatalogTests: XCTestCase {

    func testCatalogVerbatimYanranProducts() {
        XCTAssertEqual(CreditCatalog.products.count, 27)
        XCTAssertEqual(CreditCatalog.initialBalance, 100)
        // Spot-check verbatim id/amount pairs across the range.
        let expectations: [(String, Int)] = [
            ("473900", 110), ("473907", 1000), ("473913", 4200),
            ("473918", 14998), ("473919", 520), ("473926", 17000),
        ]
        for (id, amount) in expectations {
            XCTAssertEqual(CreditCatalog.product(for: id)?.amount, amount, "yanran amount must match verbatim for \(id)")
        }
        // IDs are contiguous 473900…473926.
        for i in 0..<27 {
            XCTAssertNotNil(CreditCatalog.product(for: "4739\(String(format: "%02d", i))"))
        }
    }

    func testLedgerGrantPurchaseConsume() {
        var ledger = CreditLedger()
        ledger.apply(CreditTxn(kind: .grant, amount: CreditCatalog.initialBalance, note: "Welcome credits", storekitTransactionId: nil))
        XCTAssertEqual(ledger.balance, 100)

        ledger.apply(CreditTxn(kind: .purchase, amount: 110, note: "Credit pack", storekitTransactionId: "1000000123456789"))
        XCTAssertEqual(ledger.balance, 210)
        XCTAssertEqual(ledger.transactions.last?.storekitTransactionId, "1000000123456789")

        ledger.apply(CreditTxn(kind: .consume, amount: -1, note: "Printable PDF", storekitTransactionId: nil))
        XCTAssertEqual(ledger.balance, 209)
        XCTAssertEqual(ledger.transactions.count, 3)
    }

    func testConsumeNeverDropsBalanceBelowZero() {
        var ledger = CreditLedger()
        ledger.apply(CreditTxn(kind: .consume, amount: -5, note: "Printable PDF", storekitTransactionId: nil))
        XCTAssertEqual(ledger.balance, 0)
    }
}
