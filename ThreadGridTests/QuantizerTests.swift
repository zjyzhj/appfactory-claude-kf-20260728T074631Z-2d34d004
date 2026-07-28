import XCTest
import UIKit
@testable import ThreadGrid

final class QuantizerTests: XCTestCase {

    private func makeTestImage(size: CGSize = CGSize(width: 120, height: 90)) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: size.width / 2, height: size.height))
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: size.width / 2, y: 0, width: size.width / 2, height: size.height))
        }
    }

    func testQuantizeProducesFullGridWithinColorBudget() {
        let result = ChartQuantizer.quantize(image: makeTestImage(), widthCells: 40, heightCells: 30, maxColors: 8)
        XCTAssertEqual(result.cells.count, 40 * 30)
        XCTAssertFalse(result.palette.isEmpty)
        XCTAssertLessThanOrEqual(result.palette.count, 8)
        let paletteIndices = Set(result.palette.map(\.colorIndex))
        for byte in result.cells {
            XCTAssertTrue(paletteIndices.contains(Int(byte)), "every cell references a palette color")
        }
        // Every palette DMC code exists in the library.
        for color in result.palette {
            XCTAssertNotNil(DMCLibrary.shared.thread(for: color.dmcCode))
        }
    }

    func testQuantizeIsDeterministic() {
        let image = makeTestImage()
        let a = ChartQuantizer.quantize(image: image, widthCells: 32, heightCells: 32, maxColors: 6)
        let b = ChartQuantizer.quantize(image: image, widthCells: 32, heightCells: 32, maxColors: 6)
        XCTAssertEqual(a.cells, b.cells)
        XCTAssertEqual(a.palette, b.palette)
    }

    func testPaletteIsUniquePerDMCCode() {
        let result = ChartQuantizer.quantize(image: SamplePhotoFactory.makeStitchSample(), widthCells: 48, heightCells: 48, maxColors: 16)
        let codes = result.palette.map(\.dmcCode)
        XCTAssertEqual(Set(codes).count, codes.count, "palette must dedupe clusters landing on the same floss")
    }

    func testBlankChartIsFullyFilledFabric() {
        let result = ChartQuantizer.blank(widthCells: 30, heightCells: 45)
        XCTAssertEqual(result.cells.count, 30 * 45)
        XCTAssertEqual(result.palette.count, 1)
        XCTAssertEqual(result.palette.first?.dmcCode, "Blanc")
        XCTAssertTrue(result.cells.allSatisfy { $0 == 0 })
    }

    func testLibraryLoadsBundledThreads() {
        XCTAssertGreaterThan(DMCLibrary.shared.threads.count, 200)
        XCTAssertEqual(DMCLibrary.shared.thread(for: "310")?.name, "Black")
        XCTAssertNotNil(DMCLibrary.shared.thread(for: "Blanc"))
    }
}
