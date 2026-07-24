import Foundation
import NaturalLanguage

/// On-device language detection via `NLLanguageRecognizer`.
/// Returns a language code only when the top hypothesis probability is at least 0.9; otherwise `nil`.
public struct GLILanguageDetector: GLILanguageDetectorType {
    private static let minimumConfidence = 0.9

    public init() {}

    public func detectSourceLanguage(in text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(trimmed)

        guard let (language, probability) = recognizer.languageHypotheses(withMaximum: 1).first,
              probability >= Self.minimumConfidence
        else {
            return nil
        }

        return language.rawValue
    }
}
