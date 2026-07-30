import ComposableArchitecture
import Foundation
import GlimpseCore
import IssueReporting

// Task: I1-T3 (origin), I1-T4 — docs/planning/l1-capture/I1-T4-word-card/
@Reducer
public struct GLIFolderWordsFeature {
    /// Which folder this destination browses — language or custom — id only on the shared stack path.
    public enum FolderIdentity: Equatable, Sendable {
        case language(UUID)
        case custom(UUID)

        public var id: UUID {
            switch self {
            case let .language(id), let .custom(id):
                id
            }
        }

        public var isCustom: Bool {
            if case .custom = self { return true }
            return false
        }
    }

    /// Snapshot loaded by this feature (metadata + words). Absence of the folder is not represented here — load throws instead.
    public struct LoadedContent: Equatable, Sendable {
        public var languageCode: String?
        public var customFolderName: String?
        public var words: [GLIWordPair]

        public init(
            languageCode: String? = nil,
            customFolderName: String? = nil,
            words: [GLIWordPair] = []
        ) {
            self.languageCode = languageCode
            self.customFolderName = customFolderName
            self.words = words
        }
    }

    /// Domain failures for folder-words load (missing folder shares the failure path with fetch errors).
    public enum LoadError: Error, Equatable {
        case folderMissing(FolderIdentity)
    }

    @ObservableState
    public struct State: Equatable {
        public var identity: FolderIdentity
        public var words: IdentifiedArrayOf<GLIWordPair>
        /// Resolved for `.language` identity after load; drives title + add-word prefill.
        public var languageCode: String?
        /// Resolved for `.custom` identity after load; drives navigation title.
        public var customFolderName: String?
        /// `false` until the first fetch result (success or failure); stays `true` across observation refreshes.
        public var hasCompletedInitialLoad = false
        @Presents public var addWord: GLIAddWordFeature.State?
        @Presents public var folderForm: GLIFolderFormFeature.State?
        @Presents public var alert: AlertState<Action.Alert>?

        public var id: UUID { identity.id }

        public init(
            identity: FolderIdentity,
            words: IdentifiedArrayOf<GLIWordPair> = [],
            languageCode: String? = nil,
            customFolderName: String? = nil,
            hasCompletedInitialLoad: Bool = false,
            addWord: GLIAddWordFeature.State? = nil,
            folderForm: GLIFolderFormFeature.State? = nil,
            alert: AlertState<Action.Alert>? = nil
        ) {
            self.identity = identity
            self.words = words
            self.languageCode = languageCode
            self.customFolderName = customFolderName
            self.hasCompletedInitialLoad = hasCompletedInitialLoad
            self.addWord = addWord
            self.folderForm = folderForm
            self.alert = alert
        }

        /// Language-folder convenience (same path destination as custom).
        public init(
            id: UUID,
            words: IdentifiedArrayOf<GLIWordPair> = [],
            languageCode: String? = nil,
            hasCompletedInitialLoad: Bool = false,
            addWord: GLIAddWordFeature.State? = nil
        ) {
            self.init(
                identity: .language(id),
                words: words,
                languageCode: languageCode,
                hasCompletedInitialLoad: hasCompletedInitialLoad,
                addWord: addWord
            )
        }
    }

    @CasePathable
    public enum Action {
        case onAppear
        case contentLoaded(Result<LoadedContent, Error>)
        case addButtonTapped
        case renameButtonTapped
        case deleteButtonTapped
        /// Bubbles to `GLIAppFeature`, which appends `.wordCard` onto the nav path.
        case wordTapped(GLIWordPair.ID)
        case customFolderRenamed(GLICustomFolder)
        case addWord(PresentationAction<GLIAddWordFeature.Action>)
        case folderForm(PresentationAction<GLIFolderFormFeature.Action>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        public enum Alert: Equatable {
            case confirmDeleteCustomFolder
        }

        @CasePathable
        public enum Delegate {
            /// Parent should pop this folder-words destination from the shared stack.
            case folderDeleted
        }
    }

    private enum CancelID { case observe }

    @Dependency(\.wordPairs) var wordPairs
    @Dependency(\.languageFolders) var languageFolders
    @Dependency(\.customFolders) var customFolders

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                let identity = state.identity
                return .run { [wordPairs, languageFolders, customFolders] send in
                    await send(.contentLoaded(Result {
                        try await Self.loadContent(
                            identity: identity,
                            wordPairs: wordPairs,
                            languageFolders: languageFolders,
                            customFolders: customFolders
                        )
                    }))
                    for await _ in wordPairs.changes() {
                        await send(.contentLoaded(Result {
                            try await Self.loadContent(
                                identity: identity,
                                wordPairs: wordPairs,
                                languageFolders: languageFolders,
                                customFolders: customFolders
                            )
                        }))
                    }
                }
                .cancellable(id: CancelID.observe, cancelInFlight: true)

