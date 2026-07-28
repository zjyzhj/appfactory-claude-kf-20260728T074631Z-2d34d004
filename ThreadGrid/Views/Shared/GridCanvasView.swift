import SwiftUI
import UIKit

/// Interactive chart canvas (chart_editor, stitch_session, create preview).
/// Single-finger drag paints / marks, two-finger drag pans, pinch zooms
/// (single cell up to 44pt+), double-tap fits. VoiceOver exposes visible cells
/// as "row R, column C, DMC code, stitched". The editor canvas never runs
/// automatic animations (design.md §Forbidden); the stitch pulse is
/// interaction-driven only and skipped under Reduce Motion.
struct GridCanvasView: UIViewRepresentable {

    enum Mode {
        case display
        case edit(selectedColorIndex: Int)
        case stitch(stitched: Set<Int>, filterColorIndex: Int?)
    }

    let chart: Chart
    let mode: Mode
    var showSymbols: Bool = true
    var reduceMotion: Bool = false
    var onCellInteracted: ((Int) -> Void)? = nil
    var onSelectionChange: ((Int?) -> Void)? = nil

    func makeUIView(context: Context) -> GridCanvasUIView {
        let view = GridCanvasUIView()
        view.configure(chart: chart, mode: GridCanvasUIView.Mode(mode), showSymbols: showSymbols, reduceMotion: reduceMotion)
        view.onCellInteracted = onCellInteracted
        view.onSelectionChange = onSelectionChange
        return view
    }

    func updateUIView(_ view: GridCanvasUIView, context: Context) {
        view.configure(chart: chart, mode: GridCanvasUIView.Mode(mode), showSymbols: showSymbols, reduceMotion: reduceMotion)
        view.onCellInteracted = onCellInteracted
        view.onSelectionChange = onSelectionChange
    }
}

final class GridCanvasUIView: UIView {

    enum Mode {
        case display
        case edit(selectedColorIndex: Int)
        case stitch(stitched: Set<Int>, filterColorIndex: Int?)

        init(_ mode: GridCanvasView.Mode) {
            switch mode {
            case .display:
                self = .display
            case .edit(let selectedColorIndex):
                self = .edit(selectedColorIndex: selectedColorIndex)
            case .stitch(let stitched, let filterColorIndex):
                self = .stitch(stitched: stitched, filterColorIndex: filterColorIndex)
            }
        }
    }

    private var chart: Chart = Chart(title: "", widthCells: 1, heightCells: 1, maxColors: 1, cells: Data([0]), palette: [])
    private var mode: Mode = .display
    private var showSymbols = true
    private var reduceMotion = false

    var onCellInteracted: ((Int) -> Void)?
    var onSelectionChange: ((Int?) -> Void)?

    private var cellSize: CGFloat = 14
    private var contentOffset = CGPoint.zero // top-left of visible area in content coords
    private var didInitialFit = false
    private var lastTouchedCell: Int?

    // mot_commit_stitch pulse state (interaction-driven, never looping).
    private var pulseCell: Int?
    private var pulseStart: CFTimeInterval = 0
    private var pulseLink: CADisplayLink?

    private let library = DMCLibrary.shared

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        isMultipleTouchEnabled = true
        isAccessibilityElement = false
        accessibilityTraits = .allowsDirectInteraction

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
        tap.require(toFail: doubleTap)

        let oneFinger = UIPanGestureRecognizer(target: self, action: #selector(handleOneFingerPan(_:)))
        oneFinger.minimumNumberOfTouches = 1
        oneFinger.maximumNumberOfTouches = 1
        addGestureRecognizer(oneFinger)

        let twoFinger = UIPanGestureRecognizer(target: self, action: #selector(handleTwoFingerPan(_:)))
        twoFinger.minimumNumberOfTouches = 2
        addGestureRecognizer(twoFinger)

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinch)
    }

    func configure(chart: Chart, mode: Mode, showSymbols: Bool, reduceMotion: Bool) {
        self.chart = chart
        self.mode = mode
        self.showSymbols = showSymbols
        self.reduceMotion = reduceMotion
        clampViewports()
        setNeedsDisplay()
        refreshAccessibility()
    }

    // MARK: - Layout & viewport

