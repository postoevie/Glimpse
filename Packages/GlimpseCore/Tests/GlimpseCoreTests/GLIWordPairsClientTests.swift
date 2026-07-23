import Foundation
import SwiftData
import Testing
@testable import GlimpseCore

@Suite("GLIWordPairsClient")
struct GLIWordPairsClientTests {

    @Test("save then fetchAll returns the stored pair")
    func saveThenFetchAll() async throws {
        let client = try GLIWordPairsClient.inMemory()
        let pair = GLIWordPair(word: "hola", translation: "hello")

        try await client.save(pair)
        let loaded = try await client.fetchAll()

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
        let loaded = try await client.fetchAll()

        #expect(loaded.count == 2)
        let ids = Set(loaded.map(\.id))
        #expect(ids == [first.id, second.id])
        #expect(loaded.allSatisfy { $0.word == "hola" && $0.translation == "hello" })
    }

    @Test("word-only pair persists with empty translation")
    func wordOnlyEmptyTranslation() async throws {
        let container = try GLIModelContainerFactory.makeInMemory()
        let actor = GLIWordPairsModelActor(modelContainer: container)
        let pair = GLIWordPair(word: "merci", translation: "")

        try await actor.save(pair)
        let loaded = try await actor.fetchAll()

        #expect(loaded.count == 1)
        #expect(loaded[0].word == "merci")
        #expect(loaded[0].translation == "")
    }

    @Test("fetchAll on empty store returns empty array")
    func fetchAllEmpty() async throws {
        let client = try GLIWordPairsClient.inMemory()
        let loaded = try await client.fetchAll()
        #expect(loaded.isEmpty)
    }
}
