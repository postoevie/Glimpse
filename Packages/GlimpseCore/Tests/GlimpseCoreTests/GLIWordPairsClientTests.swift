import Foundation
import SwiftData
import Testing
@testable import GlimpseCore

@Suite("GLIWordPairsClient")
struct GLIWordPairsClientTests {

    @Test("save then fetchWordPairs returns the stored pair")
    func saveThenFetchWordPairs() async throws {
        let client = try GLIWordPairsClient.inMemory()
        let pair = GLIWordPair(word: "hola")

        try await client.save(pair)
        let loaded = try await client.fetchWordPairs()

        #expect(loaded.count == 1)
        #expect(loaded[0].id == pair.id)
        #expect(loaded[0].word == "hola")
    }

    @Test("duplicate text is allowed as two rows with different ids")
    func duplicateTextAllowed() async throws {
        let client = try GLIWordPairsClient.inMemory()
        let first = GLIWordPair(word: "hola")
        let second = GLIWordPair(word: "hola")

        #expect(first.id != second.id)

        try await client.save(first)
        try await client.save(second)
        let loaded = try await client.fetchWordPairs()

        #expect(loaded.count == 2)
        let ids = Set(loaded.map(\.id))
        #expect(ids == [first.id, second.id])
        #expect(loaded.allSatisfy { $0.word == "hola" })
    }

    @Test("fetchWordPairs on empty store returns empty array")
    func fetchWordPairsEmpty() async throws {
        let client = try GLIWordPairsClient.inMemory()
        let loaded = try await client.fetchWordPairs()
        #expect(loaded.isEmpty)
    }

    @Test("fetchWordPairsInFolder on empty folder returns empty array")
    func fetchWordPairsInFolderEmpty() async throws {
        let container = try GLIModelContainerFactory.makeInMemory()
        let context = ModelContext(container)
        let folder = GLILanguageFolderEntity(languageCode: "es")
        context.insert(folder)
        try context.save()

        let client = GLIWordPairsClient.live(container: container)
        let loaded = try await client.fetchWordPairsInFolder(folder.id)
        #expect(loaded.isEmpty)
    }

    @Test("fetchWordPairsInFolder on unknown folder id returns empty array")
    func fetchWordPairsInFolderUnknown() async throws {
        let client = try GLIWordPairsClient.inMemory()
        let unknownID = UUID(uuidString: "00000000-0000-0000-0000-00000000DEAD")!
        let loaded = try await client.fetchWordPairsInFolder(unknownID)
        #expect(loaded.isEmpty)
    }

    @Test("fetchWordPairsInFolder returns only that folder’s pairs")
    func fetchWordPairsInFolderScoped() async throws {
        let container = try GLIModelContainerFactory.makeInMemory()
        let wordPairs = GLIWordPairsClient.live(container: container)
        let folders = GLILanguageFoldersClient.live(container: container)

        let esPair = GLIWordPair(word: "hola", sourceLanguage: "es")
        let frPair = GLIWordPair(word: "bonjour", sourceLanguage: "fr")
        try await wordPairs.save(esPair)
        try await wordPairs.save(frPair)

        let languageFolders = try await folders.fetchLanguageFolders()
        let esFolder = try #require(languageFolders.first { $0.languageCode == "es" })
        let loaded = try await wordPairs.fetchWordPairsInFolder(esFolder.id)

        #expect(loaded.count == 1)
        #expect(loaded[0].id == esPair.id)
        #expect(loaded[0].word == "hola")
    }

    @Test("fetchWordPairsInFolder orders newest first")
    func fetchWordPairsInFolderNewestFirst() async throws {
        let container = try GLIModelContainerFactory.makeInMemory()
        let context = ModelContext(container)
        let folder = GLILanguageFolderEntity(languageCode: "es")
        context.insert(folder)

        let older = GLIWordPairEntity(
            word: "old",
            sourceLanguage: "es",
            createdAt: Date(timeIntervalSince1970: 1),
            languageFolder: folder
        )
        let newer = GLIWordPairEntity(
            word: "new",
            sourceLanguage: "es",
            createdAt: Date(timeIntervalSince1970: 100),
            languageFolder: folder
        )
        context.insert(older)
        context.insert(newer)
        try context.save()

        let client = GLIWordPairsClient.live(container: container)
        let loaded = try await client.fetchWordPairsInFolder(folder.id)

        #expect(loaded.map(\.word) == ["new", "old"])
    }
}
