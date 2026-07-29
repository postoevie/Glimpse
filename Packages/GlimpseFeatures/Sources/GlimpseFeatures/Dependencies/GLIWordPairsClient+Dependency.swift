import ComposableArchitecture
import GlimpseCore
import IssueReporting

extension GLIWordPairsClient: DependencyKey {
    public static var liveValue: GLIWordPairsClient {
        // Apps must inject a real client via withDependencies (see app entry).
        GLIWordPairsClient(
            fetchWordPairs: unimplemented("GLIWordPairsClient.fetchWordPairs"),
            fetchWordPairsInFolder: unimplemented("GLIWordPairsClient.fetchWordPairsInFolder"),
            fetchWordPairsInCustomFolder: unimplemented("GLIWordPairsClient.fetchWordPairsInCustomFolder"),
            save: unimplemented("GLIWordPairsClient.save"),
            changes: { AsyncStream { $0.finish() } }
        )
    }

    public static var previewValue: GLIWordPairsClient {
        (try? .inMemory()) ?? liveValue
    }
}

extension DependencyValues {
    public var wordPairs: GLIWordPairsClient {
        get { self[GLIWordPairsClient.self] }
        set { self[GLIWordPairsClient.self] = newValue }
    }
}
