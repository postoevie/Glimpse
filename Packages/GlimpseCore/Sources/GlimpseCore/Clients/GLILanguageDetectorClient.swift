import Foundation

/// Capture-facing wrapper around `GLILanguageDetectorType` (TCA-free; Features inject via `@Dependency`).
public struct GLILanguageDetectorClient: Sendable {
    public var detectSourceLanguage: @Sendable (String) -> String?

    public init(detectSourceLanguage: @escaping @Sendable (String) -> String?) {
        self.detectSourceLanguage = detectSourceLanguage
    }
}

extension GLILanguageDetectorClient {
    public static let live = GLILanguageDetectorClient(
        detectSourceLanguage: { text in
            GLILanguageDetector().detectSourceLanguage(in: text)
        }
    )

    public static let unimplemented = GLILanguageDetectorClient(
        detectSourceLanguage: { _ in nil }
    )
}
