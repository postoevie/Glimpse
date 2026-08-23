import ComposableArchitecture
import GlimpseCore
import IssueReporting

extension GLIWordPairMembershipClient: DependencyKey {
    public static var liveValue: GLIWordPairMembershipClient {
        // Apps must inject a real client via withDependencies (see app entry).
        GLIWordPairMembershipClient(
            assignCustomFolder: unimplemented("GLIWordPairMembershipClient.assignCustomFolder"),
            updateSource: unimplemented("GLIWordPairMembershipClient.updateSource"),
            updateCustomFolder: unimplemented("GLIWordPairMembershipClient.updateCustomFolder"),
            pruneEmptyLanguageFolders: unimplemented(
                "GLIWordPairMembershipClient.pruneEmptyLanguageFolders"
            )
        )
    }

    public static var previewValue: GLIWordPairMembershipClient {
        (try? .inMemory()) ?? liveValue
    }
}

extension DependencyValues {
    public var wordPairMembership: GLIWordPairMembershipClient {
        get { self[GLIWordPairMembershipClient.self] }
        set { self[GLIWordPairMembershipClient.self] = newValue }
    }
}
