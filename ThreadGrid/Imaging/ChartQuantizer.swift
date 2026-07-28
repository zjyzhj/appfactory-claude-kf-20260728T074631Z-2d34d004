import Foundation
import UIKit
import CoreGraphics

/// On-device deterministic color quantization (F2): median-cut clustering of
/// the downsampled source photo, then nearest-match into the real DMC floss
/// gamut. No network, no remote service — photos never leave the device.
enum ChartQuantizer {

    struct Result {
        let cells: Data            // row-major palette indices
        let palette: [ChartColor]  // unique by dmcCode, sorted by stitch count desc
    }

    static func quantize(
        image: UIImage,
        widthCells: Int,
        heightCells: Int,
        maxColors: Int,
        library: DMCLibrary = .shared
    ) -> Result {
        let pixelCount = max(1, widthCells) * max(1, heightCells)
        let pixels = downsample(image: image, width: widthCells, height: heightCells)

        // Median-cut into up to maxColors clusters.
        let clusterCount = max(1, min(maxColors, 60))
        var boxes: [ColorBox] = [ColorBox(indices: Array(pixels.indices))]
        while boxes.count < clusterCount {
            guard let splitIndex = boxes.indices.max(by: { boxes[$0].score(pixels: pixels) < boxes[$1].score(pixels: pixels) }),
                  boxes[splitIndex].indices.count > 1,
                  boxes[splitIndex].range(pixels: pixels) > 0 else { break }
            let box = boxes.remove(at: splitIndex)
            let (a, b) = box.split(pixels: pixels)
            boxes.append(a)
            boxes.append(b)
        }

        // Average color per cluster → nearest DMC; merge clusters that land on
        // the same floss so the palette stays unique by dmcCode.
        var merged = Set<String>()
        var order: [String] = []
        for box in boxes {
            let avg = box.average(pixels: pixels)
            let thread = library.nearest(r: avg.r, g: avg.g, b: avg.b)
            if !merged.contains(thread.dmcCode) {
                merged.insert(thread.dmcCode)
                order.append(thread.dmcCode)
            }
        }

        // Stitch count per merged color.
        var counts = [String: Int]()
        for box in boxes {
            let avg = box.average(pixels: pixels)
            let thread = library.nearest(r: avg.r, g: avg.g, b: avg.b)
            counts[thread.dmcCode, default: 0] += box.indices.count
        }

        let sortedCodes = order.sorted { (counts[$0] ?? 0) > (counts[$1] ?? 0) }
        var colorIndexByCode = [String: Int]()
        var palette: [ChartColor] = []
        for (position, code) in sortedCodes.enumerated() {
            colorIndexByCode[code] = position
            palette.append(ChartColor(
                colorIndex: position,
                dmcCode: code,
                symbol: DMCLibrary.symbolPool[position % DMCLibrary.symbolPool.count],
                stitchCount: counts[code] ?? 0
            ))
        }

        // Cell assignment: cluster → merged color index.
        var clusterToColor = [Int](repeating: 0, count: boxes.count)
        for (clusterIndex, box) in boxes.enumerated() {
            let avg = box.average(pixels: pixels)
            let thread = library.nearest(r: avg.r, g: avg.g, b: avg.b)
            clusterToColor[clusterIndex] = colorIndexByCode[thread.dmcCode] ?? 0
        }
        var bytes = [UInt8](repeating: 0, count: pixelCount)
        for (clusterIndex, box) in boxes.enumerated() {
            let colorIdx = UInt8(clamping: clusterToColor[clusterIndex])
            for pixelIndex in box.indices where pixelIndex < pixelCount {
                bytes[pixelIndex] = colorIdx
            }
        }

        return Result(cells: Data(bytes), palette: palette)
    }

