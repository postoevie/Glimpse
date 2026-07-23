import Foundation
import SwiftData

@Model
public final class GLIWordPairEntity {
    @Attribute(.unique) public var id: UUID
    public var word: String
    public var translation: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        word: String,
        translation: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.word = word
        self.translation = translation
        self.createdAt = createdAt
    }
}
