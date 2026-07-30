import Foundation

public nonisolated struct GLICustomFolder: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    /// Required language code from `GLILanguageCodes.systemCodes` (set at create; not editable later).
    public var sourceLanguage: String
    public var targetLanguage: String?

    public init(
        id: UUID = UUID(),
        name: String,
        sourceLanguage: String,
        targetLanguage: String? = nil
    ) {
        self.id = id
        self.name = name
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
    }
}
