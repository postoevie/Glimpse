import Foundation
import SwiftData

@Model
public final class GLIWordExampleEntity {
    @Attribute(.unique) public var wordID: UUID
    public var text: String
    public var updatedAt: Date

    public init(
        wordID: UUID,
        text: String,
        updatedAt: Date = .now
    ) {
        self.wordID = wordID
        self.text = text
        self.updatedAt = updatedAt
    }
}
