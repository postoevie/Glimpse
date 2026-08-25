import ComposableArchitecture
import Foundation
import GlimpseCore
import IssueReporting

// Task: I1-T4 (origin), I1-T5, I1-B3, I2-T3 / I2-T4 — docs/planning/l1-capture/, l2-organize/
//
// Meanings: hand-typed text + optional detected language + optional example, `nil` while
// loading, capped at `maxMeaningsPerWord`. No generation (see `GLIGenerationServiceType`).
// Membership: Source + Custom folder controls work while viewing or editing (blocked only
// while saving/deleting), via `wordPairMembership.updateSource` / `.updateCustomFolder`.
@Reducer
public struct GLIWordCardFeature {
    @ObservableState
    public struct State: Equatable {
        public struct Draft: Equatable {
            public var word: String
            public var meanings: IdentifiedArrayOf<GLIWordMeaning>
            public var targetLanguage: String?

            public init(wordPair: GLIWordPair, meanings: IdentifiedArrayOf<GLIWordMeaning>) {
                word = wordPair.word
                self.meanings = meanings
                targetLanguage = wordPair.targetLanguage
            }
        }

        public enum MeaningsLoadState: Equatable {
            case loading
            case loaded(IdentifiedArrayOf<GLIWordMeaning>)
            case failed
        }

        public var wordPair: GLIWordPair
        public var meaningsLoadState: MeaningsLoadState
        public var draft: Draft
        public var isEditing = false
        public var isSaving = false
        public var isDeleting = false
        /// Every custom folder, unfiltered — the only stored copy. `eligibleCustomFolders`
        /// below is a filtered view of this, not a separate fetch.
        public var allCustomFolders: IdentifiedArrayOf<GLICustomFolder> = []
        @Presents public var alert: AlertState<Action.Alert>?

        public static let maxMeaningsPerWord = 20

        public var canSave: Bool {
            isEditing
                && !isSaving
                && !isDeleting
                && !draft.word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        public var canEdit: Bool {
            guard case .loaded = meaningsLoadState else { return false }
            return !isDeleting
        }

        public var isAtMeaningCap: Bool {
            draft.meanings.count >= Self.maxMeaningsPerWord
        }

        /// Unsorted (`sourceLanguage == nil`) — picker lists `allCustomFolders`.
        public var isUnsorted: Bool {
            wordPair.sourceLanguage == nil
        }

        /// Known source — picker lists `eligibleCustomFolders`.
        public var hasSourceLanguage: Bool {
            wordPair.sourceLanguage != nil
        }

        /// Folders matching item source — computed from `allCustomFolders`, not a separate fetch.
        public var eligibleCustomFolders: IdentifiedArrayOf<GLICustomFolder> {
            guard let sourceLanguage = wordPair.sourceLanguage else { return [] }
            return IdentifiedArray(
                uniqueElements: allCustomFolders.filter { $0.sourceLanguage == sourceLanguage }
            )
        }

        public init(
            wordPair: GLIWordPair,
            meaningsLoadState: MeaningsLoadState = .loading,
            allCustomFolders: IdentifiedArrayOf<GLICustomFolder> = []
        ) {
            self.wordPair = wordPair
            self.meaningsLoadState = meaningsLoadState
            self.allCustomFolders = allCustomFolders
            let loadedMeanings: IdentifiedArrayOf<GLIWordMeaning>
            if case let .loaded(meanings) = meaningsLoadState {
                loadedMeanings = meanings
            } else {
                loadedMeanings = []
            }
            draft = Draft(wordPair: wordPair, meanings: loadedMeanings)
        }
    }

    @CasePathable
    public enum Action: ViewAction {
        @CasePathable
        public enum View: Equatable {
            case onAppear
            case editButtonTapped
            case cancelButtonTapped
            case wordChanged(String)
            case meaningTextChanged(id: GLIWordMeaning.ID, text: String)
            case meaningExampleChanged(id: GLIWordMeaning.ID, text: String)
            case addMeaningTapped
            case removeMeaningTapped(id: GLIWordMeaning.ID)
            case targetLanguageChanged(String?)
            case saveButtonTapped
            case deleteButtonTapped
            /// Assign or clear custom-folder membership via `wordPairMembership`.
            case customFolderPicked(UUID?)
            case customFolderCleared
            /// Source language pick via `wordPairMembership.updateSource` (nil -> Unsorted).
            case sourceLanguagePicked(String?)
        }

