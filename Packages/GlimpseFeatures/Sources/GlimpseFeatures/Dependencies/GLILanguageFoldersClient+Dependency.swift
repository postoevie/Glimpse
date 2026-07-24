import ComposableArchitecture
import GlimpseCore
import IssueReporting

extension GLILanguageFoldersClient: DependencyKey {
    public static var liveValue: GLILanguageFoldersClient {
        // Apps must inject a real client via withDependencies (see app entry).
        GLILanguageFoldersClient(
            fetchLanguageFolders: unimplemented("GLILanguageFoldersClient.fetchLanguageFolders")
        )
    }

    public static var previewValue: GLILanguageFoldersClient {
        (try? .inMemory()) ?? liveValue
    }
}

extension DependencyValues {
    public var languageFolders: GLILanguageFoldersClient {
        get { self[GLILanguageFoldersClient.self] }
        set { self[GLILanguageFoldersClient.self] = newValue }
    }
}
