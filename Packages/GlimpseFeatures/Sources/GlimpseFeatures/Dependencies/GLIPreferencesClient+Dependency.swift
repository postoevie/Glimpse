import ComposableArchitecture
import GlimpseCore
import IssueReporting

extension GLIPreferencesClient: DependencyKey {
    public static var liveValue: GLIPreferencesClient {
        // Apps must inject a real client via withDependencies (see app entry).
        GLIPreferencesClient(
            defaultCustomFolderID: unimplemented(
                "GLIPreferencesClient.defaultCustomFolderID",
                placeholder: nil
            ),
            setDefaultCustomFolderID: unimplemented("GLIPreferencesClient.setDefaultCustomFolderID"),
            clearDefaultCustomFolderID: unimplemented(
                "GLIPreferencesClient.clearDefaultCustomFolderID"
            )
        )
    }

    public static var testValue: GLIPreferencesClient {
        GLIPreferencesClient(
            defaultCustomFolderID: unimplemented(
                "GLIPreferencesClient.defaultCustomFolderID",
                placeholder: nil
            ),
            setDefaultCustomFolderID: unimplemented("GLIPreferencesClient.setDefaultCustomFolderID"),
            clearDefaultCustomFolderID: unimplemented(
                "GLIPreferencesClient.clearDefaultCustomFolderID"
            )
        )
    }

    public static var previewValue: GLIPreferencesClient {
        .inMemory()
    }
}

extension DependencyValues {
    public var preferences: GLIPreferencesClient {
        get { self[GLIPreferencesClient.self] }
        set { self[GLIPreferencesClient.self] = newValue }
    }
}
