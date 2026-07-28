import Foundation
import SwiftUI

struct DMCThread: Codable, Hashable, Identifiable {
    let dmcCode: String
    let name: String
    let hex: String

    var id: String { dmcCode }
    var color: Color { Color(hexString: hex) }

    var rgb: (r: Double, g: Double, b: Double) {
        DMCThread.parse(hex: hex)
    }

    static func parse(hex: String) -> (r: Double, g: Double, b: Double) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        guard cleaned.count == 6, let value = UInt32(cleaned, radix: 16) else {
            return (0.5, 0.5, 0.5)
        }
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        return (r, g, b)
    }
}

/// Built-in, read-only DMC floss palette bundled with the app (no network, no CDN).
final class DMCLibrary {
    static let shared = DMCLibrary()

    let threads: [DMCThread]
    private let byCode: [String: DMCThread]

    private init() {
        var loaded: [DMCThread] = []
        if let url = Bundle.main.url(forResource: "dmc_threads", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(DMCFile.self, from: data) {
            loaded = decoded.threads
        }
        if loaded.isEmpty {
            // Hard fallback so the app is never without a palette.
            loaded = [
                DMCThread(dmcCode: "Blanc", name: "White", hex: "#FCFBF8"),
                DMCThread(dmcCode: "310", name: "Black", hex: "#000000"),
                DMCThread(dmcCode: "321", name: "Red", hex: "#C72C3B"),
                DMCThread(dmcCode: "740", name: "Tangerine", hex: "#FF8B00"),
                DMCThread(dmcCode: "823", name: "Navy Blue Dark", hex: "#1E2F4E"),
                DMCThread(dmcCode: "3346", name: "Hunter Green", hex: "#3B5E3B"),
            ]
        }
        self.threads = loaded
        self.byCode = Dictionary(uniqueKeysWithValues: loaded.map { ($0.dmcCode, $0) })
    }

    func thread(for code: String) -> DMCThread? {
        byCode[code]
    }

    /// Nearest floss to an sRGB triple using the redmean approximation —
    /// deterministic and fully on-device (F2 quantization target gamut).
    func nearest(r: Double, g: Double, b: Double) -> DMCThread {
        var best = threads[0]
        var bestDistance = Double.greatestFiniteMagnitude
        for thread in threads {
            let t = thread.rgb
            let rMean = (r + t.r) / 2.0
            let dr = r - t.r
            let dg = g - t.g
            let db = b - t.b
            let distance = (2.0 + rMean) * dr * dr + 4.0 * dg * dg + (2.0 + (1.0 - rMean)) * db * db
            if distance < bestDistance {
                bestDistance = distance
                best = thread
            }
        }
        return best
    }

    /// Printable symbols, auto-assigned per palette color (design.md: symbols
    /// carry meaning alongside color so color is never the only channel).
    static let symbolPool: [String] = [
        "✕", "●", "▲", "◆", "■", "○", "△", "◇", "□", "★",
        "☆", "♥", "+", "=", "×", "÷", "♦", "◐", "◑", "⊕",
        "⊗", "⊙", "#", "%", "@", "&", "?", "Z", "N", "M",
        "W", "H", "A", "B", "C", "D", "E", "F", "G", "K",
        "P", "R", "S", "T", "U", "V", "Y", "♣", "♠", "♪",
        "◈", "⬗", "⬘", "⬙", "⬖", "☀", "☾", "✿", "❖", "✚",
        "⊞", "⊠", "⊡", "⊜", "∴", "∵", "∗", "≡", "≈", "∞",
    ]

    private struct DMCFile: Codable {
        let threads: [DMCThread]
    }
}

extension Color {
    init(hexString: String) {
        let rgb = DMCThread.parse(hex: hexString)
        self.init(red: rgb.r, green: rgb.g, blue: rgb.b)
    }
}

extension UIColor {
    convenience init(hexString: String) {
        let rgb = DMCThread.parse(hex: hexString)
        self.init(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: 1)
    }
}
