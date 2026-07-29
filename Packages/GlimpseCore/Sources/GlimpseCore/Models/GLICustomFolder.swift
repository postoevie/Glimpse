import Foundation

public nonisolated struct GLICustomFolder: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var sourceLanguage: String?
    public var targetLanguage: String?

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
