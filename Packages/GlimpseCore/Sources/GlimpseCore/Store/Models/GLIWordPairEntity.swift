import Foundation
import SwiftData

@Model
public final class GLIWordPairEntity {
    @Attribute(.unique) public var id: UUID
    public var word: String
    public var translation: String
    public var sourceLanguage: String?
    public var targetLanguage: String?
    public var createdAt: Date
    public var languageFolder: GLILanguageFolderEntity?
    public var customFolder: GLICustomFolderEntity?

    public init(
        id: UUID = UUID(),
        word: String,
        translation: String,
        sourceLanguage: String? = nil,
        targetLanguage: String? = nil,
        createdAt: Date = .now,
        languageFolder: GLILanguageFolderEntity? = nil,
        customFolder: GLICustomFolderEntity? = nil
    ) {
        self.id = id
        self.word = word
        self.translation = translation
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.createdAt = createdAt
        self.languageFolder = languageFolder
        self.customFolder = customFolder
    }
}
