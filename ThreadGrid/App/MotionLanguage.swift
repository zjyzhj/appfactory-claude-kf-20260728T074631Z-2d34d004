import SwiftUI
import UIKit

/// Shared motion tokens + haptics (build/design.md §Motion & interaction language).
/// Thesis: short, light motions with a "thread pulled taut then settled" feel.
/// Every moment has an accessibilityReduceMotion equivalent that preserves the
/// same user value without automatic animation.
enum Motion {

    // MARK: Shared tokens (design.md table)

    /// 0.35s easeOut — general entry / state transitions.
    static let threadEase: Animation = .easeOut(duration: 0.35)

    /// spring(response 0.4, damping 0.7) — cell marking, button settle.
    static let pullSpring: Animation = .spring(response: 0.4, dampingFraction: 0.7)

    /// 0.03s per item — lists / cards weaving in row by row.
    static let weaveStagger: Double = 0.03

    /// 1.2s — finishing "stitch around the border" stroke.
    static let celebrateDuration: Double = 1.2

    // MARK: Helpers

    /// Returns `animated` unless Reduce Motion is on, in which case the change is instant.
    static func weave(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : threadEase
    }

    static func pull(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : pullSpring
    }

    static func entryDelay(index: Int, reduceMotion: Bool) -> Double {
        reduceMotion ? 0 : Double(index) * weaveStagger
    }
}

enum Haptics {
    static func lightTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func mediumTap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
