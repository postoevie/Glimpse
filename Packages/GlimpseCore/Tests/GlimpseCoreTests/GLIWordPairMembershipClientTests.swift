import Foundation
import SwiftData
import Testing
@testable import GlimpseCore

@Suite("GLIWordPairMembershipClient")
struct GLIWordPairMembershipClientTests {
    private let wordID = UUID(uuidString: "00000000-0000-0000-0000-0000000000E1")!

    // MARK: - assignCustomFolder (capture-time path)

    @Test("assignCustomFolder sets membership and updates folder targetLanguage from word")
    @MainActor
    func assignSetsMembershipAndFolderTarget() async throws {
        let (actor, folderID) = try await makeActorWithWordAndFolder()
        let membership = GLIWordPairMembershipClient.live(actor: actor)

        try await membership.assignCustomFolder(wordID, folderID, "en")

        let inFolder = try await actor.fetchWordPairs(inCustomFolderID: folderID)
        #expect(inFolder.map(\.id) == [wordID])

        let folder = try await actor.fetchCustomFolder(id: folderID)
        #expect(folder?.targetLanguage == "en")
    }

    @Test("assignCustomFolder with nil clears membership")
    @MainActor
    func assignNilClearsMembership() async throws {
        let (actor, folderID) = try await makeActorWithWordAndFolder()
        let membership = GLIWordPairMembershipClient.live(actor: actor)

        try await membership.assignCustomFolder(wordID, folderID, "en")
        try await membership.assignCustomFolder(wordID, nil as UUID?, "en")

        let inFolder = try await actor.fetchWordPairs(inCustomFolderID: folderID)
        #expect(inFolder.isEmpty)

        // Clear does not wipe the folder’s cached target.
        let folder = try await actor.fetchCustomFolder(id: folderID)
        #expect(folder?.targetLanguage == "en")
    }

    @Test("assignCustomFolder with empty target leaves folder targetLanguage unchanged")
    @MainActor
    func assignEmptyTargetDoesNotOverwriteFolderTarget() async throws {
        let (actor, folderID) = try await makeActorWithWordAndFolder()
        let membership = GLIWordPairMembershipClient.live(actor: actor)

        try await membership.assignCustomFolder(wordID, folderID, "fr")
        try await membership.assignCustomFolder(wordID, folderID, "   ")

        let folder = try await actor.fetchCustomFolder(id: folderID)
        #expect(folder?.targetLanguage == "fr")

        let inFolder = try await actor.fetchWordPairs(inCustomFolderID: folderID)
        #expect(inFolder.map(\.id) == [wordID])
    }

    @Test("assignCustomFolder throws sourceMismatch when word source differs from folder source")
    @MainActor
    func assignRejectsSourceMismatch() async throws {
        let container = try GLIModelContainerFactory.makeInMemory()
        let actor = GLIModelActor(modelContainer: container)
        let french = try await actor.createCustomFolder(name: "Paris", sourceLanguage: "fr")
        try await actor.saveWordPair(
            GLIWordPair(id: wordID, word: "hola", sourceLanguage: "es", targetLanguage: "en")
        )
        let membership = GLIWordPairMembershipClient.live(actor: actor)

        await #expect(throws: GLIWordPairMembershipError.sourceMismatch) {
            try await membership.assignCustomFolder(wordID, french.id, "en")
        }

