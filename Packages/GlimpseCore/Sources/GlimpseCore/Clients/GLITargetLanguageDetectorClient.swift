// Task: capture 1-4 copy
import Foundation

/// On-device target-language detection from meaning text.
/// Returns the same language-code `String` used by Add Word (`GLIWordPair.targetLanguage`).
public struct GLITargetLanguageDetectorClient: Sendable {
    /// Skip 1–2 character strings — the recognizer guesses wildly on those.
    public static let minimumMeaningLength = 3

    public var detectTargetLanguage: @Sendable (String) -> String?

    public init(detectTargetLanguage: @escaping @Sendable (String) -> String?) {
        self.detectTargetLanguage = detectTargetLanguage
    }

    /// Language code, or `nil` when empty, too short, or low confidence / unknown.
    public func detectTargetLanguage(fromMeaningText text: String) -> String? {
        detectTargetLanguage(text)
    }
}

extension GLITargetLanguageDetectorClient {
    public static let live = GLITargetLanguageDetectorClient(
        detectTargetLanguage: { text in
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count >= minimumMeaningLength else {
                return nil
            }
            return GLILanguageDetector().detectSourceLanguage(in: trimmed)
        }
    )

    public static let unimplemented = GLITargetLanguageDetectorClient(
        detectTargetLanguage: { _ in nil }
    )
}