        @CasePathable
        public enum Delegate: Equatable {
            case updated(GLIWordPair)
            case deleted(GLIWordPair.ID)
        }

        public enum Alert: Equatable {
            case confirmDelete
            case retrySave
            case retryDelete
        }

        case view(View)
        case delegate(Delegate)
        case alert(PresentationAction<Alert>)
        case meaningsLoaded([GLIWordMeaning])
        case meaningsLoadFailed
        case saveSucceeded(GLIWordPair, meanings: [GLIWordMeaning])
        case saveFailed
        case deleteConfirmed
        case deleteSucceeded
        case deleteFailed
        case customFoldersLoaded([GLICustomFolder])
        case sourceUpdateSucceeded(GLIWordPair)
        case customFolderUpdateSucceeded(GLIWordPair)
        case languageDetectionResponse(meaningID: GLIWordMeaning.ID, code: String?)
    }

    /// Debounce after meaning text settles before running language detection.
    private static let detectionDebounce: Duration = .milliseconds(400)

    private enum CancelID: Hashable {
        case loadMeanings
        case loadCustomFolders
        case membership
        case detectLanguage(GLIWordMeaning.ID)
    }

    @Dependency(\.wordMeanings) private var wordMeanings
    @Dependency(\.cardMutations) private var cardMutations
    @Dependency(\.customFolders) private var customFolders
    @Dependency(\.wordPairMembership) private var wordPairMembership
    @Dependency(\.languageDetector) private var languageDetector
    @Dependency(\.continuousClock) private var clock
    @Dependency(\.uuid) private var uuid

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                guard !state.isEditing else {
                    return .none
                }
                state.meaningsLoadState = .loading
                let wordID = state.wordPair.id

                let loadMeanings: Effect<Action> = .run { [wordMeanings] send in
                    do {
                        let meanings = try await wordMeanings.fetch(wordID)
                        await send(.meaningsLoaded(meanings))
                    } catch is CancellationError {
                        return
                    } catch {
                        reportIssue(error)
                        await send(.meaningsLoadFailed)
                    }
                }
                .cancellable(id: CancelID.loadMeanings, cancelInFlight: true)

                return .merge(
                    loadMeanings,
                    Self.loadCustomFoldersEffect(customFolders: customFolders)
                )

            case let .meaningsLoaded(meanings):
                let loaded = IdentifiedArrayOf<GLIWordMeaning>(uniqueElements: meanings)
                state.meaningsLoadState = .loaded(loaded)
                if !state.isEditing {
                    state.draft = State.Draft(wordPair: state.wordPair, meanings: loaded)
                }
                return .none

            case .meaningsLoadFailed:
                state.meaningsLoadState = .failed
                return .none

            case let .customFoldersLoaded(folders):
                state.allCustomFolders = IdentifiedArray(uniqueElements: folders)
                return .none

            case let .view(.sourceLanguagePicked(sourceLanguage)):
                guard !state.isSaving, !state.isDeleting else {
                    reportIssue("sourceLanguagePicked while saving or deleting — the view locks this control in that state")
                    return .none
                }
                let normalized: String?
                if let sourceLanguage {
                    let code = sourceLanguage.trimmingCharacters(in: .whitespacesAndNewlines)
                    normalized = code.isEmpty ? nil : code
                } else {
                    normalized = nil
                }
                guard normalized != state.wordPair.sourceLanguage else {
                    return .none
                }
                let wordID = state.wordPair.id
                return .run { [wordPairMembership] send in
                    let wordPair = try await wordPairMembership.updateSource(wordID, normalized)
                    await send(.sourceUpdateSucceeded(wordPair))
                } catch: { error, _ in
                    reportIssue(error)
                }
                .cancellable(id: CancelID.membership, cancelInFlight: true)

            case let .sourceUpdateSucceeded(result):
                state.wordPair = result
                return .send(.delegate(.updated(result)))

