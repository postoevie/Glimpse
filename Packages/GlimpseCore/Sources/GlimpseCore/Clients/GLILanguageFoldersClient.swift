import Foundation
import SwiftData

public struct GLILanguageFoldersClient: Sendable {
    public var fetchLanguageFolders: @Sendable () async throws -> [GLILanguageFolder]
    public var fetchLanguageFolder: @Sendable (UUID) async throws -> GLILanguageFolder?

    public init(
        fetchLanguageFolders: @escaping @Sendable () async throws -> [GLILanguageFolder],
        fetchLanguageFolder: @escaping @Sendable (UUID) async throws -> GLILanguageFolder? = { _ in nil }
    ) {
        self.fetchLanguageFolders = fetchLanguageFolders
        self.fetchLanguageFolder = fetchLanguageFolder
    }
}

extension GLILanguageFoldersClient {
    public static func live(container: ModelContainer) -> GLILanguageFoldersClient {
        let actor = GLIModelActor(modelContainer: container)
        return GLILanguageFoldersClient(
            fetchLanguageFolders: { try await actor.fetchLanguageFolders() },
            fetchLanguageFolder: { id in try await actor.fetchLanguageFolder(id: id) }
        )
    }

    public static func inMemory() throws -> GLILanguageFoldersClient {
        .live(container: try GLIModelContainerFactory.makeInMemory())
    }
}
