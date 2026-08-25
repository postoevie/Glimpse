import Foundation
import SwiftData
import Testing
@testable import GlimpseCore

@Suite("GLICardMutations")
struct GLICardMutationsTests {
    private let wordID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let folderID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    private let createdAt = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("update changes editable fields and preserves identity, source, folder, and creation date")
    @MainActor
    func updatePreservesLockedFields() async throws {
        let container = try makeContainerWithWord(meaningText: "old meaning")
        let actor = GLIModelActor(modelContainer: container)

        let updated = try await actor.update(
            GLIWordCardUpdate(
                wordID: wordID,
                word: "bonjour",
                targetLanguage: "en"
            )
        )

        #expect(updated.id == wordID)
        #expect(updated.word == "bonjour")
        #expect(updated.sourceLanguage == "es")
        #expect(updated.targetLanguage == "en")

        let entity = try #require(try fetchWord(id: wordID, from: container))
        #expect(entity.createdAt == createdAt)
        #expect(entity.languageFolder?.id == folderID)
        #expect(entity.languageFolder?.languageCode == "es")
        // update() does not touch meanings — that's a separate write via GLIWordMeaningsClient.
        #expect(try fetchMeanings(wordPairID: wordID, from: container).map(\.text) == ["old meaning"])
    }

    @Test("delete removes word and its meanings but keeps permanent folder")
    @MainActor
    func deletePreservesFolder() async throws {
        let container = try makeContainerWithWord(meaningText: "meaning")
        let actor = GLIModelActor(modelContainer: container)

        try await actor.delete(wordID: wordID)

        #expect(try fetchWord(id: wordID, from: container) == nil)
        #expect(try fetchMeanings(wordPairID: wordID, from: container).isEmpty)

        let context = ModelContext(container)
        let folders = try context.fetch(FetchDescriptor<GLILanguageFolderEntity>())
        #expect(folders.count == 1)
        #expect(folders.first?.id == folderID)
        #expect(folders.first?.items.isEmpty == true)
    }

    @Test("delete with multiple meanings removes all of them")
    @MainActor
    func deleteRemovesAllMeanings() async throws {
        let container = try makeContainerWithWord()
        let actor = GLIModelActor(modelContainer: container)
        try await actor.replaceMeanings(
            wordPairID: wordID,
            meanings: [
                GLIWordMeaning(text: "first"),
                GLIWordMeaning(text: "second"),
            ]
        )

        try await actor.delete(wordID: wordID)

        #expect(try fetchMeanings(wordPairID: wordID, from: container).isEmpty)
    }

    @Test("missing IDs fail predictably without creating meanings")
    @MainActor
    func missingIDsFailPredictably() async throws {
        let container = try GLIModelContainerFactory.makeInMemory()
        let actor = GLIModelActor(modelContainer: container)

        await #expect(throws: GLICardMutationsError.wordNotFound(wordID)) {
            try await actor.update(
                GLIWordCardUpdate(
                    wordID: wordID,
                    word: "missing",
                    targetLanguage: nil
                )
            )
        }
        await #expect(throws: GLICardMutationsError.wordNotFound(wordID)) {
            try await actor.delete(wordID: wordID)
        }

        #expect(try fetchMeanings(wordPairID: wordID, from: container).isEmpty)
    }

    @Test("shared actor clients observe one persistence state")
    @MainActor
    func sharedActorClientsStayConsistent() async throws {
        let container = try GLIModelContainerFactory.makeInMemory()
        let actor = GLIModelActor(modelContainer: container)
        let wordPairs = GLIWordPairsClient.live(actor: actor)
        let meanings = GLIWordMeaningsClient.live(actor: actor)
        let mutations = GLICardMutationsClient.live(actor: actor)
        let pair = GLIWordPair(
            id: wordID,
            word: "hola",
            sourceLanguage: "es",
            targetLanguage: "en"
        )

        try await wordPairs.save(pair)
        let updated = try await mutations.update(
            GLIWordCardUpdate(
                wordID: wordID,
                word: "hola!",
                targetLanguage: "fr"
            )
        )
        try await meanings.replaceAll(wordID, [GLIWordMeaning(text: "hello!", example: "¡Hola!")])

        let fetched = try await wordPairs.fetchWordPairs()
        #expect(fetched == [updated])
        let storedMeanings = try await meanings.fetch(wordID)
        #expect(storedMeanings.map(\.text) == ["hello!"])
        #expect(storedMeanings.first?.example == "¡Hola!")

        try await mutations.delete(wordID)
        #expect(try await wordPairs.fetchWordPairs().isEmpty)
        #expect(try await meanings.fetch(wordID).isEmpty)
    }

    @MainActor
    private func makeContainerWithWord(meaningText: String? = nil) throws -> ModelContainer {
        let container = try GLIModelContainerFactory.makeInMemory()
        let context = ModelContext(container)
        let folder = GLILanguageFolderEntity(id: folderID, languageCode: "es")
        let word = GLIWordPairEntity(
            id: wordID,
            word: "hola",
            sourceLanguage: "es",
            targetLanguage: "en",
            createdAt: createdAt,
            languageFolder: folder
        )
        context.insert(folder)
        context.insert(word)
        if let meaningText {
            context.insert(GLIWordMeaningEntity(wordPairID: wordID, text: meaningText))
        }
        try context.save()
        return container
    }

    @MainActor
    private func fetchWord(
        id: UUID,
        from container: ModelContainer
    ) throws -> GLIWordPairEntity? {
        let id = id
        var descriptor = FetchDescriptor<GLIWordPairEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try ModelContext(container).fetch(descriptor).first
    }

    @MainActor
    private func fetchMeanings(
        wordPairID: UUID,
        from container: ModelContainer
    ) throws -> [GLIWordMeaningEntity] {
        let wordPairID = wordPairID
        let descriptor = FetchDescriptor<GLIWordMeaningEntity>(
            predicate: #Predicate { $0.wordPairID == wordPairID }
        )
        return try ModelContext(container).fetch(descriptor)
    }
}
