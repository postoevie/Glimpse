import ComposableArchitecture
import GlimpseCore
import IssueReporting

extension GLIWordMeaningsClient: DependencyKey {
    public static var liveValue: GLIWordMeaningsClient {
        // Apps must inject a real client via withDependencies (see app entry).
        GLIWordMeaningsClient(
            fetch: unimplemented("GLIWordMeaningsClient.fetch"),
            replaceAll: unimplemented("GLIWordMeaningsClient.replaceAll"),
            firstMeanings: unimplemented("GLIWordMeaningsClient.firstMeanings"),
            fetchAll: unimplemented("GLIWordMeaningsClient.fetchAll")
        )
    }

    public static var previewValue: GLIWordMeaningsClient {
        (try? .inMemory()) ?? liveValue
    }
}

extension DependencyValues {
    public var wordMeanings: GLIWordMeaningsClient {
        get { self[GLIWordMeaningsClient.self] }
        set { self[GLIWordMeaningsClient.self] = newValue }
    }
}
