import Foundation

/// Editable fields for an existing word card. Identity, source language, folder, and creation date stay locked.
public struct GLIWordCardUpdate: Equatable, Sendable {
    public var wordID: GLIWordPair.ID
    public var word: String
    public var translation: String
    public var targetLanguage: String?
    public var example: String

    public init(
        wordID: GLIWordPair.ID,
        word: String,
        translation: String,
        targetLanguage: String?,
        example: String
    ) {
        self.wordID = wordID
        self.word = word
        self.translation = translation
        self.targetLanguage = targetLanguage
        self.example = example
    }
}