        let inFrench = try await actor.fetchWordPairs(inCustomFolderID: french.id)
        #expect(inFrench.isEmpty)
    }

    @Test("assignCustomFolder adopts the folder's source and language folder when the word has none yet")
    @MainActor
    func assignAdoptsFolderSourceForSourcelessWord() async throws {
        let container = try GLIModelContainerFactory.makeInMemory()
        let actor = GLIModelActor(modelContainer: container)
        let folder = try await actor.createCustomFolder(name: "Travel", sourceLanguage: "es")
        try await actor.saveWordPair(
            GLIWordPair(id: wordID, word: "hola", sourceLanguage: nil, targetLanguage: "en")
        )
        let membership = GLIWordPairMembershipClient.live(actor: actor)

        try await membership.assignCustomFolder(wordID, folder.id, "en")

        let pairs = try await actor.fetchWordPairs()
        let word = try #require(pairs.first { $0.id == wordID })
        #expect(word.sourceLanguage == "es")
        #expect(word.customFolderID == folder.id)

        let folders = try await actor.fetchLanguageFolders()
        let esFolder = try #require(folders.first { $0.languageCode == "es" })
        let inEs = try await actor.fetchWordPairs(inFolderID: esFolder.id)
        #expect(inEs.map(\.id) == [wordID])
    }

    @Test("assignCustomFolder rejects an unrecognized persisted word source as a mismatch, not a hard error")
    @MainActor
    func assignTreatsUnrecognizedWordSourceAsMismatch() async throws {
        let (actor, folderID) = try await makeActorWithWordAndFolder()
        try await actor.setUnvalidatedSourceLanguageForTesting(wordID: wordID, code: "xx-legacy")
        let membership = GLIWordPairMembershipClient.live(actor: actor)

        // Pre-fix this threw GLICustomFoldersError.invalidSourceLanguage instead of the
        // expected, recoverable sourceMismatch.
        await #expect(throws: GLIWordPairMembershipError.sourceMismatch) {
            try await membership.assignCustomFolder(wordID, folderID, "en")
        }
    }

    // MARK: - updateSource / updateCustomFolder (card-edit path)

    @Test("updateSource from Unsorted sets source and language folder")
    @MainActor
    func updateSourceFromUnsortedSetsLanguage() async throws {
        let actor = try await makeActorWithUnsortedWord()
        let membership = GLIWordPairMembershipClient.live(actor: actor)

        let updated = try await membership.updateSource(wordID, "es")
        #expect(updated.id == wordID)
        #expect(updated.sourceLanguage == "es")
        #expect(updated.targetLanguage == "en")
        #expect(updated.customFolderID == nil)

        let folders = try await actor.fetchLanguageFolders()
        let esFolder = try #require(folders.first { $0.languageCode == "es" })
        let inEs = try await actor.fetchWordPairs(inFolderID: esFolder.id)
        #expect(inEs.map(\.id) == [wordID])
    }

    @Test("updateCustomFolder from Unsorted adopts folder source, assigns membership, syncs folder target")
    @MainActor
    func updateCustomFolderFromUnsortedAdoptsSource() async throws {
        let actor = try await makeActorWithUnsortedWord()
        let folder = try await actor.createCustomFolder(name: "Travel", sourceLanguage: "es")
        let membership = GLIWordPairMembershipClient.live(actor: actor)

        let updated = try await membership.updateCustomFolder(wordID, folder.id)
        #expect(updated.sourceLanguage == "es")
        #expect(updated.targetLanguage == "en")
        #expect(updated.customFolderID == folder.id)

        let inFolder = try await actor.fetchWordPairs(inCustomFolderID: folder.id)
        #expect(inFolder.map(\.id) == [wordID])

        let fetchedFolder = try await actor.fetchCustomFolder(id: folder.id)
        #expect(fetchedFolder?.targetLanguage == "en")
    }

    @Test("updateSource nil clears custom membership and moves to Unsorted")
    @MainActor
    func updateSourceNilClearsCustomAndUnsorted() async throws {
        let (actor, folderID) = try await makeActorWithWordAndFolder()
        let membership = GLIWordPairMembershipClient.live(actor: actor)

        _ = try await membership.updateCustomFolder(wordID, folderID)
        let updated = try await membership.updateSource(wordID, nil as String?)

        #expect(updated.sourceLanguage == nil)
        #expect(updated.targetLanguage == "en")
        #expect(updated.customFolderID == nil)

        let inFolder = try await actor.fetchWordPairs(inCustomFolderID: folderID)
        #expect(inFolder.isEmpty)

        let folders = try await actor.fetchLanguageFolders()
        let unsorted = try #require(
            folders.first { $0.languageCode == GLILanguageFolder.unsortedCode }
        )
        let inUnsorted = try await actor.fetchWordPairs(inFolderID: unsorted.id)
        #expect(inUnsorted.map(\.id) == [wordID])
    }

    @Test("updateCustomFolder assigns and clears when source is known")
    @MainActor
    func updateCustomFolderAssignAndClearKnownSource() async throws {
        let (actor, folderID) = try await makeActorWithWordAndFolder()
        let membership = GLIWordPairMembershipClient.live(actor: actor)

        let assigned = try await membership.updateCustomFolder(wordID, folderID)
        #expect(assigned.sourceLanguage == "es")
        #expect(assigned.customFolderID == folderID)
        var inFolder = try await actor.fetchWordPairs(inCustomFolderID: folderID)
        #expect(inFolder.map(\.id) == [wordID])

        let cleared = try await membership.updateCustomFolder(wordID, nil as UUID?)
        #expect(cleared.sourceLanguage == "es")
        #expect(cleared.customFolderID == nil)
        inFolder = try await actor.fetchWordPairs(inCustomFolderID: folderID)
        #expect(inFolder.isEmpty)
    }

    @Test("updateCustomFolder throws sourceMismatch when folder source differs")
    @MainActor
    func updateCustomFolderRejectsSourceMismatch() async throws {
        let (actor, _) = try await makeActorWithWordAndFolder()
        let french = try await actor.createCustomFolder(name: "Paris", sourceLanguage: "fr")
        let membership = GLIWordPairMembershipClient.live(actor: actor)

        await #expect(throws: GLIWordPairMembershipError.sourceMismatch) {
            try await membership.updateCustomFolder(wordID, french.id)
        }

        let inFrench = try await actor.fetchWordPairs(inCustomFolderID: french.id)
        #expect(inFrench.isEmpty)
    }

    @Test("updateCustomFolder rejects an unrecognized persisted item source as a mismatch, not a hard error")
    @MainActor
    func updateCustomFolderTreatsUnrecognizedItemSourceAsMismatch() async throws {
        let (actor, folderID) = try await makeActorWithWordAndFolder()
        // Simulate a legacy code sitting on the word from before validation existed —
        // `saveWordPair` never validates on write, only `createCustomFolder` does.
        try await actor.setUnvalidatedSourceLanguageForTesting(wordID: wordID, code: "xx-legacy")
        let membership = GLIWordPairMembershipClient.live(actor: actor)

        // Pre-fix this threw GLICustomFoldersError.invalidSourceLanguage — a hard, unrecoverable
        // error — instead of the expected, recoverable sourceMismatch.
        await #expect(throws: GLIWordPairMembershipError.sourceMismatch) {
            try await membership.updateCustomFolder(wordID, folderID)
        }
    }

    @Test("updateCustomFolder still assigns when the item's unrecognized persisted source matches the folder's")
    @MainActor
    func updateCustomFolderAssignsWhenUnrecognizedSourcesMatch() async throws {
        let (actor, folderID) = try await makeActorWithWordAndFolder()
        try await actor.setUnvalidatedSourceLanguageForTesting(wordID: wordID, code: "xx-legacy")
        // Corrupt the folder to the same legacy code, so both sides are equally unrecognized
        // but still match — pre-fix this threw invalidSourceLanguage on the folder side.
        try await actor.setUnvalidatedCustomFolderSourceForTesting(folderID: folderID, code: "xx-legacy")
        let membership = GLIWordPairMembershipClient.live(actor: actor)

        let updated = try await membership.updateCustomFolder(wordID, folderID)
        #expect(updated.customFolderID == folderID)
    }

    @Test("updateSource throws before mutating when the new source is invalid")
    @MainActor
    func updateSourceInvalidNewSourceLeavesEntityUnchanged() async throws {
        let (actor, folderID) = try await makeActorWithWordAndFolder()
        let membership = GLIWordPairMembershipClient.live(actor: actor)
        _ = try await membership.updateCustomFolder(wordID, folderID)

        await #expect(throws: GLICustomFoldersError.self) {
            try await membership.updateSource(wordID, "not-a-real-language-code")
        }

        // The throw fires before any mutation — source and custom-folder membership
        // must be exactly as they were, not partially updated then rolled back.
        let inFolder = try await actor.fetchWordPairs(inCustomFolderID: folderID)
        #expect(inFolder.map(\.id) == [wordID])
        let folders = try await actor.fetchLanguageFolders()
        let esFolder = try #require(folders.first { $0.languageCode == "es" })
        let inEs = try await actor.fetchWordPairs(inFolderID: esFolder.id)
        #expect(inEs.map(\.id) == [wordID])
    }

    @Test("updateSource clears custom membership when new source mismatches folder")
    @MainActor
    func updateSourceClearsCustomOnMismatch() async throws {
        let (actor, folderID) = try await makeActorWithWordAndFolder()
        let membership = GLIWordPairMembershipClient.live(actor: actor)

        _ = try await membership.updateCustomFolder(wordID, folderID)
        let updated = try await membership.updateSource(wordID, "fr")

        #expect(updated.sourceLanguage == "fr")
        #expect(updated.customFolderID == nil)
        let inFolder = try await actor.fetchWordPairs(inCustomFolderID: folderID)
        #expect(inFolder.isEmpty)
    }

    // MARK: - pruneEmptyLanguageFolders

    @Test("pruneEmptyLanguageFolders deletes empty language folders and keeps custom folders")
    @MainActor
    func pruneDeletesEmptyLanguageFoldersKeepsCustom() async throws {
        let container = try GLIModelContainerFactory.makeInMemory()
        let actor = GLIModelActor(modelContainer: container)
        try await seedEmptyLanguageFolder(actor: actor, languageCode: "es")
        try await seedEmptyLanguageFolder(actor: actor, languageCode: nil)
        let custom = try await actor.createCustomFolder(name: "Travel", sourceLanguage: "es")
        let membership = GLIWordPairMembershipClient.live(actor: actor)

        try await membership.pruneEmptyLanguageFolders()

        let folders = try await actor.fetchLanguageFolders()
        #expect(folders.isEmpty)
        let remainingCustom = try await actor.fetchCustomFolder(id: custom.id)
        #expect(remainingCustom?.name == "Travel")
    }

    @Test("pruneEmptyLanguageFolders keeps a language folder that still has words")
    @MainActor
    func pruneKeepsLanguageFolderWithWords() async throws {
        let (actor, _) = try await makeActorWithWordAndFolder()
        try await seedEmptyLanguageFolder(actor: actor, languageCode: "fr")
        let membership = GLIWordPairMembershipClient.live(actor: actor)

        try await membership.pruneEmptyLanguageFolders()

        let folders = try await actor.fetchLanguageFolders()
        #expect(folders.map(\.languageCode) == ["es"])
    }

    // MARK: - Helpers

    /// Creates a language folder (or Unsorted) via a throwaway word, then deletes the word.
    @MainActor
    private func seedEmptyLanguageFolder(
        actor: GLIModelActor,
        languageCode: String?
    ) async throws {
        let id = UUID()
        try await actor.saveWordPair(
            GLIWordPair(id: id, word: "seed", sourceLanguage: languageCode, targetLanguage: "en")
        )
        try await actor.delete(wordID: id)
    }

    @MainActor
    private func makeActorWithUnsortedWord() async throws -> GLIModelActor {
        let container = try GLIModelContainerFactory.makeInMemory()
        let actor = GLIModelActor(modelContainer: container)
        try await actor.saveWordPair(
            GLIWordPair(id: wordID, word: "hola", sourceLanguage: nil, targetLanguage: "en")
        )
        return actor
    }

    @MainActor
    private func makeActorWithWordAndFolder() async throws -> (GLIModelActor, UUID) {
        let container = try GLIModelContainerFactory.makeInMemory()
        let actor = GLIModelActor(modelContainer: container)
        let folder = try await actor.createCustomFolder(name: "Travel", sourceLanguage: "es")
        try await actor.saveWordPair(
            GLIWordPair(id: wordID, word: "hola", sourceLanguage: "es", targetLanguage: "en")
        )
        return (actor, folder.id)
    }
}

extension GLIModelActor {
    /// Test-only: writes a source code directly, bypassing `validatedSourceLanguage`, to
    /// exercise revalidation edge cases (legacy/unrecognized codes) that can't be produced
    /// through the public create/save APIs — `saveWordPair` never validates on write, and
    /// `createCustomFolder` always does, so this is the only way to simulate a stored code
    /// that the OS no longer recognizes.
    fileprivate func setUnvalidatedSourceLanguageForTesting(wordID: GLIWordPair.ID, code: String) throws {
        let entity = try fetchWordEntity(id: wordID)
        entity.sourceLanguage = code
        try modelContext.save()
    }

    /// Test-only: same as above, for a custom folder's source.
    fileprivate func setUnvalidatedCustomFolderSourceForTesting(folderID: UUID, code: String) throws {
        let entity = try fetchCustomFolderEntity(id: folderID)
        entity.sourceLanguage = code
        try modelContext.save()
    }
}
