import Foundation
import SwiftData

/// One meaning of a saved word: text, an optional language, and one optional example.
/// Sidecar keyed by `wordPairID` — no relationship to the word entity.
/// Every stored property is optional or defaulted and nothing is unique, so the schema stays
/// compatible with CloudKit if the store ever syncs.
/// Display order is oldest `createdAt` first (then `id`); there is no positional index.
@Model
public final class GLIWordMeaningEntity {
    public var id: UUID = UUID()
    /// Could instead be a `@Relationship` to `GLIWordPairEntity` with a cascade delete rule —
    /// traded that for a plain scalar on purpose: this table is rewritten wholesale on every
    /// card save, and a to-many relationship would mean SwiftData diffing/rewiring the array
    /// (and, under CloudKit, syncing it as reference metadata across separate records) on each
    /// save instead of plain column writes. Cost: `GLIModelActor.delete(wordID:)` has to clean
    /// these rows up by hand — SwiftData won't cascade a field it doesn't know is a foreign key.
    public var wordPairID: UUID = UUID()
    public var text: String = ""
    public var language: String?
    public var example: String = ""
    public var createdAt: Date = Date.now

    public init(
        id: UUID = UUID(),
        wordPairID: UUID,
        text: String,
        language: String? = nil,
        example: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.wordPairID = wordPairID
        self.text = text
        self.language = language
        self.example = example
        self.createdAt = createdAt
    }
}
