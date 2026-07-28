import Foundation
import SwiftUI
import UIKit

enum AppTab: Hashable {
    case charts
    case create
    case stitch
    case threads
}

/// Single writer for all app state. Every mutation persists (debounced) so
/// progress survives process death (routes-and-states.md §状态红线).
@MainActor
final class AppStore: ObservableObject {

    enum LoadState: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    @Published private(set) var charts: [Chart] = []
    @Published private(set) var stash: [String: Int] = [:]
    @Published private(set) var ledger = CreditLedger()
    @Published private(set) var exportRecords: [ExportRecord] = []
    @Published var activeChartId: UUID?
    @Published private(set) var loadState: LoadState = .loading

    /// Cross-tab navigation intents.
    @Published var selectedTab: AppTab = .charts
    @Published var chartIdToOpen: UUID?

    private let localStore: LocalStore
    private var saveTask: Task<Void, Never>?

    init(localStore: LocalStore = .shared) {
        self.localStore = localStore
        load()
    }

    // MARK: - Load / save

    func load() {
        loadState = .loading
        do {
            if let state = try localStore.load() {
                charts = state.charts
                stash = state.stash
                ledger = state.ledger
                exportRecords = state.exportRecords
                activeChartId = state.activeChartId
                if !state.hasGrantedInitialCredits {
                    grantInitialCredits()
                }
            } else {
                grantInitialCredits()
            }
            loadState = .loaded
        } catch {
            // Friendly surface; details stay in the log, never on screen.
            print("[ThreadGrid] store load failed: \(error)")
            loadState = .failed("load")
        }
    }

    private func grantInitialCredits() {
        var txn = CreditTxn(
            kind: .grant,
            amount: CreditCatalog.initialBalance,
            note: "Welcome credits",
            storekitTransactionId: nil
        )
        txn.createdAt = Date()
        ledger.apply(txn)
        persist(immediately: true)
    }

    private func persist(immediately: Bool = false) {
        saveTask?.cancel()
        let state = PersistedState(
            charts: charts,
            stash: stash,
            ledger: ledger,
            exportRecords: exportRecords,
            activeChartId: activeChartId,
            hasGrantedInitialCredits: true
        )
        if immediately {
            try? localStore.save(state)
            return
        }
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            try? self?.localStore.save(state)
        }
    }

    /// Called on scene background — flush immediately so nothing is lost.
    func flush() {
        persist(immediately: true)
    }

    // MARK: - Charts

    func chart(with id: UUID) -> Chart? {
        charts.first(where: { $0.id == id })
    }

    @discardableResult
    func addChart(_ chart: Chart) -> Chart {
        charts.insert(chart, at: 0)
        persist()
        return chart
    }

    func updateChart(_ chart: Chart) {
        guard let index = charts.firstIndex(where: { $0.id == chart.id }) else { return }
        var updated = chart
        updated.updatedAt = Date()
        charts[index] = updated
        persist()
    }

    /// Applies an editor mutation: cells + palette are replaced wholesale and
    /// stitch counts recomputed. Stitching progress is kept — progress tracks
    /// cells, not colors (data-model.md §派生规则).
    func applyEdit(chartId: UUID, cells: Data, palette: [ChartColor]) {
        guard var chart = chart(with: chartId) else { return }
        chart.cells = cells
        chart.palette = palette
        chart.recomputeStitchCounts()
        updateChart(chart)
    }

    func deleteChart(_ chart: Chart) {
        charts.removeAll(where: { $0.id == chart.id })
        exportRecords.removeAll(where: { $0.chartId == chart.id })
        if activeChartId == chart.id { activeChartId = nil }
        // Cascade sandbox photo copies (ACC-012).
        if let source = chart.sourcePhotoPath { localStore.deletePhoto(relativePath: source) }
        if let finished = chart.finishedPhotoPath { localStore.deletePhoto(relativePath: finished) }
        persist(immediately: true)
    }

    func setActiveChart(_ id: UUID?) {
        activeChartId = id
        if let id, var chart = chart(with: id), chart.status == .draft {
            chart.status = .active
            updateChart(chart)
        }
        persist()
    }

    // MARK: - Stitching

    func toggleStitch(chartId: UUID, cellIndex: Int) {
        guard var chart = chart(with: chartId) else { return }
        if chart.stitchedCellIndices.contains(cellIndex) {
            chart.stitchedCellIndices.remove(cellIndex)
            if chart.status == .finished { chart.status = .active }
        } else {
            chart.stitchedCellIndices.insert(cellIndex)
        }
        updateChart(chart)
    }

    func markFinished(chartId: UUID) {
        guard var chart = chart(with: chartId) else { return }
        chart.status = .finished
        updateChart(chart)
    }

    func setFinishedPhoto(chartId: UUID, relativePath: String?) {
        guard var chart = chart(with: chartId) else { return }
        if let old = chart.finishedPhotoPath, old != relativePath {
            localStore.deletePhoto(relativePath: old)
        }
        chart.finishedPhotoPath = relativePath
        updateChart(chart)
    }

    // MARK: - Stash

    func setSkeinsOwned(_ skeins: Int, for dmcCode: String) {
        stash[dmcCode] = max(0, min(99, skeins))
        persist()
    }

    func skeinsOwned(for dmcCode: String) -> Int {
        stash[dmcCode] ?? 0
    }

    // MARK: - Credits & exports

    func creditPurchase(amount: Int, storekitTransactionId: String) {
        ledger.apply(CreditTxn(
            kind: .purchase,
            amount: amount,
            note: "Credit pack",
            storekitTransactionId: storekitTransactionId
        ))
        persist(immediately: true)
    }

    /// Deduction happens only after the PDF rendered successfully (checklist §9);
    /// export is refused up front when balance is insufficient.
    func consumeCredits(_ amount: Int, note: String) {
        ledger.apply(CreditTxn(
            kind: .consume,
            amount: -amount,
            note: note,
            storekitTransactionId: nil
        ))
        persist(immediately: true)
    }

    func recordExport(chartId: UUID, kind: ExportKind) {
        exportRecords.append(ExportRecord(chartId: chartId, kind: kind))
        persist()
    }

    // MARK: - Photos

    func saveSandboxPhoto(_ image: UIImage, prefix: String) -> String? {
        localStore.savePhoto(image, prefix: prefix)
    }

    func loadSandboxPhoto(relativePath: String) -> UIImage? {
        localStore.loadPhoto(relativePath: relativePath)
    }
}
