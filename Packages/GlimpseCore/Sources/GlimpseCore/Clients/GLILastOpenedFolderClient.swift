import Foundation
import IssueReporting

/// Last opened folder destination for cold-launch resume: language or custom, plus UUID.
/// Does not store navigation path, card, sheet, search, or scroll state.
///
/// Wire format (single string): `language:<uuid>` or `custom:<uuid>`.
public enum GLILastOpenedFolder: Equatable, Sendable, Codable {
    case language(UUID)
    case custom(UUID)

    private static let languagePrefix = "language:"
    private static let customPrefix = "custom:"

    public var id: UUID {
        switch self {
        case .language(let id), .custom(let id):
            return id
        }
    }

    /// Canonical UserDefaults string for this destination (`language:` / `custom:` prefixed).
    public var persistedString: String {
        switch self {
        case .language(let id):
            return Self.languagePrefix + id.uuidString
        case .custom(let id):
            return Self.customPrefix + id.uuidString
        }
    }

    /// Parses a stored string. Accepts only `language:<uuid>` or `custom:<uuid>`.
    public init?(persistedString raw: String) {
        if raw.hasPrefix(Self.languagePrefix) {
            let idPart = String(raw.dropFirst(Self.languagePrefix.count))
            guard let id = UUID(uuidString: idPart) else { return nil }
            self = .language(id)
            return
        }

        if raw.hasPrefix(Self.customPrefix) {
            let idPart = String(raw.dropFirst(Self.customPrefix.count))
            guard let id = UUID(uuidString: idPart) else { return nil }
            self = .custom(id)
            return
        }

        return nil
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(persistedString)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let value = Self(persistedString: raw) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid last-opened folder string: \(raw)"
            )
        }
        self = value
    }
}

/// Persists the last opened folder (kind + id) or root for cold-launch resume.
public struct GLILastOpenedFolderClient: Sendable {
    /// Loads the stored destination, or `nil` for root.
    /// Missing, malformed, or cleared values yield `nil` (root).
    public var load: @Sendable () -> GLILastOpenedFolder?
    /// Persists a folder destination as the resume target.
    public var save: @Sendable (GLILastOpenedFolder) -> Void
    /// Clears persistence so the next cold launch opens root.
    public var clearToRoot: @Sendable () -> Void

    public init(
        load: @escaping @Sendable () -> GLILastOpenedFolder?,
        save: @escaping @Sendable (GLILastOpenedFolder) -> Void,
        clearToRoot: @escaping @Sendable () -> Void
    ) {
        self.load = load
        self.save = save
        self.clearToRoot = clearToRoot
    }
}

extension GLILastOpenedFolderClient {
    /// Stable App Group `UserDefaults` key for the last opened folder.
    /// Value format is owned by ``GLILastOpenedFolder/persistedString``.
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
                guard let raw = defaults.string(forKey: storageKey) else {
                    reportIssue("Malformed last-opened folder; clearing to root")
                    defaults.removeObject(forKey: storageKey)
                    return nil
                }
                guard let destination = GLILastOpenedFolder(persistedString: raw) else {
                    reportIssue("Malformed last-opened folder; clearing to root")
                    defaults.removeObject(forKey: storageKey)
                    return nil
                }
                return destination
            },
            save: { destination in
                guard let defaults = UserDefaults(suiteName: suiteName) else {
                    reportIssue("App Group UserDefaults suite unavailable for last-opened folder")
                    return
                }
                defaults.set(destination.persistedString, forKey: storageKey)
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
    public static func inMemory(initial: GLILastOpenedFolder? = nil) -> GLILastOpenedFolderClient {
        let storage = InMemoryStorage(destination: initial)
        return GLILastOpenedFolderClient(
            load: { storage.load() },
            save: { storage.save($0) },
            clearToRoot: { storage.clearToRoot() }
        )
    }

    /// Always reports root; used when the App Group suite cannot be opened.
    private static var rootOnly: GLILastOpenedFolderClient {
        GLILastOpenedFolderClient(
            load: { nil },
            save: { _ in },
            clearToRoot: {}
        )
    }
}

// MARK: - In-memory storage

private final class InMemoryStorage: @unchecked Sendable {
    private let lock = NSLock()
    private var destination: GLILastOpenedFolder?

    init(destination: GLILastOpenedFolder?) {
        self.destination = destination
    }

    func load() -> GLILastOpenedFolder? {
        lock.lock()
        defer { lock.unlock() }
        return destination
    }

    func save(_ destination: GLILastOpenedFolder) {
        lock.lock()
        defer { lock.unlock() }
        self.destination = destination
    }

    func clearToRoot() {
        lock.lock()
        defer { lock.unlock() }
        destination = nil
    }
}
