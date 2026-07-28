import Foundation

enum ChartStatus: String, Codable, CaseIterable, Hashable {
    case draft
    case active
    case finished

    var sectionTitle: String {
        switch self {
        case .active: return "In progress"
        case .draft: return "Drafts"
        case .finished: return "Finished"
        }
    }
}

struct ChartColor: Codable, Hashable, Identifiable {
    var colorIndex: Int
    var dmcCode: String
    var symbol: String
    var stitchCount: Int

    var id: Int { colorIndex }
}

/// One cross-stitch chart. `cells` is a row-major byte array of palette indices;
/// every cell always references a palette color (blank charts start fully filled
/// with the fabric color, DMC Blanc), so progress denominator stays width × height.
struct Chart: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var title: String
    var sourcePhotoPath: String?
    var finishedPhotoPath: String?
    var widthCells: Int
    var heightCells: Int
    var maxColors: Int
    var cells: Data
    var palette: [ChartColor]
    var status: ChartStatus = .draft
    var stitchedCellIndices: Set<Int> = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var totalCells: Int { widthCells * heightCells }

    var progress: Double {
        guard totalCells > 0 else { return 0 }
        return Double(stitchedCellIndices.count) / Double(totalCells)
    }

    var stitchedCount: Int { stitchedCellIndices.count }

    func colorIndex(at cellIndex: Int) -> Int {
        guard cellIndex >= 0, cellIndex < cells.count else { return 0 }
        return Int(cells[cellIndex])
    }

    func paletteColor(at cellIndex: Int) -> ChartColor? {
        let idx = colorIndex(at: cellIndex)
        return palette.first(where: { $0.colorIndex == idx })
    }

    func isStitched(_ cellIndex: Int) -> Bool {
        stitchedCellIndices.contains(cellIndex)
    }

    static func cellIndex(row: Int, column: Int, width: Int) -> Int {
        row * width + column
    }

    static func row(of cellIndex: Int, width: Int) -> Int { cellIndex / width }
    static func column(of cellIndex: Int, width: Int) -> Int { cellIndex % width }

    /// Recomputes per-color stitch counts from the cell grid. Editor calls this
    /// after every mutation so palette counts stay in sync (ACC-004).
    mutating func recomputeStitchCounts() {
        var counts = [Int: Int]()
        for byte in cells {
            counts[Int(byte), default: 0] += 1
        }
        palette = palette.map { color in
            var copy = color
            copy.stitchCount = counts[color.colorIndex] ?? 0
            return copy
        }
    }
}
