import Foundation
import SwiftData

public struct GLILanguageFoldersClient: Sendable {
    public var fetchLanguageFolders: @Sendable () async throws -> [GLILanguageFolder]

    public init(
        fetchLanguageFolders: @escaping @Sendable () async throws -> [GLILanguageFolder]
    ) {
        self.fetchLanguageFolders = fetchLanguageFolders
    }
}

extension GLILanguageFoldersClient {
    public static func live(container: ModelContainer) -> GLILanguageFoldersClient {
        let actor = GLIModelActor(modelContainer: container)
        return GLILanguageFoldersClient(
            fetchLanguageFolders: { try await actor.fetchLanguageFolders() }
        )
    }

    public static func inMemory() throws -> GLILanguageFoldersClient {
        .live(container: try GLIModelContainerFactory.makeInMemory())
    }
}
