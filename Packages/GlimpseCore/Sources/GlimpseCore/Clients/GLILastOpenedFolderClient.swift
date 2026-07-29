import Foundation
import IssueReporting

/// Persists the last opened folder (language or Unsorted) or root for cold-launch resume.
/// Does not store navigation path, card, sheet, search, or scroll state.
public struct GLILastOpenedFolderClient: Sendable {
    /// Loads the stored folder ID, or `nil` for root.
    /// Missing, malformed, or cleared values yield `nil` (root).
    public var load: @Sendable () -> UUID?
    /// Persists a folder ID as the resume destination.
    public var saveFolder: @Sendable (UUID) -> Void
    /// Clears persistence so the next cold launch opens root.
    public var clearToRoot: @Sendable () -> Void

    public init(
        load: @escaping @Sendable () -> UUID?,
        saveFolder: @escaping @Sendable (UUID) -> Void,
        clearToRoot: @escaping @Sendable () -> Void
    ) {
        self.load = load
        self.saveFolder = saveFolder
        self.clearToRoot = clearToRoot
    }
}

extension GLILastOpenedFolderClient {
    /// Stable App Group `UserDefaults` key for the last opened folder ID.
    public static let storageKey = "lastOpenedFolderID"

    public static func live(suiteName: String = GLIAppGroup.identifier) -> GLILastOpenedFolderClient {
        guard UserDefaults(suiteName: suiteName) != nil else {
            reportIssue("App Group UserDefaults suite unavailable for last-opened folder")
            return .rootOnly
        }

        return GLILastOpenedFolderClient(
            load: {
                guard let defaults = UserDefaults(suiteName: suiteName) else {
                    reportIssue("App Group UserDefaults suite unavailable for last-opened folder")
                    return nil
                }
                guard defaults.object(forKey: storageKey) != nil else {
                    return nil
                }
                guard
                    let raw = defaults.string(forKey: storageKey),
                    let folderID = UUID(uuidString: raw)
                else {
                    reportIssue("Malformed last-opened folder ID; clearing to root")
                    defaults.removeObject(forKey: storageKey)
                    return nil
                }
                return folderID
            },
            saveFolder: { folderID in
                guard let defaults = UserDefaults(suiteName: suiteName) else {
                    reportIssue("App Group UserDefaults suite unavailable for last-opened folder")
                    return
                }
                defaults.set(folderID.uuidString, forKey: storageKey)
            },
            clearToRoot: {
                guard let defaults = UserDefaults(suiteName: suiteName) else {
                    reportIssue("App Group UserDefaults suite unavailable for last-opened folder")
                    return
                }
                defaults.removeObject(forKey: storageKey)
            }
        )
    }

    /// In-memory client for tests and previews.
    public static func inMemory(initialFolderID: UUID? = nil) -> GLILastOpenedFolderClient {
        let storage = InMemoryStorage(folderID: initialFolderID)
        return GLILastOpenedFolderClient(
            load: { storage.load() },
            saveFolder: { storage.saveFolder($0) },
            clearToRoot: { storage.clearToRoot() }
        )
    }

    /// Always reports root; used when the App Group suite cannot be opened.
    private static var rootOnly: GLILastOpenedFolderClient {
        GLILastOpenedFolderClient(
            load: { nil },
            saveFolder: { _ in },
            clearToRoot: {}
        )
    }
}

// MARK: - In-memory storage

private final class InMemoryStorage: @unchecked Sendable {
    private let lock = NSLock()
    private var folderID: UUID?

    init(folderID: UUID?) {
        self.folderID = folderID
    }

    func load() -> UUID? {
        lock.lock()
        defer { lock.unlock() }
        return folderID
    }

    func saveFolder(_ id: UUID) {
        lock.lock()
        defer { lock.unlock() }
        folderID = id
    }

    func clearToRoot() {
        lock.lock()
        defer { lock.unlock() }
        folderID = nil
    }
}
