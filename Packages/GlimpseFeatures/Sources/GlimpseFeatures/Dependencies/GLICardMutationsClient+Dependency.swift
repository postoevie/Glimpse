import ComposableArchitecture
import GlimpseCore
import IssueReporting

extension GLICardMutationsClient: DependencyKey {
    public static var liveValue: GLICardMutationsClient {
        // Apps must inject a real client via withDependencies (see app entry).
        GLICardMutationsClient(
            update: unimplemented("GLICardMutationsClient.update"),
            delete: unimplemented("GLICardMutationsClient.delete")
        )
    }

    public static var previewValue: GLICardMutationsClient {
        (try? .inMemory()) ?? liveValue
    }
}

extension DependencyValues {
    public var cardMutations: GLICardMutationsClient {
        get { self[GLICardMutationsClient.self] }
        set { self[GLICardMutationsClient.self] = newValue }
    }
}
