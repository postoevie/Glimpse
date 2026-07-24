import Foundation
import SwiftData

@Model
public final class GLILanguageFolderEntity {
    @Attribute(.unique) public var id: UUID
    @Attribute(.unique) public var languageCode: String
    @Relationship(deleteRule: .nullify, inverse: \GLIWordPairEntity.languageFolder)
    public var items: [GLIWordPairEntity] = []

    public init(
        id: UUID = UUID(),
        languageCode: String
    ) {
        self.id = id
        self.languageCode = languageCode
    }
}
