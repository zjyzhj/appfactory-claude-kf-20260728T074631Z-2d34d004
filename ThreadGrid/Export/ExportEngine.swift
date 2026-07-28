import Foundation
import UIKit
import CoreGraphics

/// Export artifacts (F9/F10): the free result card image and the printable
/// multi-page PDF (symbol chart tiles + DMC thread list + symbol key).
enum ExportEngine {

    /// Rounded-serif display face used across card and PDF titles.
    static func serifFont(size: CGFloat, weight: UIFont.Weight = .semibold) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        if let descriptor = base.fontDescriptor.withDesign(.serif) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return base
    }

    // MARK: - Result card (free)

    static func makeResultCard(chart: Chart, finishedPhoto: UIImage?, library: DMCLibrary = .shared) -> UIImage {
        let cardSize = CGSize(width: 1200, height: 1500)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: cardSize, format: format).image { ctx in
            let context = ctx.cgContext

            // Linen ground + stitched border.
            UIColor(hexString: "#F5EFE4").setFill()
            context.fill(CGRect(origin: .zero, size: cardSize))
            UIColor(hexString: "#C0453E").setStroke()
            context.setLineWidth(3)
            context.setLineDash(phase: 0, lengths: [10, 8])
            context.stroke(CGRect(x: 24, y: 24, width: cardSize.width - 48, height: cardSize.height - 48).insetBy(dx: 8, dy: 8))
            context.setLineDash(phase: 0, lengths: [])

            // Brand + title.
            let brand = "ThreadGrid" as NSString
            brand.draw(at: CGPoint(x: 64, y: 56), withAttributes: [
                .font: UIFont.systemFont(ofSize: 34, weight: .semibold),
                .foregroundColor: UIColor(hexString: "#C0453E"),
            ])
            let title = chart.title as NSString
            title.draw(at: CGPoint(x: 64, y: 104), withAttributes: [
                .font: serifFont(size: 64),
                .foregroundColor: UIColor(hexString: "#2B2118"),
            ])

            // Grid render, centered, scaled to fit.
            let gridStyle = ChartRenderer.Style.card
            let gridImage = ChartRenderer.image(chart: chart, style: gridStyle, library: library)
            let maxGrid = CGSize(width: cardSize.width - 560, height: 900)
            let scale = min(maxGrid.width / gridImage.size.width, maxGrid.height / gridImage.size.height, 1.6)
            let drawSize = CGSize(width: gridImage.size.width * scale, height: gridImage.size.height * scale)
            let gridOrigin = CGPoint(x: 64, y: 220)
            gridImage.draw(in: CGRect(origin: gridOrigin, size: drawSize))

            // Progress / meta under the grid.
            let percent = Int((chart.progress * 100).rounded())
            let meta = chart.status == .finished
                ? "Finished · \(chart.totalCells) stitches"
                : "\(percent)% · \(chart.stitchedCount) / \(chart.totalCells) stitches"
            (meta as NSString).draw(at: CGPoint(x: gridOrigin.x, y: gridOrigin.y + drawSize.height + 24), withAttributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 30, weight: .medium),
                .foregroundColor: UIColor(hexString: "#6E5F4E"),
            ])
            let sizeLine = "\(chart.widthCells) × \(chart.heightCells) · \(chart.palette.count) colors" as NSString
            sizeLine.draw(at: CGPoint(x: gridOrigin.x, y: gridOrigin.y + drawSize.height + 66), withAttributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 26, weight: .regular),
                .foregroundColor: UIColor(hexString: "#6E5F4E"),
            ])

            // DMC key column on the right.
            var keyY: CGFloat = 220
            let keyX = cardSize.width - 440
            ("DMC" as NSString).draw(at: CGPoint(x: keyX, y: keyY), withAttributes: [
                .font: UIFont.systemFont(ofSize: 30, weight: .bold),
                .foregroundColor: UIColor(hexString: "#3E5F8A"),
            ])
            keyY += 52
            for color in chart.palette.prefix(12) {
                let thread = library.thread(for: color.dmcCode)
                UIColor(hexString: thread?.hex ?? "#999999").setFill()
                context.fill(CGRect(x: keyX, y: keyY, width: 36, height: 36))
                UIColor(hexString: "#2B2118").setStroke()
                context.setLineWidth(1)
                context.stroke(CGRect(x: keyX, y: keyY, width: 36, height: 36))
                (color.dmcCode as NSString).draw(at: CGPoint(x: keyX + 52, y: keyY + 2), withAttributes: [
                    .font: UIFont.monospacedSystemFont(ofSize: 28, weight: .medium),
                    .foregroundColor: UIColor(hexString: "#2B2118"),
                ])
                keyY += 50
            }

            // Optional finished piece photo, bottom right.
            if let photo = finishedPhoto {
                let photoRect = CGRect(x: cardSize.width - 400, y: cardSize.height - 400, width: 320, height: 320)
                UIColor.white.setFill()
                context.fill(photoRect.insetBy(dx: -10, dy: -10))
                drawAspectFill(photo, in: photoRect, context: context)
                UIColor(hexString: "#2B2118").setStroke()
                context.setLineWidth(1.5)
                context.stroke(photoRect.insetBy(dx: -10, dy: -10))
                ("Finished piece" as NSString).draw(at: CGPoint(x: photoRect.minX - 10, y: photoRect.maxY + 16), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 24, weight: .medium),
                    .foregroundColor: UIColor(hexString: "#6E5F4E"),
                ])
            }

            // Footer date.
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            (formatter.string(from: Date()) as NSString).draw(at: CGPoint(x: 64, y: cardSize.height - 90), withAttributes: [
                .font: UIFont.systemFont(ofSize: 26),
                .foregroundColor: UIColor(hexString: "#8A7B63"),
            ])
        }
    }

    // MARK: - Printable PDF (1 credit)

    /// Multi-page letter PDF: cover, tiled symbol chart with rulers, DMC
    /// thread list with estimates, and the color-symbol key.
    static func makePrintablePDF(chart: Chart, library: DMCLibrary = .shared) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            // ---- Cover page ----
            context.beginPage()
            var ctx = context.cgContext
            drawPDFHeader(chart: chart, in: pageRect, subtitle: "Printable stitch chart")
            let coverStyle = ChartRenderer.Style(cellSize: 5, showSymbols: false, showGridLines: true)
            let coverImage = ChartRenderer.image(chart: chart, style: coverStyle, library: library)
            let fit = min((pageRect.width - 120) / coverImage.size.width, (pageRect.height - 260) / coverImage.size.height, 2.2)
            let coverSize = CGSize(width: coverImage.size.width * fit, height: coverImage.size.height * fit)
            coverImage.draw(in: CGRect(
                x: (pageRect.width - coverSize.width) / 2,
                y: 170,
                width: coverSize.width,
                height: coverSize.height
            ))
            let stats = "\(chart.widthCells) × \(chart.heightCells) stitches · \(chart.palette.count) DMC colors" as NSString
            centerText(stats, atY: 190 + coverSize.height, pageWidth: pageRect.width, attributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor(hexString: "#6E5F4E"),
            ])
            centerText("Print at 100% scale. Each square is one cross stitch." as NSString, atY: 230 + coverSize.height, pageWidth: pageRect.width, attributes: [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor(hexString: "#8A7B63"),
            ])

            // ---- Symbol chart pages (tiled) ----
            let tileCell: CGFloat = 11
            let margin: CGFloat = 72
            let usableWidth = pageRect.width - margin * 2
            let usableHeight = pageRect.height - margin * 2 - 60
            let colsPerTile = max(10, Int(usableWidth / tileCell))
            let rowsPerTile = max(10, Int(usableHeight / tileCell))

            var tileRow = 0
            while tileRow * rowsPerTile < chart.heightCells {
                var tileCol = 0
                while tileCol * colsPerTile < chart.widthCells {
                    context.beginPage()
                    ctx = context.cgContext
                    drawPDFHeader(chart: chart, in: pageRect, subtitle: "Symbol chart")

                    let rows = min(rowsPerTile, chart.heightCells - tileRow * rowsPerTile)
                    let cols = min(colsPerTile, chart.widthCells - tileCol * colsPerTile)

                    // Draw the tile by rendering a sub-chart slice.
                    let tileChart = slice(chart: chart, startRow: tileRow * rowsPerTile, startCol: tileCol * colsPerTile, rows: rows, cols: cols)
                    ChartRenderer.draw(
                        chart: tileChart,
                        in: ctx,
                        origin: CGPoint(x: margin + 20, y: margin + 30),
                        style: ChartRenderer.Style.printChart,
                        library: library
                    )

                    // Tile coordinates footer.
                    let footer = "Rows \(tileRow * rowsPerTile + 1)–\(tileRow * rowsPerTile + rows) · Columns \(tileCol * colsPerTile + 1)–\(tileCol * colsPerTile + cols)" as NSString
                    centerText(footer, atY: pageRect.height - 54, pageWidth: pageRect.width, attributes: [
                        .font: UIFont.monospacedSystemFont(ofSize: 11, weight: .regular),
                        .foregroundColor: UIColor(hexString: "#8A7B63"),
                    ])
                    tileCol += 1
                }
                tileRow += 1
            }

            // ---- Thread list page ----
            context.beginPage()
            drawPDFHeader(chart: chart, in: pageRect, subtitle: "DMC thread list")
            var y: CGFloat = 150
            let columns: [(String, CGFloat)] = [("Symbol", 72), ("DMC", 150), ("Color", 230), ("Stitches", 340), ("Skeins", 460)]
            for (label, x) in columns {
                (label as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 12, weight: .bold),
                    .foregroundColor: UIColor(hexString: "#3E5F8A"),
                ])
            }
            y += 26
            UIColor(hexString: "#C9BFAE").setStroke()
            ctx = context.cgContext
            ctx.setLineWidth(0.75)
            ctx.move(to: CGPoint(x: 72, y: y))
            ctx.addLine(to: CGPoint(x: pageRect.width - 72, y: y))
            ctx.strokePath()
            y += 12
            for color in chart.palette.sorted(by: { $0.stitchCount > $1.stitchCount }) {
                if y > pageRect.height - 90 {
                    context.beginPage()
                    drawPDFHeader(chart: chart, in: pageRect, subtitle: "DMC thread list (continued)")
                    y = 150
                }
                let thread = library.thread(for: color.dmcCode)
                (color.symbol as NSString).draw(at: CGPoint(x: columns[0].1, y: y), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 13),
                    .foregroundColor: UIColor(hexString: "#2B2118"),
                ])
                (color.dmcCode as NSString).draw(at: CGPoint(x: columns[1].1, y: y), withAttributes: [
                    .font: UIFont.monospacedSystemFont(ofSize: 12, weight: .medium),
                    .foregroundColor: UIColor(hexString: "#2B2118"),
                ])
                ((thread?.name ?? "—") as NSString).draw(at: CGPoint(x: columns[2].1, y: y), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor(hexString: "#2B2118"),
                ])
                ("\(color.stitchCount)" as NSString).draw(at: CGPoint(x: columns[3].1, y: y), withAttributes: [
                    .font: UIFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                    .foregroundColor: UIColor(hexString: "#2B2118"),
                ])
                (estimatedSkeinsText(for: color.stitchCount) as NSString).draw(at: CGPoint(x: columns[4].1, y: y), withAttributes: [
                    .font: UIFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                    .foregroundColor: UIColor(hexString: "#2B2118"),
                ])
                y += 22
            }

            // ---- Symbol key page ----
            context.beginPage()
            ctx = context.cgContext
            drawPDFHeader(chart: chart, in: pageRect, subtitle: "Color & symbol key")
            var keyY: CGFloat = 160
            for color in chart.palette {
                if keyY > pageRect.height - 100 {
                    context.beginPage()
                    drawPDFHeader(chart: chart, in: pageRect, subtitle: "Color & symbol key (continued)")
                    keyY = 160
                }
                let thread = library.thread(for: color.dmcCode)
                let swatch = CGRect(x: 96, y: keyY, width: 30, height: 30)
                UIColor(hexString: thread?.hex ?? "#999999").setFill()
                ctx.fill(swatch)
                UIColor(hexString: "#2B2118").setStroke()
                ctx.setLineWidth(1)
                ctx.stroke(swatch)
                let label = "\(color.symbol)   DMC \(color.dmcCode) · \(thread?.name ?? "")" as NSString
                label.draw(at: CGPoint(x: 150, y: keyY + 5), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor(hexString: "#2B2118"),
                ])
                keyY += 42
            }
        }
    }

    /// ~1968 full cross stitches per 8m six-strand skein (stitcher's rule of thumb).
    static func estimatedSkeinsText(for stitchCount: Int) -> String {
        let skeins = ceil(Double(stitchCount) / 1968.0 * 10) / 10
        if skeins < 0.1 { return "0.1" }
        return String(format: "%.1f", skeins)
    }

    private static func slice(chart: Chart, startRow: Int, startCol: Int, rows: Int, cols: Int) -> Chart {
        var bytes = [UInt8](repeating: 0, count: rows * cols)
        for r in 0..<rows {
            for c in 0..<cols {
                let sourceIndex = (startRow + r) * chart.widthCells + (startCol + c)
                bytes[r * cols + c] = chart.colorIndex(at: sourceIndex) < 256 ? UInt8(clamping: chart.colorIndex(at: sourceIndex)) : 0
            }
        }
        return Chart(
            title: chart.title,
            widthCells: cols,
            heightCells: rows,
            maxColors: chart.maxColors,
            cells: Data(bytes),
            palette: chart.palette
        )
    }

    private static func drawPDFHeader(chart: Chart, in pageRect: CGRect, subtitle: String) {
        ("ThreadGrid · \(chart.title)" as NSString).draw(at: CGPoint(x: 72, y: 48), withAttributes: [
            .font: serifFont(size: 22),
            .foregroundColor: UIColor(hexString: "#2B2118"),
        ])
        (subtitle as NSString).draw(at: CGPoint(x: 72, y: 80), withAttributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor(hexString: "#C0453E"),
        ])
    }

    private static func centerText(_ text: NSString, atY y: CGFloat, pageWidth: CGFloat, attributes: [NSAttributedString.Key: Any]) {
        let size = text.size(withAttributes: attributes)
        text.draw(at: CGPoint(x: (pageWidth - size.width) / 2, y: y), withAttributes: attributes)
    }

    private static func drawAspectFill(_ image: UIImage, in rect: CGRect, context: CGContext) {
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return }
        let scale = max(rect.width / imageSize.width, rect.height / imageSize.height)
        let drawSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let drawRect = CGRect(
            x: rect.midX - drawSize.width / 2,
            y: rect.midY - drawSize.height / 2,
            width: drawSize.width,
            height: drawSize.height
        )
        context.saveGState()
        context.clip(to: rect)
        image.draw(in: drawRect)
        context.restoreGState()
    }
}
