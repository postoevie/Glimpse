import ComposableArchitecture
import GlimpseCore
import IssueReporting

extension GLILastOpenedFolderClient: DependencyKey {
    public static var liveValue: GLILastOpenedFolderClient {
        // Apps must inject a real client via withDependencies (see app entry).
        GLILastOpenedFolderClient(
            load: unimplemented("GLILastOpenedFolderClient.load", placeholder: nil),
            saveFolder: unimplemented("GLILastOpenedFolderClient.saveFolder"),
            clearToRoot: unimplemented("GLILastOpenedFolderClient.clearToRoot")
        )
    }

    public static var testValue: GLILastOpenedFolderClient {
        GLILastOpenedFolderClient(
            load: unimplemented("GLILastOpenedFolderClient.load", placeholder: nil),
            saveFolder: unimplemented("GLILastOpenedFolderClient.saveFolder"),
            clearToRoot: unimplemented("GLILastOpenedFolderClient.clearToRoot")
        )
    }

    public static var previewValue: GLILastOpenedFolderClient {
        .inMemory()
    }
}

extension DependencyValues {
    public var lastOpenedFolder: GLILastOpenedFolderClient {
        get { self[GLILastOpenedFolderClient.self] }
        set { self[GLILastOpenedFolderClient.self] = newValue }
    }
}
