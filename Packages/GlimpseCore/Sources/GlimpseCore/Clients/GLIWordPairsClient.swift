import Foundation
import SwiftData

public struct GLIWordPairsClient: Sendable {
    public var fetchAll: @Sendable () async throws -> [GLIWordPair]
    public var save: @Sendable (GLIWordPair) async throws -> Void
    public var changes: @Sendable () -> AsyncStream<Void>

    public init(
        fetchAll: @escaping @Sendable () async throws -> [GLIWordPair],
        save: @escaping @Sendable (GLIWordPair) async throws -> Void,
        changes: @escaping @Sendable () -> AsyncStream<Void> = { AsyncStream { $0.finish() } }
    ) {
        self.fetchAll = fetchAll
        self.save = save
        self.changes = changes
    }
}

extension GLIWordPairsClient {
    public static func live(container: ModelContainer) -> GLIWordPairsClient {
        let actor = GLIWordPairsModelActor(modelContainer: container)
        return GLIWordPairsClient(
            fetchAll: { try await actor.fetchAll() },
            save: { pair in try await actor.save(pair) },
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
