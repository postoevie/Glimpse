import ComposableArchitecture
import GlimpseCore

extension GLITargetLanguageDetectorClient: DependencyKey {
    public static var liveValue: GLITargetLanguageDetectorClient {
        .live
    }

    public static var previewValue: GLITargetLanguageDetectorClient {
        .live
    }

    public static var testValue: GLITargetLanguageDetectorClient {
        .unimplemented
    }
}

extension DependencyValues {
    public var targetLanguageDetector: GLITargetLanguageDetectorClient {
        get { self[GLITargetLanguageDetectorClient.self] }
        set { self[GLITargetLanguageDetectorClient.self] = newValue }
    }
}
