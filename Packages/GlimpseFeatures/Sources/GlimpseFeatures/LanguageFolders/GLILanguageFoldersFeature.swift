import ComposableArchitecture
import GlimpseCore
import IssueReporting

// Task: I1-T1 (origin), I1-T2, I1-T3 — docs/planning/l1-capture/I1-T2-language-folders/
@Reducer
public struct GLILanguageFoldersFeature {
    @ObservableState
    public struct State: Equatable {
        public var folders: IdentifiedArrayOf<GLILanguageFolder> = []
        public var customFolders: IdentifiedArrayOf<GLICustomFolder> = []
        /// `false` until both language and custom folder fetches complete once (success or failure);
        /// stays `true` across observation refreshes.
        public var hasCompletedInitialLoad = false
        /// First language-folders fetch finished (success or failure).
        public var hasCompletedLanguageFoldersLoad = false
        /// First custom-folders fetch finished (success or failure).
        public var hasCompletedCustomFoldersLoad = false
        @Presents public var addWord: GLIAddWordFeature.State?
        @Presents public var folderForm: GLIFolderFormFeature.State?
        @Presents public var alert: AlertState<Action.Alert>?

        public init(
            folders: IdentifiedArrayOf<GLILanguageFolder> = [],
            customFolders: IdentifiedArrayOf<GLICustomFolder> = [],
            hasCompletedInitialLoad: Bool = false,
            hasCompletedLanguageFoldersLoad: Bool = false,
            hasCompletedCustomFoldersLoad: Bool = false,
            addWord: GLIAddWordFeature.State? = nil,
            folderForm: GLIFolderFormFeature.State? = nil,
            alert: AlertState<Action.Alert>? = nil
        ) {
            self.folders = folders
            self.customFolders = customFolders
            self.hasCompletedInitialLoad = hasCompletedInitialLoad
            self.hasCompletedLanguageFoldersLoad = hasCompletedLanguageFoldersLoad
            self.hasCompletedCustomFoldersLoad = hasCompletedCustomFoldersLoad
            self.addWord = addWord
            self.folderForm = folderForm
            self.alert = alert
        }

        mutating func markLanguageFoldersLoadCompleted() {
            hasCompletedLanguageFoldersLoad = true
            updateInitialLoadGate()
        }

        mutating func markCustomFoldersLoadCompleted() {
            hasCompletedCustomFoldersLoad = true
            updateInitialLoadGate()
        }

        private mutating func updateInitialLoadGate() {
            if hasCompletedLanguageFoldersLoad && hasCompletedCustomFoldersLoad {
                hasCompletedInitialLoad = true
            }
        }
    }

    @CasePathable
    public enum Action {
        case onAppear
        case foldersLoaded(Result<[GLILanguageFolder], Error>)
        case customFoldersLoaded(Result<[GLICustomFolder], Error>)

        case addButtonTapped
        case newFolderButtonTapped
        /// Bubbles to `GLIAppFeature`, which appends `.folderWords` onto the nav path.
        case folderTapped(GLILanguageFolder.ID)
        /// Bubbles to `GLIAppFeature` for custom-folder path push.
        case customFolderTapped(GLICustomFolder.ID)

        case renameCustomFolderTapped(GLICustomFolder.ID)
        case deleteCustomFolderTapped(GLICustomFolder.ID)

        case addWord(PresentationAction<GLIAddWordFeature.Action>)
        case folderForm(PresentationAction<GLIFolderFormFeature.Action>)
        case alert(PresentationAction<Alert>)

        public enum Alert: Equatable {
            case confirmDeleteCustomFolder(GLICustomFolder.ID)
        }
    }

    private enum CancelID {
        case observeLanguageFolders
        case observeCustomFolders
    }

    @Dependency(\.languageFolders) var languageFolders
    @Dependency(\.wordPairs) var wordPairs
    @Dependency(\.customFolders) var customFolders

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .merge(
                    Self.observeLanguageFolders(
                        languageFolders: languageFolders,
                        wordPairs: wordPairs
                    ),
                    Self.observeCustomFolders(customFolders: customFolders)
                )

