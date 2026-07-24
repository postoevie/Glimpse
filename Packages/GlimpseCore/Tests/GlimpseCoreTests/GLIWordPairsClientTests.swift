import Foundation
import SwiftData
import Testing
@testable import GlimpseCore

@Suite("GLIWordPairsClient")
struct GLIWordPairsClientTests {

    @Test("save then fetchWordPairs returns the stored pair")
    func saveThenFetchWordPairs() async throws {
        let client = try GLIWordPairsClient.inMemory()
        let pair = GLIWordPair(word: "hola", translation: "hello")

        try await client.save(pair)
        let loaded = try await client.fetchWordPairs()

        #expect(loaded.count == 1)
        #expect(loaded[0].id == pair.id)
        #expect(loaded[0].word == "hola")
        #expect(loaded[0].translation == "hello")
    }

    @Test("duplicate text is allowed as two rows with different ids")
    func duplicateTextAllowed() async throws {
        let client = try GLIWordPairsClient.inMemory()
        let first = GLIWordPair(word: "hola", translation: "hello")
        let second = GLIWordPair(word: "hola", translation: "hello")

        #expect(first.id != second.id)

        try await client.save(first)
        try await client.save(second)
        let loaded = try await client.fetchWordPairs()

        #expect(loaded.count == 2)
        let ids = Set(loaded.map(\.id))
        #expect(ids == [first.id, second.id])
        #expect(loaded.allSatisfy { $0.word == "hola" && $0.translation == "hello" })
    }

    @Test("word-only pair persists with empty translation")
    func wordOnlyEmptyTranslation() async throws {
        let container = try GLIModelContainerFactory.makeInMemory()
        let actor = GLIModelActor(modelContainer: container)
        let pair = GLIWordPair(word: "merci", translation: "")

        try await actor.saveWordPair(pair)
        let loaded = try await actor.fetchWordPairs()

        #expect(loaded.count == 1)
        #expect(loaded[0].word == "merci")
        #expect(loaded[0].translation == "")
    }

    @Test("fetchWordPairs on empty store returns empty array")
    func fetchWordPairsEmpty() async throws {
        let client = try GLIWordPairsClient.inMemory()
        let loaded = try await client.fetchWordPairs()
        #expect(loaded.isEmpty)
    }
}
