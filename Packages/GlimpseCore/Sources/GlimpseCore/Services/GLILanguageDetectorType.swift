import Foundation

/// Source language code, or nil if unknown.
public protocol GLILanguageDetectorType: Sendable {
    func detectSourceLanguage(in text: String) -> String?
}
