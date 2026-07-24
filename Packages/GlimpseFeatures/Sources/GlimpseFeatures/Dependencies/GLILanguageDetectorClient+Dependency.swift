import ComposableArchitecture
import GlimpseCore

extension GLILanguageDetectorClient: DependencyKey {
    public static var liveValue: GLILanguageDetectorClient {
        // Apps inject `.live` via withDependencies (see app entry).
        .unimplemented
    }

    public static var previewValue: GLILanguageDetectorClient {
        .live
    }
}

extension DependencyValues {
    public var languageDetector: GLILanguageDetectorClient {
        get { self[GLILanguageDetectorClient.self] }
        set { self[GLILanguageDetectorClient.self] = newValue }
    }
}
