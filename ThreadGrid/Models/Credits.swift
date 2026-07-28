import Foundation

enum CreditTxnKind: String, Codable, Hashable {
    case purchase
    case consume
    case grant
}

struct CreditTxn: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var kind: CreditTxnKind
    var amount: Int
    var note: String
    var storekitTransactionId: String?
    var createdAt: Date = Date()
}

struct CreditLedger: Codable, Hashable {
    var balance: Int = 0
    var transactions: [CreditTxn] = []

    mutating func apply(_ txn: CreditTxn) {
        transactions.append(txn)
        balance += txn.amount
        if balance < 0 { balance = 0 }
    }
}

enum ExportKind: String, Codable, Hashable {
    case imageCard = "image_card"
    case printablePDF = "printable_pdf"
}

struct ExportRecord: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var chartId: UUID
    var kind: ExportKind
    var createdAt: Date = Date()
}

/// yanran consumable balance catalog — the only permitted IAP model.
/// Values mirror agents/FinalGateAgent/data-contracts/iap/yanran.json verbatim
/// (sha256 b6b737ce…). Product IDs are internal only and never shown in UI.
enum CreditCatalog {
    struct Product: Hashable, Identifiable {
        let productID: String
        let amount: Int
        let referencePrice: String
        let promotion: Bool

        var id: String { productID }
    }

    static let initialBalance = 100

    static let products: [Product] = [
        Product(productID: "473900", amount: 110, referencePrice: "$0.99", promotion: false),
        Product(productID: "473901", amount: 210, referencePrice: "$1.99", promotion: false),
        Product(productID: "473902", amount: 310, referencePrice: "$2.99", promotion: false),
        Product(productID: "473903", amount: 400, referencePrice: "$3.99", promotion: false),
        Product(productID: "473904", amount: 520, referencePrice: "$4.99", promotion: false),
        Product(productID: "473905", amount: 630, referencePrice: "$5.99", promotion: false),
        Product(productID: "473906", amount: 740, referencePrice: "$6.99", promotion: false),
        Product(productID: "473907", amount: 1000, referencePrice: "$8.99", promotion: false),
        Product(productID: "473908", amount: 1200, referencePrice: "$9.99", promotion: false),
        Product(productID: "473909", amount: 1600, referencePrice: "$12.99", promotion: false),
        Product(productID: "473910", amount: 2000, referencePrice: "$15.99", promotion: false),
        Product(productID: "473911", amount: 2600, referencePrice: "$19.99", promotion: false),
        Product(productID: "473912", amount: 3300, referencePrice: "$24.99", promotion: false),
        Product(productID: "473913", amount: 4200, referencePrice: "$29.99", promotion: false),
        Product(productID: "473914", amount: 4900, referencePrice: "$34.99", promotion: false),
        Product(productID: "473915", amount: 6000, referencePrice: "$39.99", promotion: false),
        Product(productID: "473916", amount: 8000, referencePrice: "$49.99", promotion: false),
        Product(productID: "473917", amount: 14000, referencePrice: "$79.99", promotion: false),
        Product(productID: "473918", amount: 14998, referencePrice: "$99.99", promotion: false),
        Product(productID: "473919", amount: 520, referencePrice: "$1.99", promotion: true),
        Product(productID: "473920", amount: 800, referencePrice: "$2.99", promotion: true),
        Product(productID: "473921", amount: 1300, referencePrice: "$4.99", promotion: true),
        Product(productID: "473922", amount: 1500, referencePrice: "$5.99", promotion: true),
        Product(productID: "473923", amount: 2700, referencePrice: "$11.99", promotion: true),
        Product(productID: "473924", amount: 2900, referencePrice: "$12.99", promotion: true),
        Product(productID: "473925", amount: 7200, referencePrice: "$34.99", promotion: true),
        Product(productID: "473926", amount: 17000, referencePrice: "$79.99", promotion: true),
    ]

    static func product(for productID: String) -> Product? {
        products.first(where: { $0.productID == productID })
    }

    /// Curated tiers surfaced in the shop UI; every row is a verbatim catalog entry.
    /// Standard packs first, then special-offer packs, cheapest first.
    static var displayedProducts: [Product] {
        let standard = products.filter { !$0.promotion }
        let offers = products.filter { $0.promotion }
        return Array(standard.prefix(9)) + Array(offers.prefix(4))
    }

    /// Cost of one printable chart PDF, in credits.
    static let printablePDFCost = 1
}
