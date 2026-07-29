import ComposableArchitecture
import GlimpseAI
import GlimpseCore
import IssueReporting
import Foundation

// Task: I1-T3 (origin), I1-T4, I1-T5, I1-T6 — docs/planning/l1-capture/I1-T6-resume-folder/
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
        /// Folder ID loaded from persistence; resolved after the first successful folder list load.
        public var pendingResumeFolderID: UUID?
        /// Whether cold-launch persistence has been read into `pendingResumeFolderID`.
        public var hasLoadedPendingResume = false
        /// Whether the root list has completed at least one successful load (required before resolve).
        public var hasCompletedInitialFolderLoad = false
        /// Prevents later folder-list refreshes from pushing a second resume destination.
        public var didAttemptFolderRestore = false

        public init(
            languageFolders: GLILanguageFoldersFeature.State = GLILanguageFoldersFeature.State(),
            path: StackState<Path.State> = StackState<Path.State>(),
            pendingResumeFolderID: UUID? = nil,
            hasLoadedPendingResume: Bool = false,
            hasCompletedInitialFolderLoad: Bool = false,
            didAttemptFolderRestore: Bool = false
        ) {
            self.languageFolders = languageFolders
            self.path = path
            self.pendingResumeFolderID = pendingResumeFolderID
            self.hasLoadedPendingResume = hasLoadedPendingResume
            self.hasCompletedInitialFolderLoad = hasCompletedInitialFolderLoad
            self.didAttemptFolderRestore = didAttemptFolderRestore
        }
    }

    @CasePathable
    public enum Action {
        case onAppear
        case languageFolders(GLILanguageFoldersFeature.Action)
        case path(StackActionOf<Path>)
    }

    @Dependency(\.lastOpenedFolder) var lastOpenedFolder

    public init() {}

    public var body: some Reducer<State, Action> {
        Scope(state: \.languageFolders, action: \.languageFolders) {
            GLILanguageFoldersFeature()
        }
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.hasLoadedPendingResume else {
                    return .none
                }
                state.pendingResumeFolderID = lastOpenedFolder.load()
                state.hasLoadedPendingResume = true
                // Calling restore here too is just defensive so resume still works if a successful folder load ever arrives before that onAppear.
                return Self.attemptFolderRestore(state: &state, lastOpenedFolder: lastOpenedFolder)

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
                lastOpenedFolder.saveFolder(folder.id)
                return .none

            case .languageFolders(.foldersLoaded(.success)):
                state.hasCompletedInitialFolderLoad = true
                return Self.attemptFolderRestore(state: &state, lastOpenedFolder: lastOpenedFolder)

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
        .forEach(\.path, action: \.path) // Wires each StackState element to the matching Path destination reducer. destination reducer runs before base reducer.
        // Run after the stack mutates so a pop-to-root sees `path.isEmpty`.
        // Card-on-stack still leaves the folder destination, so persistence stays.
        Reduce { state, action in
            switch action {
            case .path:
                guard state.didAttemptFolderRestore, state.path.isEmpty else {
                    return .none
                }
                lastOpenedFolder.clearToRoot()
                return .none
            default:
                return .none
            }
        }
    }

    /// Resolves `pendingResumeFolderID` once folders are loaded. Stale IDs clear persistence and stay at root.
    private static func attemptFolderRestore(
        state: inout State,
        lastOpenedFolder: GLILastOpenedFolderClient
    ) -> Effect<Action> {
        guard !state.didAttemptFolderRestore else {
            return .none
        }
        guard state.hasLoadedPendingResume, state.hasCompletedInitialFolderLoad else {
            return .none
        }

        state.didAttemptFolderRestore = true
        defer { state.pendingResumeFolderID = nil }

        // User already navigated (e.g. tapped a folder before restore resolved) — keep their stack.
        guard state.path.isEmpty else {
            return .none
        }

        guard let folderID = state.pendingResumeFolderID else {
            return .none
        }

        guard let folder = state.languageFolders.folders[id: folderID] else {
            lastOpenedFolder.clearToRoot()
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
    }
}

extension GLIAppFeature.Path.State: Equatable {}
