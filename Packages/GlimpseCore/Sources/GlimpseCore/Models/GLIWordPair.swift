import Foundation

public nonisolated struct GLIWordPair: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var word: String
    public var translation: String

    public init(id: UUID = UUID(), word: String, translation: String) {
        self.id = id
        self.word = word
        self.translation = translation
    }
}
