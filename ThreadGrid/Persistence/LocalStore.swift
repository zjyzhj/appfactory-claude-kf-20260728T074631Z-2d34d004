import Foundation
import UIKit

struct PersistedState: Codable {
    var charts: [Chart]
    var stash: [String: Int] // dmcCode -> skeinsOwned
    var ledger: CreditLedger
    var exportRecords: [ExportRecord]
    var activeChartId: UUID?
    var hasGrantedInitialCredits: Bool
}

/// File-based local persistence. Everything lives in the app sandbox —
/// zero account, zero cloud, photos never leave the device.
final class LocalStore {
    static let shared = LocalStore()

    private let fileManager = FileManager.default
    private let baseDirectory: URL
    private let photosDirectory: URL
    private let stateURL: URL

    init(baseDirectory: URL? = nil) {
        let base: URL
        if let baseDirectory {
            base = baseDirectory
        } else {
            let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            base = support.appendingPathComponent("ThreadGrid", isDirectory: true)
        }
        self.baseDirectory = base
        self.photosDirectory = base.appendingPathComponent("Photos", isDirectory: true)
        self.stateURL = base.appendingPathComponent("store.json")
        try? fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
    }

    // MARK: - State

    func load() throws -> PersistedState? {
        guard fileManager.fileExists(atPath: stateURL.path) else { return nil }
        let data = try Data(contentsOf: stateURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(PersistedState.self, from: data)
    }

    func save(_ state: PersistedState) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(state)
        try data.write(to: stateURL, options: .atomic)
    }

    // MARK: - Photos (sandbox copies, referenced by relative path)

    func savePhoto(_ image: UIImage, prefix: String) -> String? {
        let name = "\(prefix)-\(UUID().uuidString).jpg"
        let url = photosDirectory.appendingPathComponent(name)
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        do {
            try data.write(to: url, options: .atomic)
            return "Photos/\(name)"
        } catch {
            return nil
        }
    }

    func loadPhoto(relativePath: String) -> UIImage? {
        let url = baseDirectory.appendingPathComponent(relativePath)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func deletePhoto(relativePath: String) {
        let url = baseDirectory.appendingPathComponent(relativePath)
        try? fileManager.removeItem(at: url)
    }
}
