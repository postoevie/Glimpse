import ComposableArchitecture
import GlimpseCore
import IssueReporting

extension GLICustomFoldersClient: DependencyKey {
    public static var liveValue: GLICustomFoldersClient {
        // Apps must inject a real client via withDependencies (see app entry).
        GLICustomFoldersClient(
            fetch: unimplemented("GLICustomFoldersClient.fetch"),
            fetchCustomFolder: unimplemented("GLICustomFoldersClient.fetchCustomFolder"),
            create: unimplemented("GLICustomFoldersClient.create"),
            rename: unimplemented("GLICustomFoldersClient.rename"),
            delete: unimplemented("GLICustomFoldersClient.delete"),
            changes: { AsyncStream { $0.finish() } }
        )
    }

    public static var previewValue: GLICustomFoldersClient {
        (try? .inMemory()) ?? liveValue
    }
}

extension DependencyValues {
    public var customFolders: GLICustomFoldersClient {
        get { self[GLICustomFoldersClient.self] }
        set { self[GLICustomFoldersClient.self] = newValue }
    }
}
