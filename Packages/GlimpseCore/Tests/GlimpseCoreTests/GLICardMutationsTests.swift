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
        let container = try makeContainerWithWord(example: "Old example")
        let actor = GLIModelActor(modelContainer: container)

        let updated = try await actor.update(
            GLIWordCardUpdate(
                wordID: wordID,
                word: "bonjour",
                translation: "",
                targetLanguage: "en",
                example: ""
            )
        )

        #expect(updated.id == wordID)
        #expect(updated.word == "bonjour")
        #expect(updated.translation.isEmpty)
        #expect(updated.sourceLanguage == "es")
        #expect(updated.targetLanguage == "en")

        let entity = try #require(try fetchWord(id: wordID, from: container))
        #expect(entity.createdAt == createdAt)
        #expect(entity.languageFolder?.id == folderID)
        #expect(entity.languageFolder?.languageCode == "es")
        #expect(try fetchExamples(wordID: wordID, from: container).map(\.text) == [""])
    }

    @Test("update inserts then updates one example sidecar")
    @MainActor
    func updateUpsertsExample() async throws {
        let container = try makeContainerWithWord()
        let actor = GLIModelActor(modelContainer: container)

        _ = try await actor.update(
            GLIWordCardUpdate(
                wordID: wordID,
                word: "hola",
                translation: "hello",
                targetLanguage: "en",
                example: "First"
            )
        )
        _ = try await actor.update(
            GLIWordCardUpdate(
                wordID: wordID,
                word: "hola",
                translation: "hello",
                targetLanguage: "en",
                example: "Second"
            )
        )

        let examples = try fetchExamples(wordID: wordID, from: container)
        #expect(examples.count == 1)
        #expect(examples.first?.text == "Second")
    }

    @Test("delete removes word and example but keeps permanent folder")
    @MainActor
    func deletePreservesFolder() async throws {
        let container = try makeContainerWithWord(example: "Example")
        let actor = GLIModelActor(modelContainer: container)

        try await actor.delete(wordID: wordID)

        #expect(try fetchWord(id: wordID, from: container) == nil)
        #expect(try fetchExamples(wordID: wordID, from: container).isEmpty)

        let context = ModelContext(container)
        let folders = try context.fetch(FetchDescriptor<GLILanguageFolderEntity>())
        #expect(folders.count == 1)
        #expect(folders.first?.id == folderID)
        #expect(folders.first?.items.isEmpty == true)
    }

    @Test("missing IDs fail predictably without creating sidecars")
    @MainActor
    func missingIDsFailPredictably() async throws {
        let container = try GLIModelContainerFactory.makeInMemory()
        let actor = GLIModelActor(modelContainer: container)

        await #expect(throws: GLICardMutationsError.wordNotFound(wordID)) {
            try await actor.update(
                GLIWordCardUpdate(
                    wordID: wordID,
                    word: "missing",
                    translation: "",
                    targetLanguage: nil,
                    example: "Must not persist"
                )
            )
        }
        await #expect(throws: GLICardMutationsError.wordNotFound(wordID)) {
            try await actor.delete(wordID: wordID)
        }

        #expect(try fetchExamples(wordID: wordID, from: container).isEmpty)
    }

    @Test("shared actor clients observe one persistence state")
    @MainActor
    func sharedActorClientsStayConsistent() async throws {
        let container = try GLIModelContainerFactory.makeInMemory()
        let actor = GLIModelActor(modelContainer: container)
        let wordPairs = GLIWordPairsClient.live(actor: actor)
        let examples = GLIWordExamplesClient.live(actor: actor)
        let mutations = GLICardMutationsClient.live(actor: actor)
        let pair = GLIWordPair(
            id: wordID,
            word: "hola",
            translation: "hello",
            sourceLanguage: "es",
            targetLanguage: "en"
        )

        try await wordPairs.save(pair)
        let updated = try await mutations.update(
            GLIWordCardUpdate(
                wordID: wordID,
                word: "hola!",
                translation: "hello!",
                targetLanguage: "fr",
                example: "¡Hola!"
            )
        )

        let fetched = try await wordPairs.fetchWordPairs()
        #expect(fetched == [updated])
        #expect(try await examples.fetchExample(wordID) == "¡Hola!")

        try await mutations.delete(wordID)
        #expect(try await wordPairs.fetchWordPairs().isEmpty)
        #expect(try await examples.fetchExample(wordID).isEmpty)
    }

    @MainActor
    private func makeContainerWithWord(example: String? = nil) throws -> ModelContainer {
        let container = try GLIModelContainerFactory.makeInMemory()
        let context = ModelContext(container)
        let folder = GLILanguageFolderEntity(id: folderID, languageCode: "es")
        let word = GLIWordPairEntity(
            id: wordID,
            word: "hola",
            translation: "hello",
            sourceLanguage: "es",
            targetLanguage: "en",
            createdAt: createdAt,
            languageFolder: folder
        )
        context.insert(folder)
        context.insert(word)
        if let example {
            context.insert(GLIWordExampleEntity(wordID: wordID, text: example))
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
    private func fetchExamples(
        wordID: UUID,
        from container: ModelContainer
    ) throws -> [GLIWordExampleEntity] {
        let wordID = wordID
        let descriptor = FetchDescriptor<GLIWordExampleEntity>(
            predicate: #Predicate { $0.wordID == wordID }
        )
        return try ModelContext(container).fetch(descriptor)
    }
}
