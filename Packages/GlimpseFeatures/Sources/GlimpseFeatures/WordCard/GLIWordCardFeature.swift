import ComposableArchitecture
import Foundation
import GlimpseCore
import IssueReporting

// Task: I1-T4 (origin), I1-T5, I1-B3, I2-T3 / I2-T4 — docs/planning/l1-capture/, l2-organize/
//
// Meanings: hand-typed text + optional detected language + optional example, `nil` while
// loading, capped at `maxMeaningsPerWord`. No generation (see `GLIGenerationServiceType`).
// Field caps: word 300, meaning 300, example 500 (`GLICaptureFieldLimits`) on each change.
// Persist trims meaning text and normalizes the example with `GLIExampleListCodec`.
// Detection: one pending row. A later row settles the previous row's language only.
// Save settles the pending row (that row may also set the card target) before persist.
// `didManuallySetTarget` blocks detection from overwriting the card target.
// Membership: Source + Custom folder controls work while viewing or editing (blocked only
// while saving/deleting), via `wordPairMembership.updateSource` / `.updateCustomFolder`.
// onAppear scans source-matching custom folders so `customFolderID` matches storage.
// Save re-files `customFolderID` with `assignCustomFolder` after the card update.
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
        /// Skip detect-from-meaning overwrite of card target after a Target pick this Edit session.
        public var didManuallySetTarget = false
        /// Row whose 400 ms detection has not delivered yet. Save settles only this id.
        public var pendingLanguageDetectionID: GLIWordMeaning.ID?
        /// Every custom folder, unfiltered — the only stored copy. `eligibleCustomFolders`
        /// below is a filtered view of this, not a separate fetch.
        public var allCustomFolders: IdentifiedArrayOf<GLICustomFolder> = []
        @Presents public var alert: AlertState<Action.Alert>?
        /// Incremented on successful save. The view does not observe this yet.
        public var lightHapticTick = 0

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
        /// Folder id from the onAppear membership scan, or `nil` when the word is in none.
        case membershipLoaded(UUID?)
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
        case detectLanguage
    }

    @Dependency(\.wordMeanings) private var wordMeanings
    @Dependency(\.cardMutations) private var cardMutations
    @Dependency(\.customFolders) private var customFolders
    @Dependency(\.wordPairs) private var wordPairs
    @Dependency(\.wordPairMembership) private var wordPairMembership
    @Dependency(\.targetLanguageDetector) private var targetLanguageDetector
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
                let wordPair = state.wordPair
                let wordID = wordPair.id
                let sourceLanguage = wordPair.sourceLanguage

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

                if sourceLanguage == nil {
                    state.wordPair.customFolderID = nil
                }

                return .merge(
                    loadMeanings,
                    Self.loadCustomFoldersEffect(
                        wordID: wordID,
                        sourceLanguage: sourceLanguage,
                        customFolders: customFolders,
                        wordPairs: wordPairs
                    )
                )

            case let .meaningsLoaded(meanings):
                let loaded = IdentifiedArrayOf<GLIWordMeaning>(uniqueElements: meanings)
                state.meaningsLoadState = .loaded(loaded)
                if !state.isEditing {
                    Self.resetDraft(&state, meanings: loaded)
                }
                return .none

            case .meaningsLoadFailed:
                state.meaningsLoadState = .failed
                return .none

            case let .customFoldersLoaded(folders):
                state.allCustomFolders = IdentifiedArray(uniqueElements: folders)
                return .none

            case let .membershipLoaded(folderID):
                state.wordPair.customFolderID = folderID
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
                Self.resetDraft(&state, meanings: loaded)
                state.isEditing = true
                if state.draft.meanings.isEmpty {
                    state.draft.meanings.append(
                        GLIWordMeaning(id: uuid(), text: "", language: state.draft.targetLanguage)
                    )
                }
                return .cancel(id: CancelID.detectLanguage)

            case .view(.cancelButtonTapped):
                guard !state.isSaving, !state.isDeleting else {
                    reportIssue("cancelButtonTapped while saving or deleting — the toolbar button is disabled in that state")
                    return .none
                }
                if case let .loaded(loaded) = state.meaningsLoadState {
                    Self.resetDraft(&state, meanings: loaded)
                } else {
                    state.didManuallySetTarget = false
                    state.pendingLanguageDetectionID = nil
                }
                state.isEditing = false
                return .cancel(id: CancelID.detectLanguage)

            case let .view(.wordChanged(word)):
                guard state.isEditing else {
                    return .none
                }
                state.draft.word = GLICaptureFieldLimits.capped(
                    word,
                    to: GLICaptureFieldLimits.maxWordLength
                )
                return .none

            case let .view(.meaningTextChanged(meaningID, text)):
                guard state.isEditing, state.draft.meanings[id: meaningID] != nil else {
                    reportIssue("meaningTextChanged for a row not in the current draft — the row's field shouldn't exist to send this")
                    return .none
                }
                let capped = GLICaptureFieldLimits.capped(
                    text,
                    to: GLICaptureFieldLimits.maxMeaningLength
                )
                state.draft.meanings[id: meaningID]?.text = capped
                return detectLanguageEffect(for: meaningID, text: capped, state: &state)

            case let .languageDetectionResponse(meaningID, code):
                guard state.isEditing,
                      !state.isSaving,
                      state.pendingLanguageDetectionID == meaningID
                else {
                    return .none
                }
                state.pendingLanguageDetectionID = nil
                Self.applyDetectedLanguage(
                    code,
                    to: meaningID,
                    in: &state,
                    updatesCardTarget: true
                )
                return .none

            case let .view(.meaningExampleChanged(meaningID, text)):
                guard state.isEditing, state.draft.meanings[id: meaningID] != nil else {
                    reportIssue("meaningExampleChanged for a row not in the current draft — the row's field shouldn't exist to send this")
                    return .none
                }
                state.draft.meanings[id: meaningID]?.example = GLICaptureFieldLimits.capped(
                    text,
                    to: GLICaptureFieldLimits.maxExampleLength
                )
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
                let wasPendingDetection = state.pendingLanguageDetectionID == meaningID
                state.draft.meanings.remove(id: meaningID)
                if wasPendingDetection {
                    state.pendingLanguageDetectionID = nil
                }
                return wasPendingDetection ? .cancel(id: CancelID.detectLanguage) : .none

            case let .view(.targetLanguageChanged(languageCode)):
                guard state.isEditing else {
                    return .none
                }
                state.didManuallySetTarget = true
                state.draft.targetLanguage = languageCode
                return .none

            case .view(.saveButtonTapped):
                guard state.canSave else {
                    return .none
                }
                // Debounce may not have fired; settle only the row still pending.
                settlePendingLanguageDetection(to: &state)
                state.isSaving = true
                let update = GLIWordCardUpdate(
                    wordID: state.wordPair.id,
                    word: state.draft.word.trimmingCharacters(in: .whitespacesAndNewlines),
                    targetLanguage: state.draft.targetLanguage
                )
                let meanings = Self.persistableMeanings(state.draft.meanings)
                let customFolderID = state.wordPair.customFolderID
                return .merge(
                    .cancel(id: CancelID.detectLanguage),
                    .run { [cardMutations, wordMeanings, wordPairMembership] send in
                        let wordPair = try await cardMutations.update(update)
                        try await wordMeanings.replaceAll(wordPair.id, meanings)
                        if let customFolderID {
                            try await wordPairMembership.assignCustomFolder(
                                wordPair.id,
                                customFolderID,
                                wordPair.targetLanguage
                            )
                        }
                        await send(.saveSucceeded(wordPair, meanings: meanings))
                    } catch: { error, send in
                        reportIssue(error)
                        await send(.saveFailed)
                    }
                )

            case let .saveSucceeded(wordPair, meanings):
                let stored = IdentifiedArrayOf<GLIWordMeaning>(uniqueElements: meanings)
                state.wordPair = wordPair
                state.meaningsLoadState = .loaded(stored)
                Self.resetDraft(&state, meanings: stored)
                state.isSaving = false
                state.isEditing = false
                state.lightHapticTick += 1
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
                state.pendingLanguageDetectionID = nil
                let wordID = state.wordPair.id
                return .merge(
                    .cancel(id: CancelID.detectLanguage),
                    .run { [cardMutations] send in
                        try await cardMutations.delete(wordID)
                        await send(.deleteSucceeded)
                    } catch: { error, send in
                        reportIssue(error)
                        await send(.deleteFailed)
                    }
                )

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

    /// Draft back to the loaded rows. A saved target does not count as manual for the next Edit.
    private static func resetDraft(
        _ state: inout State,
        meanings: IdentifiedArrayOf<GLIWordMeaning>
    ) {
        state.draft = State.Draft(wordPair: state.wordPair, meanings: meanings)
        state.didManuallySetTarget = false
        state.pendingLanguageDetectionID = nil
    }

    /// Detected code writes the row's language. `nil` clears that row and does not touch the
    /// card target. A non-nil code sets the card target only for the latest typed meaning
    /// and only when the user has not picked Target this Edit session.
    private static func applyDetectedLanguage(
        _ code: String?,
        to meaningID: GLIWordMeaning.ID,
        in state: inout State,
        updatesCardTarget: Bool
    ) {
        guard state.draft.meanings[id: meaningID] != nil else { return }
        state.draft.meanings[id: meaningID]?.language = code
        guard updatesCardTarget, let code, !state.didManuallySetTarget else { return }
        state.draft.targetLanguage = code
    }

    private func detectLanguageEffect(
        for meaningID: GLIWordMeaning.ID,
        text: String,
        state: inout State
    ) -> Effect<Action> {
        if let pendingID = state.pendingLanguageDetectionID, pendingID != meaningID {
            settleRowLanguage(pendingID, in: &state, updatesCardTarget: false)
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state.pendingLanguageDetectionID = nil
            return .cancel(id: CancelID.detectLanguage)
        }
        state.pendingLanguageDetectionID = meaningID
        return .run { [targetLanguageDetector, clock] send in
            try await clock.sleep(for: Self.detectionDebounce)
            let detected = targetLanguageDetector.detectTargetLanguage(trimmed)
            await send(.languageDetectionResponse(meaningID: meaningID, code: detected))
        }
        .cancellable(id: CancelID.detectLanguage, cancelInFlight: true)
    }

    /// Runs detection for the in-flight row only, so Done inside the debounce still lands.
    private func settlePendingLanguageDetection(to state: inout State) {
        guard let pendingID = state.pendingLanguageDetectionID else { return }
        state.pendingLanguageDetectionID = nil
        settleRowLanguage(pendingID, in: &state, updatesCardTarget: true)
    }

    /// Sync detect for one row. `updatesCardTarget` is true for the latest typed meaning
    /// (debounce response / Save); false when leaving a previous pending row.
    private func settleRowLanguage(
        _ meaningID: GLIWordMeaning.ID,
        in state: inout State,
        updatesCardTarget: Bool
    ) {
        guard let meaning = state.draft.meanings[id: meaningID] else { return }
        let trimmed = meaning.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let code = targetLanguageDetector.detectTargetLanguage(trimmed)
        Self.applyDetectedLanguage(
            code,
            to: meaningID,
            in: &state,
            updatesCardTarget: updatesCardTarget
        )
    }

    /// Rows as stored: text trimmed, example normalized, rows with neither dropped.
    private static func persistableMeanings(
        _ meanings: IdentifiedArrayOf<GLIWordMeaning>
    ) -> [GLIWordMeaning] {
        meanings.compactMap { meaning in
            var normalized = meaning
            normalized.text = meaning.text.trimmingCharacters(in: .whitespacesAndNewlines)
            normalized.example = GLIExampleListCodec.encode(
                GLIExampleListCodec.decode(meaning.example)
            )
            guard !normalized.text.isEmpty || !normalized.example.isEmpty else {
                return nil
            }
            return normalized
        }
    }

    /// Loads every custom folder, then, when source is known, scans for this word's membership.
    /// Membership responses already carry a current `customFolderID`, so they don't call this again.
    private static func loadCustomFoldersEffect(
        wordID: GLIWordPair.ID,
        sourceLanguage: String?,
        customFolders: GLICustomFoldersClient,
        wordPairs: GLIWordPairsClient
    ) -> Effect<Action> {
        .run { send in
            let folders: [GLICustomFolder]
            do {
                folders = try await customFolders.fetch()
            } catch is CancellationError {
                return
            } catch {
                reportIssue(error)
                return
            }
            await send(.customFoldersLoaded(folders))

            guard let sourceLanguage else { return }

            do {
                var membership: UUID?
                for folder in folders where folder.sourceLanguage == sourceLanguage {
                    let words = try await wordPairs.fetchWordPairsInCustomFolder(folder.id)
                    if words.contains(where: { $0.id == wordID }) {
                        membership = folder.id
                        break
                    }
                }
                await send(.membershipLoaded(membership))
            } catch is CancellationError {
                return
            } catch {
                reportIssue(error)
            }
        }
        .cancellable(id: CancelID.loadCustomFolders, cancelInFlight: true)
    }
}
