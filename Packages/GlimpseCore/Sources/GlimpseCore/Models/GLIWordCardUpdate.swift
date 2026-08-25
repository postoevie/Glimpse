import Foundation

/// Editable fields for an existing word card. Identity, source language, folder, creation date,
/// and meanings stay locked — meanings persist separately via `GLIWordMeaningsClient.replaceAll`.
public struct GLIWordCardUpdate: Equatable, Sendable {
    public var wordID: GLIWordPair.ID
    public var word: String
    public var targetLanguage: String?

    public init(
        wordID: GLIWordPair.ID,
        word: String,
        targetLanguage: String?
    ) {
        self.wordID = wordID
        self.word = word
        self.targetLanguage = targetLanguage
    }
}
