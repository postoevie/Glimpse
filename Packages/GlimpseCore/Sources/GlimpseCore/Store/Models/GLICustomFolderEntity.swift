import Foundation
import SwiftData

@Model
public final class GLICustomFolderEntity {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var sourceLanguage: String?
    public var targetLanguage: String?
    @Relationship(deleteRule: .nullify, inverse: \GLIWordPairEntity.customFolder)
    public var items: [GLIWordPairEntity] = []

    public init(
        id: UUID = UUID(),
        name: String,
        sourceLanguage: String? = nil,
        targetLanguage: String? = nil
    ) {
        self.id = id
        self.name = name
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
    }
}
