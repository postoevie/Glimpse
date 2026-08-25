import Foundation
import SwiftData

public enum GLICustomFoldersError: Error, Equatable, Sendable {
    case emptyName
    case invalidSourceLanguage
    case folderNotFound(UUID)
}

public enum GLIWordPairMembershipError: Error, Equatable, Sendable {
    /// Item source language does not match the custom folder’s source.
    case sourceMismatch
}

@ModelActor
public actor GLIModelActor {
    public func fetchWordPairs() throws -> [GLIWordPair] {
        let descriptor = FetchDescriptor<GLIWordPairEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map(Self.mapWordPair)
    }

    /// Word pairs in one language folder, newest first. Missing folder yields `[]`.
    public func fetchWordPairs(inFolderID folderID: UUID) throws -> [GLIWordPair] {
        let folderID = folderID
        var descriptor = FetchDescriptor<GLILanguageFolderEntity>(
            predicate: #Predicate { folder in
                folder.id == folderID
            }
        )
        descriptor.fetchLimit = 1

        guard let folder = try modelContext.fetch(descriptor).first else {
            return []
        }

        return folder.items
            .sorted { $0.createdAt > $1.createdAt }
            .map(Self.mapWordPair)
    }

    /// Word pairs in one custom folder, newest first. Missing folder yields `[]`.
    public func fetchWordPairs(inCustomFolderID customFolderID: UUID) throws -> [GLIWordPair] {
        let customFolderID = customFolderID
        var descriptor = FetchDescriptor<GLICustomFolderEntity>(
            predicate: #Predicate { folder in
                folder.id == customFolderID
            }
        )
        descriptor.fetchLimit = 1

        guard let folder = try modelContext.fetch(descriptor).first else {
            return []
        }

        return folder.items
            .sorted { $0.createdAt > $1.createdAt }
            .map(Self.mapWordPair)
    }

    public func fetchLanguageFolders() throws -> [GLILanguageFolder] {
        let descriptor = FetchDescriptor<GLILanguageFolderEntity>(
            sortBy: [SortDescriptor(\.languageCode, order: .forward)]
        )
        let folders = try modelContext.fetch(descriptor).map { entity in
            GLILanguageFolder(id: entity.id, languageCode: entity.languageCode)
        }
        return folders.sorted { lhs, rhs in
            switch (lhs.isUnsorted, rhs.isUnsorted) {
            case (true, false):
                return false
            case (false, true):
                return true
            default:
                return lhs.languageCode < rhs.languageCode
            }
        }
    }

    /// Single language folder by id. Missing id yields `nil`.
    public func fetchLanguageFolder(id: UUID) throws -> GLILanguageFolder? {
        var descriptor = FetchDescriptor<GLILanguageFolderEntity>(
            predicate: #Predicate { folder in
                folder.id == id
            }
        )
        descriptor.fetchLimit = 1
        guard let entity = try modelContext.fetch(descriptor).first else {
            return nil
        }
        return GLILanguageFolder(id: entity.id, languageCode: entity.languageCode)
    }

    /// Custom folders ordered by name (ascending). Entity has no `createdAt`.
    public func fetchCustomFolders() throws -> [GLICustomFolder] {
        let descriptor = FetchDescriptor<GLICustomFolderEntity>(
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        return try modelContext.fetch(descriptor).map(Self.mapCustomFolder)
    }

    /// Single custom folder by id. Missing id yields `nil`.
    public func fetchCustomFolder(id: UUID) throws -> GLICustomFolder? {
        var descriptor = FetchDescriptor<GLICustomFolderEntity>(
            predicate: #Predicate { folder in
                folder.id == id
            }
        )
        descriptor.fetchLimit = 1
        guard let entity = try modelContext.fetch(descriptor).first else {
            return nil
        }
        return Self.mapCustomFolder(entity)
    }

    public func createCustomFolder(name: String, sourceLanguage: String) throws -> GLICustomFolder {
        let trimmedName = try Self.validatedFolderName(name)
        let languageCode = try Self.validatedSourceLanguage(sourceLanguage)
        let entity = GLICustomFolderEntity(name: trimmedName, sourceLanguage: languageCode)
        modelContext.insert(entity)
        try modelContext.save()
        return Self.mapCustomFolder(entity)
    }

    /// Renames only. Does not change `sourceLanguage`.
    public func renameCustomFolder(id: UUID, name: String) throws -> GLICustomFolder {
        let trimmedName = try Self.validatedFolderName(name)
        let entity = try fetchCustomFolderEntity(id: id)
        entity.name = trimmedName
        try modelContext.save()
        return Self.mapCustomFolder(entity)
    }

    /// Clears custom-folder membership on words, then deletes the folder.
    /// Does not change language folders or word text/languages.
    public func deleteCustomFolder(id: UUID) throws {
        let entity = try fetchCustomFolderEntity(id: id)
        try modelContext.transaction {
            for item in entity.items {
                item.customFolder = nil
            }
            modelContext.delete(entity)
        }
    }

    /// Sets or clears the word pair’s custom-folder membership at capture time.
    /// Same membership rule as `updateCustomFolder`: requires the item’s source (if already
    /// set) to match the folder’s source, and adopts the folder’s source/language folder when
    /// the item has none yet.
    /// When assigning and `wordTargetLanguage` is non-empty, updates the folder’s cached target language.
    public func assignCustomFolder(
        wordPairID: GLIWordPair.ID,
        customFolderID: UUID?,
        wordTargetLanguage: String?
    ) throws {
        let wordEntity = try fetchWordEntity(id: wordPairID)

        guard let customFolderID else {
            wordEntity.customFolder = nil
            try modelContext.save()
            return
        }

        let folderEntity = try fetchCustomFolderEntity(id: customFolderID)
        let folderSource = try Self.matchingMembershipFolderSource(
            itemSource: wordEntity.sourceLanguage,
            folderEntity: folderEntity
        )

        if wordEntity.sourceLanguage == nil {
            let languageFolder = try findOrCreateLanguageFolder(languageCode: folderSource)
            wordEntity.sourceLanguage = folderSource
            wordEntity.languageFolder = languageFolder
        }
        wordEntity.customFolder = folderEntity

        if let targetLanguage = Self.normalizedLanguageCode(wordTargetLanguage) {
            folderEntity.targetLanguage = targetLanguage
        }

        try modelContext.save()
    }

    /// Edits item `sourceLanguage`; language folder always follows.
    /// Clears custom-folder membership when the new source is nil or does not match the folder’s source.
    /// Does not change `targetLanguage`. Source is always editable (including clearing to Unsorted).
    public func updateSource(
        wordPairID: GLIWordPair.ID,
        sourceLanguage: String?
    ) throws -> GLIWordPair {
        let wordEntity = try fetchWordEntity(id: wordPairID)

        // Validate the new source before mutating the entity — the only throwing step in this
        // function — so a rejected input never leaves the entity dirtied-but-unsaved on this
        // actor's shared ModelContext.
        let sourceCode = try Self.normalizedLanguageCode(sourceLanguage).map(Self.validatedSourceLanguage)

        let shouldClearCustomFolder: Bool
        if let customFolder = wordEntity.customFolder {
            let folderSource = Self.persistedSourceLanguage(customFolder.sourceLanguage)
            shouldClearCustomFolder = sourceCode == nil || folderSource != sourceCode
        } else {
            shouldClearCustomFolder = false
        }

        let languageFolder = try findOrCreateLanguageFolder(
            languageCode: sourceCode ?? GLILanguageFolder.unsortedCode
        )

        wordEntity.sourceLanguage = sourceCode
        wordEntity.languageFolder = languageFolder
        if shouldClearCustomFolder {
            wordEntity.customFolder = nil
        }

        try modelContext.save()
        return Self.mapWordPair(wordEntity)
    }

    /// Sets or clears custom-folder membership.
    /// When the item has no source, adopts the folder’s source and language folder.
    /// When the item already has a source, requires a match with the folder’s source.
    /// Syncs folder target from the item target when present. Does not change item target.
    public func updateCustomFolder(
        wordPairID: GLIWordPair.ID,
        customFolderID: UUID?
    ) throws -> GLIWordPair {
        let wordEntity = try fetchWordEntity(id: wordPairID)

        guard let customFolderID else {
            wordEntity.customFolder = nil
            try modelContext.save()
            return Self.mapWordPair(wordEntity)
        }

        let folderEntity = try fetchCustomFolderEntity(id: customFolderID)
        let folderSource = try Self.matchingMembershipFolderSource(
            itemSource: wordEntity.sourceLanguage,
            folderEntity: folderEntity
        )

        if wordEntity.sourceLanguage != nil {
            wordEntity.customFolder = folderEntity
        } else {
            let languageFolder = try findOrCreateLanguageFolder(languageCode: folderSource)
            wordEntity.sourceLanguage = folderSource
            wordEntity.languageFolder = languageFolder
            wordEntity.customFolder = folderEntity
        }

        if let targetLanguage = Self.normalizedLanguageCode(wordEntity.targetLanguage) {
            folderEntity.targetLanguage = targetLanguage
        }

        try modelContext.save()
        return Self.mapWordPair(wordEntity)
    }

    /// Deletes language folders that have no words, including Unsorted.
    /// Does not delete custom folders.
    public func pruneEmptyLanguageFolders() throws {
        let folders = try modelContext.fetch(FetchDescriptor<GLILanguageFolderEntity>())
        let emptyFolders = folders.filter(\.items.isEmpty)
        guard !emptyFolders.isEmpty else { return }
        for folder in emptyFolders {
            modelContext.delete(folder)
        }
        try modelContext.save()
    }

    public func saveWordPair(_ pair: GLIWordPair) throws {
        let sourceLanguage = Self.normalizedLanguageCode(pair.sourceLanguage)
        let targetLanguage = Self.normalizedLanguageCode(pair.targetLanguage)
        let folderCode = sourceLanguage ?? GLILanguageFolder.unsortedCode
        let folder = try findOrCreateLanguageFolder(languageCode: folderCode)

        let entity = GLIWordPairEntity(
            id: pair.id,
            word: pair.word,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            languageFolder: folder
        )
        modelContext.insert(entity)
        try modelContext.save()
    }

    /// Updates word and target language only.
    /// Never changes identity, source language, language folder, creation date, or meanings —
    /// meanings persist separately via `replaceMeanings`.
    public func update(_ update: GLIWordCardUpdate) throws -> GLIWordPair {
        let wordEntity = try fetchWordEntity(id: update.wordID)
        wordEntity.word = update.word
        wordEntity.targetLanguage = Self.normalizedLanguageCode(update.targetLanguage)
        try modelContext.save()
        return Self.mapWordPair(wordEntity)
    }

    /// Deletes the word and its meanings. Keeps the language folder.
    public func delete(wordID: GLIWordPair.ID) throws {
        let wordEntity = try fetchWordEntity(id: wordID)
        let meaningEntities = try unorderedMeaningEntities(wordPairID: wordID)

        try modelContext.transaction {
            for meaning in meaningEntities {
                modelContext.delete(meaning)
            }
            modelContext.delete(wordEntity)
        }
    }

    // MARK: - Meanings

    /// Meanings stored for one word pair, oldest `createdAt` first, then `id`.
    public func fetchMeanings(wordPairID: GLIWordPair.ID) throws -> [GLIWordMeaning] {
        try unorderedMeaningEntities(wordPairID: wordPairID)
            .sorted(by: Self.isMeaningOrderedBefore)
            .map(Self.mapMeaning)
    }

    /// Updates rows that still exist, inserts new ids (`createdAt` = now), deletes rows that are gone.
    /// Passing an empty array leaves the word pair with no meanings.
    /// An existing row's `createdAt` is never assigned — only `text`, `language`, and `example` change.
    public func replaceMeanings(wordPairID: GLIWordPair.ID, meanings: [GLIWordMeaning]) throws {
        try modelContext.transaction {
            let existing = try unorderedMeaningEntities(wordPairID: wordPairID)
            var existingByID: [UUID: GLIWordMeaningEntity] = [:]
            existingByID.reserveCapacity(existing.count)
            for entity in existing {
                existingByID[entity.id] = entity
            }

            var incomingIDs: Set<UUID> = []
            incomingIDs.reserveCapacity(meanings.count)
            for meaning in meanings {
                guard incomingIDs.insert(meaning.id).inserted else {
                    continue
                }
                if let entity = existingByID[meaning.id] {
                    entity.text = meaning.text
                    entity.language = meaning.language
                    entity.example = meaning.example
                } else {
                    modelContext.insert(
                        GLIWordMeaningEntity(
                            id: meaning.id,
                            wordPairID: wordPairID,
                            text: meaning.text,
                            language: meaning.language,
                            example: meaning.example
                        )
                    )
                }
            }

            for entity in existing where !incomingIDs.contains(entity.id) {
                modelContext.delete(entity)
            }
        }
    }

    /// Oldest meaning text per pair, one fetch for the whole id set. Missing keys = no meanings.
    public func firstMeaningTexts(for wordPairIDs: [GLIWordPair.ID]) throws -> [GLIWordPair.ID: String] {
        let entities = try meaningEntities(for: wordPairIDs)
        var firstMeanings: [GLIWordPair.ID: String] = [:]
        for entity in entities where firstMeanings[entity.wordPairID] == nil {
            firstMeanings[entity.wordPairID] = entity.text
        }
        return firstMeanings
    }

    /// All meanings per pair, one fetch for the whole id set. Oldest first. Missing keys = no meanings.
    public func fetchAllMeanings(
        for wordPairIDs: [GLIWordPair.ID]
    ) throws -> [GLIWordPair.ID: [GLIWordMeaning]] {
        let entities = try meaningEntities(for: wordPairIDs)
        var meaningsByWordPairID: [GLIWordPair.ID: [GLIWordMeaning]] = [:]
        for entity in entities {
            meaningsByWordPairID[entity.wordPairID, default: []].append(Self.mapMeaning(entity))
        }
        return meaningsByWordPairID
    }

    private func unorderedMeaningEntities(
        wordPairID: GLIWordPair.ID
    ) throws -> [GLIWordMeaningEntity] {
        let wordPairID = wordPairID
        let descriptor = FetchDescriptor<GLIWordMeaningEntity>(
            predicate: #Predicate { meaning in
                meaning.wordPairID == wordPairID
            }
        )
        return try modelContext.fetch(descriptor)
    }

    /// Oldest first across the id set. Empty input → no fetch.
    private func meaningEntities(for wordPairIDs: [GLIWordPair.ID]) throws -> [GLIWordMeaningEntity] {
        let ids = Array(Set(wordPairIDs))
        guard !ids.isEmpty else {
            return []
        }
        let descriptor = FetchDescriptor<GLIWordMeaningEntity>(
            predicate: #Predicate<GLIWordMeaningEntity> { meaning in
                ids.contains(meaning.wordPairID)
            }
        )
        return try modelContext.fetch(descriptor)
            .sorted(by: Self.isMeaningOrderedBefore)
    }

    /// Oldest first; equal timestamps break ties with `id` so the order cannot swap across fetches.
    private static func isMeaningOrderedBefore(
        _ lhs: GLIWordMeaningEntity,
        _ rhs: GLIWordMeaningEntity
    ) -> Bool {
        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt < rhs.createdAt
        }
        return lhs.id < rhs.id
    }

    public static func mapMeaning(_ entity: GLIWordMeaningEntity) -> GLIWordMeaning {
        GLIWordMeaning(
            id: entity.id,
            text: entity.text,
            language: entity.language,
            example: entity.example
        )
    }

    public func findOrCreateLanguageFolder(languageCode: String) throws -> GLILanguageFolderEntity {
        let code = languageCode
        var descriptor = FetchDescriptor<GLILanguageFolderEntity>(
            predicate: #Predicate { folder in
                folder.languageCode == code
            }
        )
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }

        let folder = GLILanguageFolderEntity(languageCode: languageCode)
        modelContext.insert(folder)
        return folder
    }

    public func fetchCustomFolderEntity(id: UUID) throws -> GLICustomFolderEntity {
        var descriptor = FetchDescriptor<GLICustomFolderEntity>(
            predicate: #Predicate { folder in
                folder.id == id
            }
        )
        descriptor.fetchLimit = 1

        guard let entity = try modelContext.fetch(descriptor).first else {
            throw GLICustomFoldersError.folderNotFound(id)
        }
        return entity
    }

    public func fetchWordEntity(id: GLIWordPair.ID) throws -> GLIWordPairEntity {
        var descriptor = FetchDescriptor<GLIWordPairEntity>(
            predicate: #Predicate { wordPair in
                wordPair.id == id
            }
        )
        descriptor.fetchLimit = 1

        guard let entity = try modelContext.fetch(descriptor).first else {
            throw GLICardMutationsError.wordNotFound(id)
        }
        return entity
    }

    public static func mapWordPair(_ entity: GLIWordPairEntity) -> GLIWordPair {
        GLIWordPair(
            id: entity.id,
            word: entity.word,
            sourceLanguage: entity.sourceLanguage,
            targetLanguage: entity.targetLanguage,
            customFolderID: entity.customFolder?.id
        )
    }

    public static func mapCustomFolder(_ entity: GLICustomFolderEntity) -> GLICustomFolder {
        GLICustomFolder(
            id: entity.id,
            name: entity.name,
            sourceLanguage: entity.sourceLanguage,
            targetLanguage: entity.targetLanguage
        )
    }

    public static func validatedFolderName(_ name: String) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw GLICustomFoldersError.emptyName
        }
        return trimmed
    }

    public static func validatedSourceLanguage(_ code: String) throws -> String {
        guard let normalized = GLILanguageCodes.normalizedSystemCode(code) else {
            throw GLICustomFoldersError.invalidSourceLanguage
        }
        return normalized
    }

    public static func normalizedLanguageCode(_ code: String?) -> String? {
        guard let code else {
            return nil
        }
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Canonical form of an already-persisted source code for comparison only — never throws.
    /// Neither word nor custom-folder source is guaranteed to still be OS-recognized:
    /// `saveWordPair` never validates on write, and a folder's source — though validated at
    /// `createCustomFolder` time — can still fall out of the OS's recognized set later (locale
    /// tables change across OS versions). Re-validating either side here would permanently
    /// block membership changes for that word/folder. Falls back to the raw stored value when
    /// unrecognized, so equality still works for the common case.
    public static func persistedSourceLanguage(_ code: String) -> String {
        GLILanguageCodes.normalizedSystemCode(code) ?? code
    }

    /// Shared custom-folder membership rule: an item with a known source may only join a
    /// folder whose source matches — compared leniently via `persistedSourceLanguage` on both
    /// sides, not `validatedSourceLanguage`. Used by both `updateCustomFolder` and
    /// `assignCustomFolder` so the rule can't drift out of sync between them.
    public static func matchingMembershipFolderSource(
        itemSource: String?,
        folderEntity: GLICustomFolderEntity
    ) throws -> String {
        let folderSource = Self.persistedSourceLanguage(folderEntity.sourceLanguage)
        if let itemSource {
            guard Self.persistedSourceLanguage(itemSource) == folderSource else {
                throw GLIWordPairMembershipError.sourceMismatch
            }
        }
        return folderSource
    }
}