            case let .contentLoaded(.success(content)):
                state.languageCode = content.languageCode
                state.customFolderName = content.customFolderName
                state.words = IdentifiedArray(uniqueElements: content.words)
                state.hasCompletedInitialLoad = true
                return .none

            case let .contentLoaded(.failure(error)):
                state.words = []
                state.hasCompletedInitialLoad = true
                reportIssue(error)
                return .none

            case .addButtonTapped:
                // Prefill only for concrete language folders; Unsorted and custom stay blank (T2 owns custom filing).
                if let code = state.languageCode,
                   code != GLILanguageFolder.unsortedCode {
                    state.addWord = GLIAddWordFeature.State(
                        wordPair: GLIWordPair(
                            word: "",
                            translation: "",
                            sourceLanguage: code,
                            targetLanguage: code
                        ),
                        didManuallySetSource: true
                    )
                } else {
                    state.addWord = GLIAddWordFeature.State(
                        wordPair: GLIWordPair(word: "", translation: "")
                    )
                }
                return .none

            case .renameButtonTapped:
                guard case let .custom(id) = state.identity else {
                    reportIssue("renameButtonTapped on non-custom folder")
                    return .none
                }
                state.folderForm = GLIFolderFormFeature.State(
                    mode: .rename(id),
                    name: state.customFolderName ?? ""
                )
                return .none

            case .deleteButtonTapped:
                guard state.identity.isCustom else {
                    reportIssue("deleteButtonTapped on non-custom folder")
                    return .none
                }
                state.alert = AlertState {
                    TextState("Delete Folder?")
                } actions: {
                    ButtonState(
                        role: .destructive,
                        action: .confirmDeleteCustomFolder
                    ) {
                        TextState("Delete")
                    }
                    ButtonState(role: .cancel) {
                        TextState("Cancel")
                    }
                } message: {
                    TextState("Words stay in their language folders.")
                }
                return .none

            case let .wordTapped(id):
                guard state.words[id: id] != nil else {
                    reportIssue("wordTapped with id missing from words list: \(id)")
                    return .none
                }
                // Handled by `GLIAppFeature` (path push).
                return .none

            case let .customFolderRenamed(folder):
                state.customFolderName = folder.name
                return .none

            case .addWord(.presented(.delegate(.wordAdded))):
                guard let pair = state.addWord?.wordPair else {
                    reportIssue("wordAdded delegate without presented child draft")
                    return .none
                }
                return .run { [wordPairs] send in
                    try await wordPairs.save(pair)
                    await send(.addWord(.dismiss))
                } catch: { error, _ in
                    reportIssue(error)
                }

            case .addWord:
                return .none

            case .folderForm(.presented(.delegate(.saved))):
                guard case let .custom(id) = state.identity else {
                    reportIssue("folderForm saved on non-custom folder")
                    return .none
                }
                guard let form = state.folderForm else {
                    reportIssue("folderForm saved delegate without presented form")
                    return .none
                }
                guard case .rename = form.mode else {
                    reportIssue("folderForm saved with unexpected mode on folder detail")
                    return .none
                }
                let name = form.name
                return .run { [customFolders] send in
                    let renamed = try await customFolders.rename(id, name)
                    await send(.customFolderRenamed(renamed))
                    await send(.folderForm(.dismiss))
                } catch: { error, _ in
                    reportIssue(error)
                }

            case .folderForm:
                return .none

            case .alert(.presented(.confirmDeleteCustomFolder)):
                guard case let .custom(id) = state.identity else {
                    reportIssue("confirmDeleteCustomFolder on non-custom folder")
                    return .none
                }
                return .run { [customFolders] send in
                    try await customFolders.delete(id)
                    await send(.delegate(.folderDeleted))
                } catch: { error, _ in
                    reportIssue(error)
                }

            case .alert:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$addWord, action: \.addWord) {
            GLIAddWordFeature()
        }
        .ifLet(\.$folderForm, action: \.folderForm) {
            GLIFolderFormFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }

    private static func loadContent(
        identity: FolderIdentity,
        wordPairs: GLIWordPairsClient,
        languageFolders: GLILanguageFoldersClient,
        customFolders: GLICustomFoldersClient
    ) async throws -> LoadedContent {
        switch identity {
        case let .language(id):
            guard let folder = try await languageFolders.fetchLanguageFolder(id) else {
                throw LoadError.folderMissing(identity)
            }
            let words = try await wordPairs.fetchWordPairsInFolder(id)
            return LoadedContent(
                languageCode: folder.languageCode,
                words: words
            )

        case let .custom(id):
            guard let folder = try await customFolders.fetchCustomFolder(id) else {
                throw LoadError.folderMissing(identity)
            }
            let words = try await wordPairs.fetchWordPairsInCustomFolder(id)
            return LoadedContent(
                customFolderName: folder.name,
                words: words
            )
        }
    }
}

extension GLIFolderWordsFeature.LoadError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .folderMissing(identity):
            "folder missing for identity: \(identity)"
        }
    }
}