            case let .foldersLoaded(.success(folders)):
                state.folders = IdentifiedArray(uniqueElements: folders)
                state.markLanguageFoldersLoadCompleted()
                return .none

            case let .foldersLoaded(.failure(error)):
                state.markLanguageFoldersLoadCompleted()
                reportIssue(error)
                return .none

            case let .customFoldersLoaded(.success(folders)):
                state.customFolders = IdentifiedArray(uniqueElements: folders)
                state.markCustomFoldersLoadCompleted()
                return .none

            case let .customFoldersLoaded(.failure(error)):
                state.markCustomFoldersLoadCompleted()
                reportIssue(error)
                return .none

            case .addButtonTapped:
                state.addWord = GLIAddWordFeature.State(
                    wordPair: GLIWordPair(word: "", translation: "")
                )
                return .none

            case .newFolderButtonTapped:
                state.folderForm = GLIFolderFormFeature.State(mode: .create)
                return .none

            case .folderTapped:
                // Handled by `GLIAppFeature` (path push).
                return .none

            case .customFolderTapped:
                // Handled by `GLIAppFeature` (path push).
                return .none

            case let .renameCustomFolderTapped(id):
                guard let folder = state.customFolders[id: id] else {
                    reportIssue("renameCustomFolderTapped with id missing from customFolders: \(id)")
                    return .none
                }
                state.folderForm = GLIFolderFormFeature.State(
                    mode: .rename(id),
                    name: folder.name
                )
                return .none

            case let .deleteCustomFolderTapped(id):
                guard state.customFolders[id: id] != nil else {
                    reportIssue("deleteCustomFolderTapped with id missing from customFolders: \(id)")
                    return .none
                }
                state.alert = AlertState {
                    TextState("Delete Folder?")
                } actions: {
                    ButtonState(
                        role: .destructive,
                        action: .confirmDeleteCustomFolder(id)
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
                guard let form = state.folderForm else {
                    reportIssue("folderForm saved delegate without presented form")
                    return .none
                }
                let name = form.name
                switch form.mode {
                case .create:
                    guard let sourceLanguage = form.sourceLanguage, !sourceLanguage.isEmpty else {
                        reportIssue("folderForm create saved without sourceLanguage")
                        return .none
                    }
                    return .run { [customFolders] send in
                        _ = try await customFolders.create(name, sourceLanguage)
                        await send(.folderForm(.dismiss))
                    } catch: { error, _ in
                        reportIssue(error)
                    }

                case let .rename(id):
                    return .run { [customFolders] send in
                        _ = try await customFolders.rename(id, name)
                        await send(.folderForm(.dismiss))
                    } catch: { error, _ in
                        reportIssue(error)
                    }
                }

            case .folderForm:
                return .none

            case let .alert(.presented(.confirmDeleteCustomFolder(id))):
                return .run { [customFolders] _ in
                    try await customFolders.delete(id)
                } catch: { error, _ in
                    reportIssue(error)
                }

            case .alert:
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

    private static func observeLanguageFolders(
        languageFolders: GLILanguageFoldersClient,
        wordPairs: GLIWordPairsClient
    ) -> Effect<Action> {
        .run { send in
            await send(.foldersLoaded(Result {
                try await languageFolders.fetchLanguageFolders()
            }))
            // Language folders are auto-created on word save; client has no changes() yet, so observe wordPairs.
            for await _ in wordPairs.changes() {
                await send(.foldersLoaded(Result {
                    try await languageFolders.fetchLanguageFolders()
                }))
            }
        }
        .cancellable(id: CancelID.observeLanguageFolders, cancelInFlight: true)
    }

    private static func observeCustomFolders(
        customFolders: GLICustomFoldersClient
    ) -> Effect<Action> {
        .run { send in
            await send(.customFoldersLoaded(Result {
                try await customFolders.fetch()
            }))
            for await _ in customFolders.changes() {
                await send(.customFoldersLoaded(Result {
                    try await customFolders.fetch()
                }))
            }
        }
        .cancellable(id: CancelID.observeCustomFolders, cancelInFlight: true)
    }
}
