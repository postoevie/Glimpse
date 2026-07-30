import Foundation
import SwiftData

public struct GLICustomFoldersClient: Sendable {
    public var fetch: @Sendable () async throws -> [GLICustomFolder]
    public var fetchCustomFolder: @Sendable (UUID) async throws -> GLICustomFolder?
    public var create: @Sendable (_ name: String, _ sourceLanguage: String) async throws -> GLICustomFolder
    public var rename: @Sendable (UUID, String) async throws -> GLICustomFolder
    public var delete: @Sendable (UUID) async throws -> Void
    public var changes: @Sendable () -> AsyncStream<Void>

    public init(
        fetch: @escaping @Sendable () async throws -> [GLICustomFolder],
        fetchCustomFolder: @escaping @Sendable (UUID) async throws -> GLICustomFolder? = { _ in nil },
        create: @escaping @Sendable (_ name: String, _ sourceLanguage: String) async throws -> GLICustomFolder,
        rename: @escaping @Sendable (UUID, String) async throws -> GLICustomFolder,
        delete: @escaping @Sendable (UUID) async throws -> Void,
        changes: @escaping @Sendable () -> AsyncStream<Void> = { AsyncStream { $0.finish() } }
    ) {
        self.fetch = fetch
        self.fetchCustomFolder = fetchCustomFolder
        self.create = create
        self.rename = rename
        self.delete = delete
        self.changes = changes
    }
}

extension GLICustomFoldersClient {
    public static func live(
        container: ModelContainer,
        preferences: GLIPreferencesClient = .live()
    ) -> GLICustomFoldersClient {
        live(actor: GLIModelActor(modelContainer: container), preferences: preferences)
    }

    public static func live(
        actor: GLIModelActor,
        preferences: GLIPreferencesClient = .live()
    ) -> GLICustomFoldersClient {
        GLICustomFoldersClient(
            fetch: { try await actor.fetchCustomFolders() },
            fetchCustomFolder: { id in try await actor.fetchCustomFolder(id: id) },
            create: { name, sourceLanguage in
                try await actor.createCustomFolder(name: name, sourceLanguage: sourceLanguage)
            },
            rename: { id, name in try await actor.renameCustomFolder(id: id, name: name) },
            delete: { id in
                try await actor.deleteCustomFolder(id: id)
                if preferences.defaultCustomFolderID() == id {
                    preferences.clearDefaultCustomFolderID()
                }
            },
            changes: {
                AsyncStream { continuation in
                    nonisolated(unsafe) let observer = NotificationCenter.default.addObserver(
                        forName: ModelContext.didSave,
                        object: nil,
                        queue: nil
                    ) { _ in
                        continuation.yield(())
                    }
                    continuation.onTermination = { _ in
                        NotificationCenter.default.removeObserver(observer)
                    }
                }
            }
        )
    }

    public static func inMemory() throws -> GLICustomFoldersClient {
        .live(container: try GLIModelContainerFactory.makeInMemory())
    }
}
