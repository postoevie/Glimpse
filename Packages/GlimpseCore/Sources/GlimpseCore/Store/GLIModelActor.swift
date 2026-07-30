import Foundation
import SwiftData

public enum GLICustomFoldersError: Error, Equatable, Sendable {
    case emptyName
    case invalidSourceLanguage
    case folderNotFound(UUID)
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

    public func saveWordPair(_ pair: GLIWordPair) throws {
        let sourceLanguage = Self.normalizedLanguageCode(pair.sourceLanguage)
        let targetLanguage = Self.normalizedLanguageCode(pair.targetLanguage)
        let folderCode = sourceLanguage ?? GLILanguageFolder.unsortedCode
        let folder = try findOrCreateLanguageFolder(languageCode: folderCode)

        let entity = GLIWordPairEntity(
            id: pair.id,
            word: pair.word,
            translation: pair.translation,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            languageFolder: folder
        )
        modelContext.insert(entity)
        try modelContext.save()
    }

    /// Stored example text for a word pair. Missing sidecar yields `""`.
    public func fetchExample(for wordID: GLIWordPair.ID) throws -> String {
        try fetchExampleEntity(wordID: wordID)?.text ?? ""
    }

    /// Updates word, translation, target language, and example only.
    /// Never changes identity, source language, language folder, or creation date.
    public func update(_ update: GLIWordCardUpdate) throws -> GLIWordPair {
        try modelContext.transaction {
            let wordEntity = try fetchWordEntity(id: update.wordID)
            wordEntity.word = update.word
            wordEntity.translation = update.translation
            wordEntity.targetLanguage = Self.normalizedLanguageCode(update.targetLanguage)
            try upsertExample(wordID: update.wordID, text: update.example)
        }
        return Self.mapWordPair(try fetchWordEntity(id: update.wordID))
    }

    /// Deletes the word and its example sidecar. Keeps the language folder.
    public func delete(wordID: GLIWordPair.ID) throws {
        let wordEntity = try fetchWordEntity(id: wordID)
        let exampleEntity = try fetchExampleEntity(wordID: wordID)

        try modelContext.transaction {
            if let exampleEntity {
                modelContext.delete(exampleEntity)
            }
            modelContext.delete(wordEntity)
        }
    }

    private func findOrCreateLanguageFolder(languageCode: String) throws -> GLILanguageFolderEntity {
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

    private func fetchCustomFolderEntity(id: UUID) throws -> GLICustomFolderEntity {
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

    private func fetchWordEntity(id: GLIWordPair.ID) throws -> GLIWordPairEntity {
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

    private func fetchExampleEntity(wordID: GLIWordPair.ID) throws -> GLIWordExampleEntity? {
        let wordID = wordID
        var descriptor = FetchDescriptor<GLIWordExampleEntity>(
            predicate: #Predicate { example in
                example.wordID == wordID
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func upsertExample(wordID: GLIWordPair.ID, text: String) throws {
        if let example = try fetchExampleEntity(wordID: wordID) {
            example.text = text
            example.updatedAt = .now
            return
        }

        modelContext.insert(
            GLIWordExampleEntity(
                wordID: wordID,
                text: text
            )
        )
    }

    private static func mapWordPair(_ entity: GLIWordPairEntity) -> GLIWordPair {
        GLIWordPair(
            id: entity.id,
            word: entity.word,
            translation: entity.translation,
            sourceLanguage: entity.sourceLanguage,
            targetLanguage: entity.targetLanguage
        )
    }

    private static func mapCustomFolder(_ entity: GLICustomFolderEntity) -> GLICustomFolder {
        GLICustomFolder(
            id: entity.id,
            name: entity.name,
            sourceLanguage: entity.sourceLanguage,
            targetLanguage: entity.targetLanguage
        )
    }

    private static func validatedFolderName(_ name: String) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw GLICustomFoldersError.emptyName
        }
        return trimmed
    }

    private static func validatedSourceLanguage(_ code: String) throws -> String {
        guard let normalized = GLILanguageCodes.normalizedSystemCode(code) else {
            throw GLICustomFoldersError.invalidSourceLanguage
        }
        return normalized
    }

    private static func normalizedLanguageCode(_ code: String?) -> String? {
        guard let code else {
            return nil
        }
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
