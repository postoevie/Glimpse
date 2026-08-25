import Foundation
import SwiftData

public struct GLIWordMeaningsClient: Sendable {
    /// Stored meanings for a word pair, oldest creation date first. See `GLIModelActor.fetchMeanings`.
    public var fetch: @Sendable (_ wordPairID: GLIWordPair.ID) async throws -> [GLIWordMeaning]

    /// Reconciles stored meanings for a word pair by `id` in one transaction.
    /// See `GLIModelActor.replaceMeanings`.
    public var replaceAll: @Sendable (
        _ wordPairID: GLIWordPair.ID,
        _ meanings: [GLIWordMeaning]
    ) async throws -> Void

    /// Oldest meaning text for each id. Pairs with no meanings are omitted.
    public var firstMeanings: @Sendable (
        _ wordPairIDs: [GLIWordPair.ID]
    ) async throws -> [GLIWordPair.ID: String]

    /// All meanings for each id, oldest first. Missing keys = no meanings.
    public var fetchAll: @Sendable (
        _ wordPairIDs: [GLIWordPair.ID]
    ) async throws -> [GLIWordPair.ID: [GLIWordMeaning]]

    public init(
        fetch: @escaping @Sendable (_ wordPairID: GLIWordPair.ID) async throws -> [GLIWordMeaning],
        replaceAll: @escaping @Sendable (
            _ wordPairID: GLIWordPair.ID,
            _ meanings: [GLIWordMeaning]
        ) async throws -> Void,
        firstMeanings: @escaping @Sendable (
            _ wordPairIDs: [GLIWordPair.ID]
        ) async throws -> [GLIWordPair.ID: String],
        fetchAll: @escaping @Sendable (
            _ wordPairIDs: [GLIWordPair.ID]
        ) async throws -> [GLIWordPair.ID: [GLIWordMeaning]]
    ) {
        self.fetch = fetch
        self.replaceAll = replaceAll
        self.firstMeanings = firstMeanings
        self.fetchAll = fetchAll
    }
}

extension GLIWordMeaningsClient {
    public static func live(container: ModelContainer) -> GLIWordMeaningsClient {
        live(actor: GLIModelActor(modelContainer: container))
    }

    public static func live(actor: GLIModelActor) -> GLIWordMeaningsClient {
        GLIWordMeaningsClient(
            fetch: { wordPairID in
                try await actor.fetchMeanings(wordPairID: wordPairID)
            },
            replaceAll: { wordPairID, meanings in
                try await actor.replaceMeanings(wordPairID: wordPairID, meanings: meanings)
            },
            firstMeanings: { wordPairIDs in
                try await actor.firstMeaningTexts(for: wordPairIDs)
            },
            fetchAll: { wordPairIDs in
                try await actor.fetchAllMeanings(for: wordPairIDs)
            }
        )
    }

    public static func inMemory() throws -> GLIWordMeaningsClient {
        .live(container: try GLIModelContainerFactory.makeInMemory())
    }
}
