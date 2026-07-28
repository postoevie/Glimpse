import Foundation
import SwiftData

public struct GLIWordExamplesClient: Sendable {
    public var fetchExample: @Sendable (GLIWordPair.ID) async throws -> String

    public init(
        fetchExample: @escaping @Sendable (GLIWordPair.ID) async throws -> String
    ) {
        self.fetchExample = fetchExample
    }
}

extension GLIWordExamplesClient {
    public static func live(container: ModelContainer) -> GLIWordExamplesClient {
        live(actor: GLIModelActor(modelContainer: container))
    }

    public static func live(actor: GLIModelActor) -> GLIWordExamplesClient {
        GLIWordExamplesClient(
            fetchExample: { wordID in
                try await actor.fetchExample(for: wordID)
            }
        )
    }

    public static func inMemory() throws -> GLIWordExamplesClient {
        .live(container: try GLIModelContainerFactory.makeInMemory())
    }
}