    /// Blank chart: every cell filled with the fabric color (DMC Blanc) so the
    /// grid is first-class data and the finish flow stays reachable (F3).
    static func blank(widthCells: Int, heightCells: Int) -> Result {
        let count = max(1, widthCells) * max(1, heightCells)
        let palette = [ChartColor(colorIndex: 0, dmcCode: "Blanc", symbol: "·", stitchCount: count)]
        return Result(cells: Data(repeating: 0, count: count), palette: palette)
    }

    // MARK: - Downsampling

    private static func downsample(image: UIImage, width: Int, height: Int) -> [(r: Double, g: Double, b: Double)] {
        let w = max(1, width)
        let h = max(1, height)
        var pixels = [(r: Double, g: Double, b: Double)](repeating: (0.8, 0.78, 0.72), count: w * h)
        guard let cgImage = image.cgImage else { return pixels }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var raw = [UInt8](repeating: 0, count: w * h * 4)
        guard let context = CGContext(
            data: &raw,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return pixels }

        // Aspect-fill so the chart grid covers the whole photo region.
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let targetSize = CGSize(width: w, height: h)
        let scale = max(targetSize.width / imageSize.width, targetSize.height / imageSize.height)
        let drawSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let drawOrigin = CGPoint(x: (targetSize.width - drawSize.width) / 2, y: (targetSize.height - drawSize.height) / 2)
        context.draw(cgImage, in: CGRect(origin: drawOrigin, size: drawSize))

        for i in 0..<(w * h) {
            let offset = i * 4
            pixels[i] = (
                r: Double(raw[offset]) / 255.0,
                g: Double(raw[offset + 1]) / 255.0,
                b: Double(raw[offset + 2]) / 255.0
            )
        }
        return pixels
    }

    // MARK: - Median cut

    private struct ColorBox {
        var indices: [Int]

        func range(pixels: [(r: Double, g: Double, b: Double)]) -> Double {
            var minR = 1.0, maxR = 0.0, minG = 1.0, maxG = 0.0, minB = 1.0, maxB = 0.0
            for i in indices {
                let p = pixels[i]
                minR = min(minR, p.r); maxR = max(maxR, p.r)
                minG = min(minG, p.g); maxG = max(maxG, p.g)
                minB = min(minB, p.b); maxB = max(maxB, p.b)
            }
            return max(maxR - minR, max(maxG - minG, maxB - minB))
        }

        func score(pixels: [(r: Double, g: Double, b: Double)]) -> Double {
            range(pixels: pixels) * Double(indices.count)
        }

        func average(pixels: [(r: Double, g: Double, b: Double)]) -> (r: Double, g: Double, b: Double) {
            var r = 0.0, g = 0.0, b = 0.0
            for i in indices {
                let p = pixels[i]
                r += p.r; g += p.g; b += p.b
            }
            let n = max(1, indices.count)
            return (r / Double(n), g / Double(n), b / Double(n))
        }

        func split(pixels: [(r: Double, g: Double, b: Double)]) -> (ColorBox, ColorBox) {
            var minR = 1.0, maxR = 0.0, minG = 1.0, maxG = 0.0, minB = 1.0, maxB = 0.0
            for i in indices {
                let p = pixels[i]
                minR = min(minR, p.r); maxR = max(maxR, p.r)
                minG = min(minG, p.g); maxG = max(maxG, p.g)
                minB = min(minB, p.b); maxB = max(maxB, p.b)
            }
            let ranges = [(maxR - minR), (maxG - minG), (maxB - minB)]
            let channel = ranges.firstIndex(of: ranges.max() ?? 0) ?? 0
            let sorted = indices.sorted { a, b in
                let pa = pixels[a], pb = pixels[b]
                switch channel {
                case 0: return pa.r < pb.r
                case 1: return pa.g < pb.g
                default: return pa.b < pb.b
                }
            }
            let mid = max(1, sorted.count / 2)
            return (ColorBox(indices: Array(sorted[..<mid])), ColorBox(indices: Array(sorted[mid...])))
        }
    }
}
