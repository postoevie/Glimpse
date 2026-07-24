import Foundation
import SwiftData

public struct GLIWordPairsClient: Sendable {
    public var fetchWordPairs: @Sendable () async throws -> [GLIWordPair]
    public var save: @Sendable (GLIWordPair) async throws -> Void
    public var changes: @Sendable () -> AsyncStream<Void>

    public init(
        fetchWordPairs: @escaping @Sendable () async throws -> [GLIWordPair],
        save: @escaping @Sendable (GLIWordPair) async throws -> Void,
        changes: @escaping @Sendable () -> AsyncStream<Void> = { AsyncStream { $0.finish() } }
    ) {
        self.fetchWordPairs = fetchWordPairs
        self.save = save
        self.changes = changes
    }
}

extension GLIWordPairsClient {
    public static func live(container: ModelContainer) -> GLIWordPairsClient {
        let actor = GLIModelActor(modelContainer: container)
        return GLIWordPairsClient(
            fetchWordPairs: { try await actor.fetchWordPairs() },
            save: { pair in try await actor.saveWordPair(pair) },
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

    public static func inMemory() throws -> GLIWordPairsClient {
        .live(container: try GLIModelContainerFactory.makeInMemory())
    }
}
