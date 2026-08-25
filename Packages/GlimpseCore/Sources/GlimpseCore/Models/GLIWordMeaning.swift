import Foundation

/// One meaning of a saved word. The language may equal the word's language (a definition)
/// or differ from it (a translation). The example belongs to this meaning, not to the card.
/// Store order is oldest creation date first; this value does not carry a timestamp.
public nonisolated struct GLIWordMeaning: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var text: String
    public var language: String?
    public var example: String

    public init(
        id: UUID = UUID(),
        text: String,
        language: String? = nil,
        example: String = ""
    ) {
        self.id = id
        self.text = text
        self.language = language
        self.example = example
    }

    /// Meaning #1 from Add's single meaning line.
    /// `nil` when both the line and the example are blank — zero meanings is valid; do not invent a row.
    public static func captureMeaning(
        text: String,
        language: String?,
        example: String = ""
    ) -> GLIWordMeaning? {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let example = example.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || !example.isEmpty else {
            return nil
        }
        return GLIWordMeaning(text: text, language: language, example: example)
    }
}
