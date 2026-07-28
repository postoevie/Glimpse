import ComposableArchitecture
import GlimpseCore
import IssueReporting

extension GLIWordExamplesClient: DependencyKey {
    public static var liveValue: GLIWordExamplesClient {
        // Apps must inject a real client via withDependencies (see app entry).
        GLIWordExamplesClient(
            fetchExample: unimplemented("GLIWordExamplesClient.fetchExample")
        )
    }

    public static var previewValue: GLIWordExamplesClient {
        (try? .inMemory()) ?? liveValue
    }
}

extension DependencyValues {
    public var wordExamples: GLIWordExamplesClient {
        get { self[GLIWordExamplesClient.self] }
        set { self[GLIWordExamplesClient.self] = newValue }
    }
}