            case let .view(.customFolderPicked(folderID)):
                guard !state.isSaving, !state.isDeleting else {
                    reportIssue("customFolderPicked while saving or deleting — the view locks this control in that state")
                    return .none
                }
                guard let folderID else {
                    return .send(.view(.customFolderCleared))
                }
                let wordID = state.wordPair.id
                return .run { [wordPairMembership] send in
                    let wordPair = try await wordPairMembership.updateCustomFolder(wordID, folderID)
                    await send(.customFolderUpdateSucceeded(wordPair))
                } catch: { error, _ in
                    reportIssue(error)
                }
                .cancellable(id: CancelID.membership, cancelInFlight: true)

            case .view(.customFolderCleared):
                guard !state.isSaving, !state.isDeleting else {
                    reportIssue("customFolderCleared while saving or deleting — should be unreachable, forwarded from customFolderPicked's own guard")
                    return .none
                }
                let wordID = state.wordPair.id
                return .run { [wordPairMembership] send in
                    let wordPair = try await wordPairMembership.updateCustomFolder(wordID, nil)
                    await send(.customFolderUpdateSucceeded(wordPair))
                } catch: { error, _ in
                    reportIssue(error)
                }
                .cancellable(id: CancelID.membership, cancelInFlight: true)

            case let .customFolderUpdateSucceeded(result):
                state.wordPair = result
                return .send(.delegate(.updated(result)))

            case .view(.editButtonTapped):
                guard state.canEdit, case let .loaded(loaded) = state.meaningsLoadState else {
                    return .none
                }
                state.draft = State.Draft(wordPair: state.wordPair, meanings: loaded)
                state.isEditing = true
                if state.draft.meanings.isEmpty {
                    state.draft.meanings.append(
                        GLIWordMeaning(id: uuid(), text: "", language: state.draft.targetLanguage)
                    )
                }
                return .none

            case .view(.cancelButtonTapped):
                guard !state.isSaving, !state.isDeleting else {
                    reportIssue("cancelButtonTapped while saving or deleting — the toolbar button is disabled in that state")
                    return .none
                }
                if case let .loaded(loaded) = state.meaningsLoadState {
                    state.draft = State.Draft(wordPair: state.wordPair, meanings: loaded)
                }
                state.isEditing = false
                return .none

            case let .view(.wordChanged(word)):
                guard state.isEditing else {
                    return .none
                }
                state.draft.word = word
                return .none

            case let .view(.meaningTextChanged(meaningID, text)):
                guard state.isEditing, state.draft.meanings[id: meaningID] != nil else {
                    reportIssue("meaningTextChanged for a row not in the current draft — the row's field shouldn't exist to send this")
                    return .none
                }
                state.draft.meanings[id: meaningID]?.text = text
                return .run { [languageDetector, clock] send in
                    try await clock.sleep(for: Self.detectionDebounce)
                    let detected = languageDetector.detectSourceLanguage(text)
                    await send(.languageDetectionResponse(meaningID: meaningID, code: detected))
                }
                .cancellable(id: CancelID.detectLanguage(meaningID), cancelInFlight: true)

            case let .languageDetectionResponse(meaningID, code):
                guard state.isEditing, state.draft.meanings[id: meaningID] != nil else {
                    return .none
                }
                state.draft.meanings[id: meaningID]?.language = code
                return .none

            case let .view(.meaningExampleChanged(meaningID, text)):
                guard state.isEditing, state.draft.meanings[id: meaningID] != nil else {
                    reportIssue("meaningExampleChanged for a row not in the current draft — the row's field shouldn't exist to send this")
                    return .none
                }
                state.draft.meanings[id: meaningID]?.example = text
                return .none

            case .view(.addMeaningTapped):
                guard state.isEditing, !state.isAtMeaningCap else {
                    return .none
                }
                state.draft.meanings.append(
                    GLIWordMeaning(id: uuid(), text: "", language: state.draft.targetLanguage)
                )
                return .none

            case let .view(.removeMeaningTapped(meaningID)):
                guard state.isEditing, state.draft.meanings[id: meaningID] != nil else {
                    reportIssue("removeMeaningTapped for a row not in the current draft — the swipe/onDelete reads the id fresh at invocation")
                    return .none
                }
                state.draft.meanings.remove(id: meaningID)
                return .cancel(id: CancelID.detectLanguage(meaningID))

