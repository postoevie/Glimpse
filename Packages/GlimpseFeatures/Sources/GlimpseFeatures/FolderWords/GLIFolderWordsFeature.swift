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
        public var customFolderSourceLanguage: String?
        public var customFolderTargetLanguage: String?
        public var words: [GLIWordPair]
        /// First (oldest) meaning text per word, for the row subtitle. Missing keys = no meanings.
        public var firstMeaningTexts: [GLIWordPair.ID: String]

        public init(
            languageCode: String? = nil,
            customFolderName: String? = nil,
            customFolderSourceLanguage: String? = nil,
            customFolderTargetLanguage: String? = nil,
            words: [GLIWordPair] = [],
            firstMeaningTexts: [GLIWordPair.ID: String] = [:]
        ) {
            self.languageCode = languageCode
            self.customFolderName = customFolderName
            self.customFolderSourceLanguage = customFolderSourceLanguage
            self.customFolderTargetLanguage = customFolderTargetLanguage
            self.words = words
            self.firstMeaningTexts = firstMeaningTexts
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
        /// First (oldest) meaning text per word, for the row subtitle. Missing keys = no meanings.
        public var firstMeaningTexts: [GLIWordPair.ID: String] = [:]
        /// Resolved for `.language` identity after load; drives title + add-word prefill.
        public var languageCode: String?
        /// Resolved for `.custom` identity after load; drives navigation title.
        public var customFolderName: String?
        /// Filled from load when still nil. Add source lock for custom folders.
        public var customFolderSourceLanguage: String?
        /// Filled from load when still nil. Add target prefill for custom folders.
        public var customFolderTargetLanguage: String?
        /// `false` until the first fetch result (success or failure); stays `true` across observation refreshes.
        public var hasCompletedInitialLoad = false
        @Presents public var addWord: GLIAddWordFeature.State?
        @Presents public var folderForm: GLIFolderFormFeature.State?
        @Presents public var alert: AlertState<Action.Alert>?

        public var id: UUID { identity.id }

        public init(
            identity: FolderIdentity,
            words: IdentifiedArrayOf<GLIWordPair> = [],
            firstMeaningTexts: [GLIWordPair.ID: String] = [:],
            languageCode: String? = nil,
            customFolderName: String? = nil,
            customFolderSourceLanguage: String? = nil,
            customFolderTargetLanguage: String? = nil,
            hasCompletedInitialLoad: Bool = false,
            addWord: GLIAddWordFeature.State? = nil,
            folderForm: GLIFolderFormFeature.State? = nil,
            alert: AlertState<Action.Alert>? = nil
        ) {
            self.identity = identity
            self.words = words
            self.firstMeaningTexts = firstMeaningTexts
            self.languageCode = languageCode
            self.customFolderName = customFolderName
            self.customFolderSourceLanguage = customFolderSourceLanguage
            self.customFolderTargetLanguage = customFolderTargetLanguage
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
        case presentAddWord(GLIAddWordFeature.State)
        case renameButtonTapped
        case deleteButtonTapped
        /// Bubbles to `GLIAppFeature`, which appends `.wordCard` onto the nav path.
        case wordTapped(GLIWordPair.ID)
        case customFolderRenamed(GLICustomFolder)
        case addWord(PresentationAction<GLIAddWordFeature.Action>)
        case folderForm(PresentationAction<GLIFolderFormFeature.Action>)
        case alert(PresentationAction<Alert>)
        case wordSaveFailed
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
    @Dependency(\.wordMeanings) var wordMeanings
    @Dependency(\.wordPairMembership) var wordPairMembership
    @Dependency(\.preferences) var preferences

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                let identity = state.identity
                return .run { [wordPairs, languageFolders, customFolders, wordMeanings] send in
                    await send(.contentLoaded(Result {
                        try await Self.loadContent(
                            identity: identity,
                            wordPairs: wordPairs,
                            languageFolders: languageFolders,
                            customFolders: customFolders,
                            wordMeanings: wordMeanings
                        )
                    }))
                    for await _ in wordPairs.changes() {
                        await send(.contentLoaded(Result {
                            try await Self.loadContent(
                                identity: identity,
                                wordPairs: wordPairs,
                                languageFolders: languageFolders,
                                customFolders: customFolders,
                                wordMeanings: wordMeanings
                            )
                        }))
                    }
                }
                .cancellable(id: CancelID.observe, cancelInFlight: true)

            case let .contentLoaded(.success(content)):
                state.languageCode = content.languageCode
                state.customFolderName = content.customFolderName
                if state.customFolderSourceLanguage == nil {
                    state.customFolderSourceLanguage = content.customFolderSourceLanguage
                }
                if state.customFolderTargetLanguage == nil {
                    state.customFolderTargetLanguage = content.customFolderTargetLanguage
                }
                state.words = IdentifiedArray(uniqueElements: content.words)
                state.firstMeaningTexts = content.firstMeaningTexts
                state.hasCompletedInitialLoad = true
                return .none

            case let .contentLoaded(.failure(error)):
                state.words = []
                state.hasCompletedInitialLoad = true
                reportIssue(error)
                return .none

            case .addButtonTapped:
                switch state.identity {
                case let .custom(id):
                    if let source = state.customFolderSourceLanguage {
                        let target = state.customFolderTargetLanguage ?? source
                        state.addWord = Self.addWordState(
                            customFolderID: id,
                            sourceLanguage: source,
                            targetLanguage: target
                        )
                        return .none
                    }
                    return .run { [customFolders] send in
                        do {
                            guard let folder = try await customFolders.fetchCustomFolder(id) else {
                                reportIssue("addButtonTapped: custom folder missing for id \(id)")
                                return
                            }
                            await send(.presentAddWord(Self.addWordState(for: folder)))
                        } catch {
                            reportIssue(error)
                        }
                    }

                case .language:
                    if let code = state.languageCode,
                       code != GLILanguageFolder.unsortedCode {
                        state.addWord = GLIAddWordFeature.State(
                            wordPair: GLIWordPair(
                                word: "",
                                sourceLanguage: code,
                                targetLanguage: code
                            ),
                            didManuallySetSource: true,
                            selectedCustomFolderID: nil,
                            defaultCustomFolderPrefillMode: .matchPendingSource
                        )
                    } else {
                        state.addWord = GLIAddWordFeature.State(
                            wordPair: GLIWordPair(word: ""),
                            selectedCustomFolderID: nil,
                            defaultCustomFolderPrefillMode: .always
                        )
                    }
                    return .none
                }

            case let .presentAddWord(addState):
                state.addWord = addState
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
                state.customFolderSourceLanguage = folder.sourceLanguage
                state.customFolderTargetLanguage = folder.targetLanguage
                return .none

            case .addWord(.presented(.delegate(.wordAdded))):
                guard let addWord = state.addWord else {
                    reportIssue("wordAdded delegate without presented child draft")
                    return .none
                }
                let pair = addWord.pairForPersist
                let meaning = addWord.captureMeaning
                let selectedCustomFolderID = addWord.selectedCustomFolderID
                return .run { [wordPairs, wordMeanings, preferences, wordPairMembership] send in
                    try await wordPairs.save(pair)
                    if let meaning {
                        try await wordMeanings.replaceAll(pair.id, [meaning])
                    }
                    try await wordPairMembership.assignCustomFolder(
                        pair.id,
                        selectedCustomFolderID,
                        pair.targetLanguage
                    )
                    if let selectedCustomFolderID {
                        preferences.setDefaultCustomFolderID(selectedCustomFolderID)
                    } else {
                        preferences.clearDefaultCustomFolderID()
                    }
                    await send(.addWord(.dismiss))
                } catch: { error, send in
                    reportIssue(error)
                    await send(.wordSaveFailed)
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

            case .wordSaveFailed:
                state.addWord?.isSaving = false
                state.alert = AlertState {
                    TextState("Couldn't save word")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("OK")
                    }
                } message: {
                    TextState("Your draft is still here.")
                }
                return .none

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

    private static func addWordState(for folder: GLICustomFolder) -> GLIAddWordFeature.State {
        addWordState(
            customFolderID: folder.id,
            sourceLanguage: folder.sourceLanguage,
            targetLanguage: folder.targetLanguage ?? folder.sourceLanguage
        )
    }

    private static func addWordState(
        customFolderID: UUID,
        sourceLanguage: String,
        targetLanguage: String
    ) -> GLIAddWordFeature.State {
        GLIAddWordFeature.State(
            wordPair: GLIWordPair(
                word: "",
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage
            ),
            didManuallySetSource: true,
            selectedCustomFolderID: customFolderID
        )
    }

    private static func loadContent(
        identity: FolderIdentity,
        wordPairs: GLIWordPairsClient,
        languageFolders: GLILanguageFoldersClient,
        customFolders: GLICustomFoldersClient,
        wordMeanings: GLIWordMeaningsClient
    ) async throws -> LoadedContent {
        switch identity {
        case let .language(id):
            guard let folder = try await languageFolders.fetchLanguageFolder(id) else {
                throw LoadError.folderMissing(identity)
            }
            let words = try await wordPairs.fetchWordPairsInFolder(id)
            let firstMeaningTexts = try await wordMeanings.firstMeanings(words.map(\.id))
            return LoadedContent(
                languageCode: folder.languageCode,
                words: words,
                firstMeaningTexts: firstMeaningTexts
            )

        case let .custom(id):
            guard let folder = try await customFolders.fetchCustomFolder(id) else {
                throw LoadError.folderMissing(identity)
            }
            let words = try await wordPairs.fetchWordPairsInCustomFolder(id)
            let firstMeaningTexts = try await wordMeanings.firstMeanings(words.map(\.id))
            return LoadedContent(
                customFolderName: folder.name,
                customFolderSourceLanguage: folder.sourceLanguage,
                customFolderTargetLanguage: folder.targetLanguage,
                words: words,
                firstMeaningTexts: firstMeaningTexts
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
