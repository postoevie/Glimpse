import ComposableArchitecture
import GlimpseAI
import GlimpseCore
import IssueReporting

// Task: I1-T3 (origin), I1-T4, I1-T5 — docs/planning/l1-capture/I1-T5-card-edit-delete/
/// Root navigation shell. Owns `NavigationStack` path (folder word list and word card).
@Reducer
public struct GLIAppFeature {
    /// Compile-time anchors so Core + AI stay in the Features graph (I0).
    public static let appGroupIdentifier = GLIAppGroup.identifier
    public static let stubGeneration: any GLIGenerationServiceType = GLIUnimplementedGenerationService()

    @Reducer
    public enum Path {
        case folderWords(GLIFolderWordsFeature)
        case wordCard(GLIWordCardFeature)
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

            case let .path(
                .element(
                    id: pathID,
                    action: .folderWords(.wordTapped(wordID))
                )
            ):
                guard let folderWords = state.path[id: pathID, case: \.folderWords] else {
                    reportIssue("wordTapped from missing folder words path: \(pathID)")
                    return .none
                }
                guard let wordPair = folderWords.words[id: wordID] else {
                    reportIssue("wordTapped with id missing from folder words: \(wordID)")
                    return .none
                }
                state.path.append(
                    .wordCard(GLIWordCardFeature.State(wordPair: wordPair))
                )
                return .none

            case let .path(
                .element(
                    id: pathID,
                    action: .wordCard(.delegate(.updated(wordPair)))
                )
            ):
                let pathIDs = Array(state.path.ids)
                guard let cardIndex = pathIDs.firstIndex(of: pathID),
                      cardIndex > pathIDs.startIndex else {
                    reportIssue("updated word card missing its preceding folder path: \(pathID)")
                    return .none
                }
                let folderPathID = pathIDs[pathIDs.index(before: cardIndex)]
                guard state.path[id: folderPathID, case: \.folderWords] != nil else {
                    reportIssue("updated word card preceded by a non-folder path: \(pathID)")
                    return .none
                }
                guard state.path[id: folderPathID, case: \.folderWords]?.words[id: wordPair.id] != nil else {
                    reportIssue("updated word missing from preceding folder snapshot: \(wordPair.id)")
                    return .none
                }
                state.path[id: folderPathID, case: \.folderWords]?.words[id: wordPair.id] = wordPair
                return .none

            case let .path(
                .element(
                    id: pathID,
                    action: .wordCard(.delegate(.deleted(wordID)))
                )
            ):
                let pathIDs = Array(state.path.ids)
                guard let cardIndex = pathIDs.firstIndex(of: pathID),
                      cardIndex > pathIDs.startIndex else {
                    reportIssue("deleted word card missing its preceding folder path: \(pathID)")
                    return .none
                }
                let folderPathID = pathIDs[pathIDs.index(before: cardIndex)]
                guard state.path[id: folderPathID, case: \.folderWords] != nil else {
                    reportIssue("deleted word card preceded by a non-folder path: \(pathID)")
                    return .none
                }
                state.path[id: folderPathID, case: \.folderWords]?.words.remove(id: wordID)
                guard state.path.ids.last == pathID else {
                    reportIssue("deleted word card was not the top navigation destination: \(pathID)")
                    return .none
                }
                state.path.removeLast()
                return .none

            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

extension GLIAppFeature.Path.State: Equatable {}
