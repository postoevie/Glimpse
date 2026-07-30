import ComposableArchitecture
import GlimpseAI
import GlimpseCore
import IssueReporting
import Foundation

// Task: I1-T3 (origin), I1-T4, I1-T5, I1-T6, I2-T1 — docs/planning/l2-organize/I2-T1-custom-folders/
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
        /// Folder destination loaded from persistence; validated against SwiftData before push.
        public var pendingResumeFolder: GLILastOpenedFolder?
        /// Whether cold-launch persistence has been read into `pendingResumeFolder`.
        public var hasLoadedPendingResume = false
        /// Mirrors `languageFolders.hasCompletedInitialLoad` (both language and custom fetches done once).
        /// Kept for root UI polish; resume validation does **not** require in-memory list membership.
        public var hasCompletedInitialFolderLoad = false
        /// Prevents a second SwiftData validation / push for the same cold launch.
        public var didAttemptFolderRestore = false

        public init(
            languageFolders: GLILanguageFoldersFeature.State = GLILanguageFoldersFeature.State(),
            path: StackState<Path.State> = StackState<Path.State>(),
            pendingResumeFolder: GLILastOpenedFolder? = nil,
            hasLoadedPendingResume: Bool = false,
            hasCompletedInitialFolderLoad: Bool = false,
            didAttemptFolderRestore: Bool = false
        ) {
            self.languageFolders = languageFolders
            self.path = path
            self.pendingResumeFolder = pendingResumeFolder
            self.hasLoadedPendingResume = hasLoadedPendingResume
            self.hasCompletedInitialFolderLoad = hasCompletedInitialFolderLoad
            self.didAttemptFolderRestore = didAttemptFolderRestore
        }
    }

    @CasePathable
    public enum Action {
        case onAppear
        case resumeFolderValidated(GLILastOpenedFolder?)
        case languageFolders(GLILanguageFoldersFeature.Action)
        case path(StackActionOf<Path>)
    }

    @Dependency(\.lastOpenedFolder) var lastOpenedFolder
    @Dependency(\.languageFolders) var languageFolders
    @Dependency(\.customFolders) var customFolders

    public init() {}

    private enum CancelID { case resumeFolderValidation }

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
                state.pendingResumeFolder = lastOpenedFolder.load()
                state.hasLoadedPendingResume = true
                return Self.attemptFolderRestore(
                    state: &state,
                    lastOpenedFolder: lastOpenedFolder,
                    languageFolders: languageFolders,
                    customFolders: customFolders
                )

            case let .resumeFolderValidated(destination):
                // User already navigated while validation was in flight — keep their stack.
                guard state.path.isEmpty else {
                    return .none
                }
                guard let destination else {
                    // Stale or missing: preference already cleared by Core; stay at root.
                    return .none
                }
                switch destination {
                case .language(let id):
                    state.path.append(
                        .folderWords(
                            GLIFolderWordsFeature.State(identity: .language(id))
                        )
                    )
                case .custom(let id):
                    state.path.append(
                        .folderWords(
                            GLIFolderWordsFeature.State(identity: .custom(id))
                        )
                    )
                }
                return .none

            case let .languageFolders(.folderTapped(id)):
                state.path.append(
                    .folderWords(
                        GLIFolderWordsFeature.State(identity: .language(id))
                    )
                )
                lastOpenedFolder.save(.language(id))
                return .none

            case let .languageFolders(.customFolderTapped(id)):
                state.path.append(
                    .folderWords(
                        GLIFolderWordsFeature.State(identity: .custom(id))
                    )
                )
                lastOpenedFolder.save(.custom(id))
                return .none

            case .languageFolders(.foldersLoaded),
                 .languageFolders(.customFoldersLoaded):
                state.hasCompletedInitialFolderLoad = state.languageFolders.hasCompletedInitialLoad
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

            case let .path(
                .element(
                    id: pathID,
                    action: .folderWords(.delegate(.folderDeleted))
                )
            ):
                guard state.path.ids.last == pathID else {
                    reportIssue("folderDeleted was not the top navigation destination: \(pathID)")
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

    /// Starts SwiftData validation of the persisted folder once pending is loaded.
    /// Stale destinations are cleared in UserDefaults by Core; no in-memory list membership check.
    private static func attemptFolderRestore(
        state: inout State,
        lastOpenedFolder: GLILastOpenedFolderClient,
        languageFolders: GLILanguageFoldersClient,
        customFolders: GLICustomFoldersClient
    ) -> Effect<Action> {
        guard !state.didAttemptFolderRestore else {
            return .none
        }
        guard state.hasLoadedPendingResume else {
            return .none
        }

        state.didAttemptFolderRestore = true

        // User already navigated (e.g. tapped a folder before restore resolved) — keep their stack.
        guard state.path.isEmpty else {
            state.pendingResumeFolder = nil
            return .none
        }

        guard state.pendingResumeFolder != nil else {
            state.pendingResumeFolder = nil
            return .none
        }

        state.pendingResumeFolder = nil

        return .run { send in
            let destination = await lastOpenedFolder.loadClearingIfFolderMissing(
                fetchLanguageFolder: languageFolders.fetchLanguageFolder,
                fetchCustomFolder: customFolders.fetchCustomFolder
            )
            await send(.resumeFolderValidated(destination))
        }
        .cancellable(id: CancelID.resumeFolderValidation, cancelInFlight: true)
    }
}

extension GLIAppFeature.Path.State: Equatable {}
