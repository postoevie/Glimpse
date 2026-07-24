import Foundation

public nonisolated struct GLILanguageFolder: Equatable, Identifiable, Sendable {
    /// Sentinel `languageCode` for items with `nil` source language.
    public static let unsortedCode = "unsorted"

    public let id: UUID
    public var languageCode: String

    public var isUnsorted: Bool {
        languageCode == Self.unsortedCode
    }

    public init(id: UUID = UUID(), languageCode: String) {
        self.id = id
        self.languageCode = languageCode
    }
}
