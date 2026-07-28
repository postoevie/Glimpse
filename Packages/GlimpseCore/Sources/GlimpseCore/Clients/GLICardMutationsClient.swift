import Foundation
import SwiftData

public enum GLICardMutationsError: Error, Equatable, Sendable {
    case wordNotFound(GLIWordPair.ID)
}

public struct GLICardMutationsClient: Sendable {
    public var update: @Sendable (GLIWordCardUpdate) async throws -> GLIWordPair
    public var delete: @Sendable (GLIWordPair.ID) async throws -> Void

    public init(
        update: @escaping @Sendable (GLIWordCardUpdate) async throws -> GLIWordPair,
        delete: @escaping @Sendable (GLIWordPair.ID) async throws -> Void
    ) {
        self.update = update
        self.delete = delete
    }
}

extension GLICardMutationsClient {
    public static func live(container: ModelContainer) -> GLICardMutationsClient {
        live(actor: GLIModelActor(modelContainer: container))
    }

    public static func live(actor: GLIModelActor) -> GLICardMutationsClient {
        GLICardMutationsClient(
            update: { update in
                try await actor.update(update)
            },
            delete: { wordID in
                try await actor.delete(wordID: wordID)
            }
        )
    }

    public static func inMemory() throws -> GLICardMutationsClient {
        .live(container: try GLIModelContainerFactory.makeInMemory())
    }
}