            case let .view(.targetLanguageChanged(languageCode)):
                guard state.isEditing else {
                    return .none
                }
                state.draft.targetLanguage = languageCode
                return .none

            case .view(.saveButtonTapped):
                guard state.canSave else {
                    return .none
                }
                state.isSaving = true
                let update = GLIWordCardUpdate(
                    wordID: state.wordPair.id,
                    word: state.draft.word.trimmingCharacters(in: .whitespacesAndNewlines),
                    targetLanguage: state.draft.targetLanguage
                )
                let meanings = Self.persistableMeanings(state.draft.meanings)
                return .run { [cardMutations, wordMeanings] send in
                    do {
                        let wordPair = try await cardMutations.update(update)
                        try await wordMeanings.replaceAll(wordPair.id, meanings)
                        await send(.saveSucceeded(wordPair, meanings: meanings))
                    } catch {
                        reportIssue(error)
                        await send(.saveFailed)
                    }
                }

            case let .saveSucceeded(wordPair, meanings):
                let stored = IdentifiedArrayOf<GLIWordMeaning>(uniqueElements: meanings)
                state.wordPair = wordPair
                state.meaningsLoadState = .loaded(stored)
                state.draft = State.Draft(wordPair: wordPair, meanings: stored)
                state.isSaving = false
                state.isEditing = false
                return .send(.delegate(.updated(wordPair)))

            case .saveFailed:
                state.isSaving = false
                state.alert = AlertState {
                    TextState("Couldn’t save changes")
                } actions: {
                    ButtonState(action: .retrySave) {
                        TextState("Retry")
                    }
                    ButtonState(role: .cancel) {
                        TextState("Cancel")
                    }
                } message: {
                    TextState("Your edits are still here.")
                }
                return .none

            case .view(.deleteButtonTapped):
                guard !state.isSaving, !state.isDeleting else {
                    reportIssue("deleteButtonTapped while saving or deleting — the view hides/disables this control in that state")
                    return .none
                }
                state.alert = AlertState {
                    TextState("Delete this word?")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDelete) {
                        TextState("Delete")
                    }
                    ButtonState(role: .cancel) {
                        TextState("Cancel")
                    }
                } message: {
                    TextState("This action can’t be undone.")
                }
                return .none

            case .alert(.presented(.confirmDelete)),
                 .alert(.presented(.retryDelete)):
                return .send(.deleteConfirmed)

            case .alert(.presented(.retrySave)):
                return .send(.view(.saveButtonTapped))

            case .alert:
                return .none

            case .deleteConfirmed:
                guard !state.isSaving, !state.isDeleting else {
                    reportIssue("deleteConfirmed while saving or deleting — should be unreachable, the confirm alert only follows a guarded deleteButtonTapped")
                    return .none
                }
                state.isDeleting = true
                let wordID = state.wordPair.id
                return .run { [cardMutations] send in
                    try await cardMutations.delete(wordID)
                    await send(.deleteSucceeded)
                } catch: { error, send in
                    reportIssue(error)
                    await send(.deleteFailed)
                }

            case .deleteSucceeded:
                state.isDeleting = false
                return .send(.delegate(.deleted(state.wordPair.id)))

            case .deleteFailed:
                state.isDeleting = false
                state.alert = AlertState {
                    TextState("Couldn’t delete word")
                } actions: {
                    ButtonState(role: .destructive, action: .retryDelete) {
                        TextState("Retry")
                    }
                    ButtonState(role: .cancel) {
                        TextState("Cancel")
                    }
                } message: {
                    TextState("The word is still on this card.")
                }
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    /// Drops rows the user never touched (blank text and blank example) — an unedited
    /// Edit-seed row must not persist as an empty meaning.
    private static func persistableMeanings(_ meanings: IdentifiedArrayOf<GLIWordMeaning>) -> [GLIWordMeaning] {
        meanings.filter {
            !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !$0.example.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private static func loadCustomFoldersEffect(
        customFolders: GLICustomFoldersClient
    ) -> Effect<Action> {
        .run { send in
            do {
                let folders = try await customFolders.fetch()
                await send(.customFoldersLoaded(folders))
            } catch is CancellationError {
                return
            } catch {
                reportIssue(error)
            }
        }
        .cancellable(id: CancelID.loadCustomFolders, cancelInFlight: true)
    }
}
