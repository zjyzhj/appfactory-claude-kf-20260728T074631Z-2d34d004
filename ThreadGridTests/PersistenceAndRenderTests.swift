import XCTest
import UIKit
@testable import ThreadGrid

final class PersistenceAndRenderTests: XCTestCase {

    private func makeChart() -> Chart {
        let result = ChartQuantizer.blank(widthCells: 12, heightCells: 9)
        return Chart(
            title: "Test chart",
            widthCells: 12,
            heightCells: 9,
            maxColors: 4,
            cells: result.cells,
            palette: result.palette,
            status: .draft,
            stitchedCellIndices: [0, 5, 12]
        )
    }

    func testLocalStoreRoundTrip() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = LocalStore(baseDirectory: tempDir)
        let chart = makeChart()
        let state = PersistedState(
            charts: [chart],
            stash: ["310": 2],
            ledger: CreditLedger(balance: 7, transactions: []),
            exportRecords: [ExportRecord(chartId: chart.id, kind: .imageCard)],
            activeChartId: chart.id,
            hasGrantedInitialCredits: true
        )
        try store.save(state)
        let loaded = try XCTUnwrap(try store.load())
        XCTAssertEqual(loaded.charts.first?.title, "Test chart")
        XCTAssertEqual(loaded.charts.first?.stitchedCellIndices, [0, 5, 12])
        XCTAssertEqual(loaded.stash["310"], 2)
        XCTAssertEqual(loaded.ledger.balance, 7)
        XCTAssertEqual(loaded.exportRecords.count, 1)
        XCTAssertEqual(loaded.activeChartId, chart.id)
    }

    func testRendererProducesNonEmptyImage() {
        let chart = makeChart()
        let image = ChartRenderer.image(chart: chart, style: .thumbnail)
        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
    }

    func testResultCardAndPDFRender() {
        var chart = makeChart()
        chart.palette.append(ChartColor(colorIndex: 1, dmcCode: "310", symbol: "✕", stitchCount: 10))
        let card = ExportEngine.makeResultCard(chart: chart, finishedPhoto: nil)
        XCTAssertGreaterThan(card.size.width, 0)
        let pdf = ExportEngine.makePrintablePDF(chart: chart)
        XCTAssertGreaterThan(pdf.count, 1000, "PDF should carry real pages")
        // PDF magic bytes.
        XCTAssertEqual(String(data: pdf.prefix(5), encoding: .ascii), "%PDF-")
    }

    func testStitchProgressDerivation() {
        var chart = makeChart()
        XCTAssertEqual(chart.totalCells, 108)
        XCTAssertEqual(chart.progress, 3.0 / 108.0, accuracy: 0.0001)
        chart.stitchedCellIndices = Set(0..<108)
        XCTAssertEqual(chart.progress, 1.0, accuracy: 0.0001)
    }
}
