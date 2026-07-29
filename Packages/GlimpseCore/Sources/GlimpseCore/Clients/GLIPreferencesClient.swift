import Foundation
import IssueReporting

/// App Group preferences. T1 readiness: sticky default custom folder ID only
/// (set/prefill ownership is later; delete clears a matching stored ID).
public struct GLIPreferencesClient: Sendable {
    /// Loads the sticky default custom folder ID, or `nil` when unset.
    public var defaultCustomFolderID: @Sendable () -> UUID?
    /// Persists a custom folder ID as the sticky default.
    public var setDefaultCustomFolderID: @Sendable (UUID) -> Void
    /// Clears the sticky default custom folder ID.
    public var clearDefaultCustomFolderID: @Sendable () -> Void

    public init(
        defaultCustomFolderID: @escaping @Sendable () -> UUID?,
        setDefaultCustomFolderID: @escaping @Sendable (UUID) -> Void,
        clearDefaultCustomFolderID: @escaping @Sendable () -> Void
    ) {
        self.defaultCustomFolderID = defaultCustomFolderID
        self.setDefaultCustomFolderID = setDefaultCustomFolderID
        self.clearDefaultCustomFolderID = clearDefaultCustomFolderID
    }
}

extension GLIPreferencesClient {
    /// Stable App Group `UserDefaults` key for the sticky default custom folder ID.
    public static let defaultCustomFolderIDKey = "defaultCustomFolderID"

    public static func live(suiteName: String = GLIAppGroup.identifier) -> GLIPreferencesClient {
        guard UserDefaults(suiteName: suiteName) != nil else {
            reportIssue("App Group UserDefaults suite unavailable for preferences")
            return .empty
        }

        return GLIPreferencesClient(
            defaultCustomFolderID: {
                guard let defaults = UserDefaults(suiteName: suiteName) else {
                    reportIssue("App Group UserDefaults suite unavailable for preferences")
                    return nil
                }
                guard defaults.object(forKey: defaultCustomFolderIDKey) != nil else {
                    return nil
                }
                guard
                    let raw = defaults.string(forKey: defaultCustomFolderIDKey),
                    let folderID = UUID(uuidString: raw)
                else {
                    reportIssue("Malformed default custom folder ID; clearing")
                    defaults.removeObject(forKey: defaultCustomFolderIDKey)
                    return nil
                }
                return folderID
            },
            setDefaultCustomFolderID: { folderID in
                guard let defaults = UserDefaults(suiteName: suiteName) else {
                    reportIssue("App Group UserDefaults suite unavailable for preferences")
                    return
                }
                defaults.set(folderID.uuidString, forKey: defaultCustomFolderIDKey)
            },
            clearDefaultCustomFolderID: {
                guard let defaults = UserDefaults(suiteName: suiteName) else {
                    reportIssue("App Group UserDefaults suite unavailable for preferences")
                    return
                }
                defaults.removeObject(forKey: defaultCustomFolderIDKey)
            }
        )
    }

    /// In-memory client for tests and previews.
    public static func inMemory(initialDefaultCustomFolderID: UUID? = nil) -> GLIPreferencesClient {
        let storage = InMemoryStorage(defaultCustomFolderID: initialDefaultCustomFolderID)
        return GLIPreferencesClient(
            defaultCustomFolderID: { storage.load() },
            setDefaultCustomFolderID: { storage.set($0) },
            clearDefaultCustomFolderID: { storage.clear() }
        )
    }

    /// No-op client when the App Group suite cannot be opened.
    private static var empty: GLIPreferencesClient {
        GLIPreferencesClient(
            defaultCustomFolderID: { nil },
            setDefaultCustomFolderID: { _ in },
            clearDefaultCustomFolderID: {}
        )
    }
}

// MARK: - In-memory storage

private final class InMemoryStorage: @unchecked Sendable {
    private let lock = NSLock()
    private var defaultCustomFolderID: UUID?

    init(defaultCustomFolderID: UUID?) {
        self.defaultCustomFolderID = defaultCustomFolderID
    }

    func load() -> UUID? {
        lock.lock()
        defer { lock.unlock() }
        return defaultCustomFolderID
    }

    func set(_ id: UUID) {
        lock.lock()
        defer { lock.unlock() }
        defaultCustomFolderID = id
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        defaultCustomFolderID = nil
    }
}