    private var fitCellSize: CGFloat {
        guard chart.widthCells > 0, chart.heightCells > 0, bounds.width > 0, bounds.height > 0 else { return 4 }
        return max(2.5, min(bounds.width / CGFloat(chart.widthCells), bounds.height / CGFloat(chart.heightCells)))
    }

    private var contentSize: CGSize {
        CGSize(width: CGFloat(chart.widthCells) * cellSize, height: CGFloat(chart.heightCells) * cellSize)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !didInitialFit, bounds.width > 0 {
            didInitialFit = true
            fitToView(animated: false)
        }
        clampViewports()
    }

    private func fitToView(animated: Bool) {
        cellSize = fitCellSize
        let size = contentSize
        contentOffset = CGPoint(
            x: max(0, (size.width - bounds.width) / 2),
            y: max(0, (size.height - bounds.height) / 2)
        )
        if animated, !reduceMotion {
            UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut) { self.setNeedsDisplay() }
        }
        setNeedsDisplay()
        refreshAccessibility()
    }

    private func clampViewports() {
        let fit = fitCellSize
        cellSize = min(64, max(fit, cellSize))
        let size = contentSize
        let maxX = max(0, size.width - bounds.width)
        let maxY = max(0, size.height - bounds.height)
        contentOffset.x = min(max(contentOffset.x, -cellSize * 2), maxX + cellSize * 2)
        contentOffset.y = min(max(contentOffset.y, -cellSize * 2), maxY + cellSize * 2)
    }

    private func cellIndex(at point: CGPoint) -> Int? {
        let col = Int((point.x + contentOffset.x) / cellSize)
        let row = Int((point.y + contentOffset.y) / cellSize)
        guard col >= 0, col < chart.widthCells, row >= 0, row < chart.heightCells else { return nil }
        return row * chart.widthCells + col
    }

    // MARK: - Gestures

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let cell = cellIndex(at: gesture.location(in: self)) else { return }
        lastTouchedCell = cell
        onSelectionChange?(cell)
        switch mode {
        case .display:
            break
        case .edit:
            onCellInteracted?(cell)
        case .stitch(let stitched, _):
            onCellInteracted?(cell)
            if !reduceMotion {
                startPulse(on: cell, becameStitched: !stitched.contains(cell))
            }
        }
        setNeedsDisplay()
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        fitToView(animated: true)
    }

    @objc private func handleOneFingerPan(_ gesture: UIPanGestureRecognizer) {
        switch mode {
        case .display:
            panContent(with: gesture)
        case .edit:
            paintAlong(gesture)
        case .stitch:
            markAlong(gesture)
        }
    }

    @objc private func handleTwoFingerPan(_ gesture: UIPanGestureRecognizer) {
        panContent(with: gesture)
    }

    private func panContent(with gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        contentOffset.x -= translation.x
        contentOffset.y -= translation.y
        gesture.setTranslation(.zero, in: self)
        clampViewports()
        setNeedsDisplay()
        if gesture.state == .ended || gesture.state == .cancelled {
            refreshAccessibility()
        }
    }

    private func paintAlong(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        if let cell = cellIndex(at: location), cell != lastTouchedCell || gesture.state == .began {
            lastTouchedCell = cell
            onSelectionChange?(cell)
            onCellInteracted?(cell)
        }
        if gesture.state == .ended || gesture.state == .cancelled {
            setNeedsDisplay()
        }
    }

    private var dragMarkedCells = Set<Int>()

    private func markAlong(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        switch gesture.state {
        case .began:
            dragMarkedCells.removeAll()
            fallthrough
        case .changed:
            guard let cell = cellIndex(at: location), !dragMarkedCells.contains(cell) else { return }
            dragMarkedCells.insert(cell)
            lastTouchedCell = cell
            onSelectionChange?(cell)
            // Drag marking only stitches (never unstitches) so a stray swipe
            // cannot silently erase progress.
            if case .stitch(let stitched, _) = mode, !stitched.contains(cell) {
                onCellInteracted?(cell)
            }
        default:
            dragMarkedCells.removeAll()
            setNeedsDisplay()
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard gesture.numberOfTouches >= 2 else { return }
        let center = gesture.location(in: self)
        let contentPoint = CGPoint(x: center.x + contentOffset.x, y: center.y + contentOffset.y)
        let oldCellSize = cellSize
        cellSize = min(64, max(fitCellSize, cellSize * gesture.scale))
        gesture.scale = 1
        let ratio = cellSize / oldCellSize
        contentOffset = CGPoint(
            x: contentPoint.x * ratio - center.x,
            y: contentPoint.y * ratio - center.y
        )
        clampViewports()
        setNeedsDisplay()
        if gesture.state == .ended {
            refreshAccessibility()
        }
    }

    // MARK: - Stitch pulse (mot_commit_stitch)

    private func startPulse(on cell: Int, becameStitched: Bool) {
        guard becameStitched else { return }
        pulseCell = cell
        pulseStart = CACurrentMediaTime()
        pulseLink?.invalidate()
        let link = CADisplayLink(target: self, selector: #selector(pulseTick))
        link.add(to: .main, forMode: .common)
        pulseLink = link
    }

    @objc private func pulseTick() {
        let elapsed = CACurrentMediaTime() - pulseStart
        if elapsed > 0.4 {
            pulseLink?.invalidate()
            pulseLink = nil
            pulseCell = nil
        }
        setNeedsDisplay()
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), chart.widthCells > 0 else { return }
        let w = chart.widthCells

        let firstCol = max(0, Int(contentOffset.x / cellSize))
        let firstRow = max(0, Int(contentOffset.y / cellSize))
        let lastCol = min(w - 1, Int((contentOffset.x + bounds.width) / cellSize) + 1)
        let lastRow = min(chart.heightCells - 1, Int((contentOffset.y + bounds.height) / cellSize) + 1)
        guard lastCol >= firstCol, lastRow >= firstRow else { return }

        // Fabric ground under the whole visible area.
        UIColor(hexString: "#FBF7EE").setFill()
        context.fill(bounds)

        let drawSymbols = showSymbols && cellSize >= 9
        let font = UIFont.systemFont(ofSize: max(5, cellSize * 0.58), weight: .medium)
        let stitchedSet: Set<Int>
        let filterIndex: Int?
        if case .stitch(let stitched, let filter) = mode {
            stitchedSet = stitched
            filterIndex = filter
        } else {
            stitchedSet = []
            filterIndex = nil
        }

        for row in firstRow...lastRow {
            for col in firstCol...lastCol {
                let cellIndex = row * w + col
                let cellRect = CGRect(
                    x: CGFloat(col) * cellSize - contentOffset.x,
                    y: CGFloat(row) * cellSize - contentOffset.y,
                    width: cellSize,
                    height: cellSize
                )
                guard let paletteColor = chart.paletteColor(at: cellIndex) else { continue }
                let thread = library.thread(for: paletteColor.dmcCode)
                let color = UIColor(hexString: thread?.hex ?? "#999999")

                switch mode {
                case .display, .edit:
                    color.setFill()
                    context.fill(cellRect)
                    if drawSymbols {
                        let luminance = Self.luminance(color)
                        let symbolColor: UIColor = luminance > 0.6
                            ? UIColor(white: 0.12, alpha: 0.85)
                            : UIColor(white: 1, alpha: 0.9)
                        draw(paletteColor.symbol, in: cellRect, font: font, color: symbolColor)
                    }
                case .stitch:
                    if stitchedSet.contains(cellIndex) {
                        color.setFill()
                        context.fill(cellRect)
                    } else {
                        UIColor(hexString: "#F3ECDD").setFill()
                        context.fill(cellRect)
                        if drawSymbols {
                            let dimmed = filterIndex != nil && paletteColor.colorIndex != filterIndex
                            draw(paletteColor.symbol, in: cellRect, font: font,
                                 color: dimmed ? UIColor(hexString: "#D8CDB8") : UIColor(hexString: "#8A7B63"))
                        }
                        if filterIndex != nil && paletteColor.colorIndex == filterIndex {
                            // Current-thread highlight: indigo corner tick.
                            UIColor(hexString: "#3E5F8A").setFill()
                            let tick = cellSize * 0.22
                            context.fill(CGRect(x: cellRect.maxX - tick - 1, y: cellRect.minY + 1, width: tick, height: tick))
                        }
                    }
                }

                UIColor(white: 0.4, alpha: 0.14).setStroke()
                context.setLineWidth(0.5)
                context.stroke(cellRect)
            }
        }

        // Stitch pulse: the just-marked cell springs 1 → 1.15 → 1 with a soft
        // color bloom (pullSpring feel, 0.35s, interaction-driven only).
        if let pulse = pulseCell {
            let elapsed = CGFloat(CACurrentMediaTime() - pulseStart)
            let t = min(1, elapsed / 0.35)
            let scale = 1 + 0.15 * sin(CGFloat.pi * min(1, t * 1.2))
            let row = pulse / w
            let col = pulse % w
            let base = CGRect(
                x: CGFloat(col) * cellSize - contentOffset.x,
                y: CGFloat(row) * cellSize - contentOffset.y,
                width: cellSize,
                height: cellSize
            )
            let expanded = base.insetBy(dx: -base.width * (scale - 1) / 2, dy: -base.height * (scale - 1) / 2)
            if let paletteColor = chart.paletteColor(at: pulse) {
                let thread = library.thread(for: paletteColor.dmcCode)
                UIColor(hexString: thread?.hex ?? "#999999").withAlphaComponent(CGFloat(1 - t * 0.3)).setFill()
                let path = UIBezierPath(roundedRect: expanded, cornerRadius: cellSize * 0.18)
                path.fill()
            }
        }

        // Selection ring (editor R·C indicator).
        if let selected = lastTouchedCell {
            let row = selected / w
            let col = selected % w
            let rect = CGRect(
                x: CGFloat(col) * cellSize - contentOffset.x,
                y: CGFloat(row) * cellSize - contentOffset.y,
                width: cellSize,
                height: cellSize
            ).insetBy(dx: -1.5, dy: -1.5)
            UIColor(hexString: "#3E5F8A").setStroke()
            context.setLineWidth(2)
            context.stroke(rect)
        }
    }

    private func draw(_ symbol: String, in rect: CGRect, font: UIFont, color: UIColor) {
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let text = symbol as NSString
        let size = text.size(withAttributes: attributes)
        text.draw(at: CGPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2), withAttributes: attributes)
    }

    private static func luminance(_ color: UIColor) -> Double {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.2126 * Double(r) + 0.7152 * Double(g) + 0.0722 * Double(b)
    }

    // MARK: - Accessibility (visible cells speak row/column/DMC/state)

    private var accessibilityCells: [UIAccessibilityElement] = []

    private func refreshAccessibility() {
        guard cellSize >= 9, bounds.width > 0 else {
            accessibilityCells = []
            accessibilityElements = []
            return
        }
        let w = chart.widthCells
        let firstCol = max(0, Int(contentOffset.x / cellSize))
        let firstRow = max(0, Int(contentOffset.y / cellSize))
        let lastCol = min(w - 1, Int((contentOffset.x + bounds.width) / cellSize) + 1)
        let lastRow = min(chart.heightCells - 1, Int((contentOffset.y + bounds.height) / cellSize) + 1)

        var elements: [UIAccessibilityElement] = []
        let stitched: Set<Int>
        if case .stitch(let set, _) = mode { stitched = set } else { stitched = [] }

        for row in firstRow...lastRow {
            for col in firstCol...lastCol {
                let cellIndex = row * w + col
                guard let paletteColor = chart.paletteColor(at: cellIndex) else { continue }
                let element = UIAccessibilityElement(accessibilityContainer: self)
                element.accessibilityFrameInContainerSpace = CGRect(
                    x: CGFloat(col) * cellSize - contentOffset.x,
                    y: CGFloat(row) * cellSize - contentOffset.y,
                    width: cellSize,
                    height: cellSize
                )
                let state: String
                switch mode {
                case .stitch:
                    state = stitched.contains(cellIndex) ? "stitched" : "not stitched"
                default:
                    state = ""
                }
                element.accessibilityLabel = "row \(row + 1), column \(col + 1), DMC \(paletteColor.dmcCode)\(state.isEmpty ? "" : ", \(state)")"
                element.accessibilityTraits = .button
                elements.append(element)
            }
        }
        accessibilityCells = elements
        accessibilityElements = elements
    }
}
