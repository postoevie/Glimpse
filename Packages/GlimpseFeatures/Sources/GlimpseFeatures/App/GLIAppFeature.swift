import ComposableArchitecture
import GlimpseAI
import GlimpseCore
import IssueReporting

// Task: I1-T3 — docs/planning/l1-capture/I1-T3-folder-word-list/
/// Root navigation shell. Owns `NavigationStack` path (folder word list and later destinations).
@Reducer
public struct GLIAppFeature {
    /// Compile-time anchors so Core + AI stay in the Features graph (I0).
    public static let appGroupIdentifier = GLIAppGroup.identifier
    public static let stubGeneration: any GLIGenerationServiceType = GLIUnimplementedGenerationService()

    @Reducer
    public enum Path {
        case folderWords(GLIFolderWordsFeature)
    }

    @ObservableState
    public struct State: Equatable {
        public var languageFolders = GLILanguageFoldersFeature.State()
        public var path = StackState<Path.State>()

        public init(
            languageFolders: GLILanguageFoldersFeature.State = GLILanguageFoldersFeature.State(),
            path: StackState<Path.State> = StackState<Path.State>()
        ) {
            self.languageFolders = languageFolders
            self.path = path
        }
    }

    @CasePathable
    public enum Action {
        case onAppear
        case languageFolders(GLILanguageFoldersFeature.Action)
        case path(StackActionOf<Path>)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Scope(state: \.languageFolders, action: \.languageFolders) {
            GLILanguageFoldersFeature()
        }
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none

            case let .languageFolders(.folderTapped(id)):
                guard let folder = state.languageFolders.folders[id: id] else {
                    reportIssue("folderTapped with id missing from folders list: \(id)")
                    return .none
                }
                state.path.append(
                    .folderWords(
                        GLIFolderWordsFeature.State(
                            id: folder.id,
                            languageCode: folder.languageCode
                        )
                    )
                )
                return .none

            case .languageFolders:
                return .none

            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

extension GLIAppFeature.Path.State: Equatable {}
