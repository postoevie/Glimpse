import Foundation
import SwiftData

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

    private static func mapWordPair(_ entity: GLIWordPairEntity) -> GLIWordPair {
        GLIWordPair(
            id: entity.id,
            word: entity.word,
            translation: entity.translation,
            sourceLanguage: entity.sourceLanguage,
            targetLanguage: entity.targetLanguage
        )
    }

    private static func normalizedLanguageCode(_ code: String?) -> String? {
        guard let code else {
            return nil
        }
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
