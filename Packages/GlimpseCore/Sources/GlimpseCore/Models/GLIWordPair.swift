import Foundation

public nonisolated struct GLIWordPair: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var word: String
    public var sourceLanguage: String?
    public var targetLanguage: String?
    public var customFolderID: UUID?

    public init(
        id: UUID = UUID(),
        word: String,
        sourceLanguage: String? = nil,
        targetLanguage: String? = nil,
        customFolderID: UUID? = nil
    ) {
        self.id = id
        self.word = word
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.customFolderID = customFolderID
    }
}
