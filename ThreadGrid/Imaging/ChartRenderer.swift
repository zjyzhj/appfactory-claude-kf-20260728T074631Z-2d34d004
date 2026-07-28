import Foundation
import UIKit
import CoreGraphics

/// Renders chart grids into CGContexts — shared by thumbnails, the result
/// card, and printable PDF pages so every surface shows the same truth.
enum ChartRenderer {

    struct Style {
        var cellSize: CGFloat = 8
        var showSymbols: Bool = false
        var showGridLines: Bool = true
        var rulers: Bool = false
        var stitchedOnly: Set<Int>? = nil
        var dimUnstitched: Bool = false
        var highlightColorIndex: Int? = nil

        static let thumbnail = Style(cellSize: 4, showSymbols: false, showGridLines: false)
        static let detail = Style(cellSize: 6, showSymbols: false, showGridLines: true)
        static let card = Style(cellSize: 9, showSymbols: false, showGridLines: true)
        static let printChart = Style(cellSize: 11, showSymbols: true, showGridLines: true, rulers: true)
    }

    static func gridPixelSize(chart: Chart, style: Style) -> CGSize {
        CGSize(
            width: CGFloat(chart.widthCells) * style.cellSize,
            height: CGFloat(chart.heightCells) * style.cellSize
        )
    }

    /// Draws the grid (and optional rulers) at the given origin.
    static func draw(
        chart: Chart,
        in context: CGContext,
        origin: CGPoint,
        style: Style,
        library: DMCLibrary = .shared
    ) {
        let cell = style.cellSize
        let w = chart.widthCells
        let h = chart.heightCells

        // Fabric ground.
        context.setFillColor(UIColor(hexString: "#FBF7EE").cgColor)
        context.fill(CGRect(x: origin.x, y: origin.y, width: CGFloat(w) * cell, height: CGFloat(h) * cell))

        var uiFontSize = cell * 0.62
        if uiFontSize < 5 { uiFontSize = 5 }
        let font = UIFont.systemFont(ofSize: uiFontSize, weight: .medium)

        for row in 0..<h {
            for col in 0..<w {
                let cellIndex = row * w + col
                let rect = CGRect(x: origin.x + CGFloat(col) * cell, y: origin.y + CGFloat(row) * cell, width: cell, height: cell)
                guard let paletteColor = chart.paletteColor(at: cellIndex) else { continue }
                let thread = library.thread(for: paletteColor.dmcCode)
                let uiColor = UIColor(hexString: thread?.hex ?? "#999999")

                let isStitched = style.stitchedOnly?.contains(cellIndex) ?? false
                if style.stitchedOnly != nil {
                    // Stitch-session style rendering: stitched cells full color,
                    // unstitched show their symbol on fabric.
                    if isStitched {
                        uiColor.setFill()
                        context.fill(rect)
                    } else {
                        UIColor(hexString: "#F3ECDD").setFill()
                        context.fill(rect)
                        if style.showSymbols {
                            let dimmed = style.highlightColorIndex != nil && paletteColor.colorIndex != style.highlightColorIndex
                            let symbolColor = dimmed ? UIColor(hexString: "#C9BFAE") : UIColor(hexString: "#8A7B63")
                            drawSymbol(paletteColor.symbol, in: rect, font: font, color: symbolColor, context: context)
                        }
                    }
                } else {
                    let dimmed = style.dimUnstitched && style.highlightColorIndex != nil
                        && paletteColor.colorIndex != style.highlightColorIndex
                    (dimmed ? uiColor.withAlphaComponent(0.22) : uiColor).setFill()
                    context.fill(rect)
                    if style.showSymbols {
                        let luminance = relativeLuminance(uiColor)
                        let symbolColor = dimmed
                            ? UIColor(hexString: "#B9AE9C")
                            : (luminance > 0.6 ? UIColor(white: 0.15, alpha: 0.85) : UIColor(white: 1, alpha: 0.9))
                        drawSymbol(paletteColor.symbol, in: rect, font: font, color: symbolColor, context: context)
                    }
                }

                if style.showGridLines {
                    UIColor(white: 0.35, alpha: 0.16).setStroke()
                    context.setLineWidth(0.5)
                    context.stroke(rect)
                }
            }
        }

        if style.rulers {
            drawRulers(chart: chart, in: context, origin: origin, cell: cell)
        }
    }

    private static func drawSymbol(_ symbol: String, in rect: CGRect, font: UIFont, color: UIColor, context: CGContext) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
        ]
        let text = symbol as NSString
        let size = text.size(withAttributes: attributes)
        let point = CGPoint(
            x: rect.midX - size.width / 2,
            y: rect.midY - size.height / 2
        )
        text.draw(at: point, withAttributes: attributes)
    }

    private static func drawRulers(chart: Chart, in context: CGContext, origin: CGPoint, cell: CGFloat) {
        let font = UIFont.monospacedSystemFont(ofSize: 8, weight: .regular)
        let color = UIColor(hexString: "#8A7B63")
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        // Column numbers every 10 cells along the top.
        var col = 9
        while col < chart.widthCells {
            let label = "\(col + 1)" as NSString
            let x = origin.x + (CGFloat(col) + 0.5) * cell
            label.draw(at: CGPoint(x: x - label.size(withAttributes: attributes).width / 2, y: origin.y - 12), withAttributes: attributes)
            // Marker tick.
            color.setStroke()
            context.setLineWidth(0.75)
            context.move(to: CGPoint(x: x, y: origin.y - 3))
            context.addLine(to: CGPoint(x: x, y: origin.y))
            context.strokePath()
            col += 10
        }
        // Row numbers every 10 down the left.
        var row = 9
        while row < chart.heightCells {
            let label = "\(row + 1)" as NSString
            let y = origin.y + (CGFloat(row) + 0.5) * cell
            label.draw(at: CGPoint(x: origin.x - 6 - label.size(withAttributes: attributes).width, y: y - 4), withAttributes: attributes)
            row += 10
        }
    }

    private static func relativeLuminance(_ color: UIColor) -> Double {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.2126 * Double(r) + 0.7152 * Double(g) + 0.0722 * Double(b)
    }

    // MARK: - UIImage conveniences

    static func image(chart: Chart, style: Style, library: DMCLibrary = .shared) -> UIImage {
        let rulerMargin: CGFloat = style.rulers ? 20 : 0
        let grid = gridPixelSize(chart: chart, style: style)
        let size = CGSize(width: grid.width + rulerMargin, height: grid.height + rulerMargin)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            draw(chart: chart, in: ctx.cgContext, origin: CGPoint(x: rulerMargin, y: rulerMargin), style: style, library: library)
        }
    }
}
