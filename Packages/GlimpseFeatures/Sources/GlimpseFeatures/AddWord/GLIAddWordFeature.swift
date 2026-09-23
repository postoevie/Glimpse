import ComposableArchitecture
import Foundation
import GlimpseCore
import IssueReporting

// Task: I1-T1 (origin), I1-T2 — docs/planning/l1-capture/I1-T2-language-folders/
@Reducer
public struct GLIAddWordFeature {

    /// Debounce after word/meaning text settles before running detection; Done also sync-detects.
    private static let detectionDebounce: Duration = .milliseconds(400)

    /// How sticky-default custom-folder prefill decides whether to apply.
    public enum DefaultCustomFolderPrefillMode: Equatable {
        /// Root / Unsorted Add — prefill whenever a default exists (forces source from folder).
        case always
        /// Language-folder Add — prefill only when pending source matches the default folder’s source.
        case matchPendingSource
    }

    @ObservableState
    public struct State: Equatable {
        public var wordPair: GLIWordPair
        /// Capture's single meaning line — becomes meaning #1 on save (`GLIWordMeaning.captureMeaning`).
        public var meaningText: String
        /// User picked source in the UI — skip auto-detection overwrite.
        public var didManuallySetSource: Bool
        /// User picked target in the UI — skip detect-from-meaning and default-from-source.
        public var didManuallySetTarget: Bool
        /// Selected custom folder for this Add sheet (not stored on `GLIWordPair`).
        public var selectedCustomFolderID: UUID?
        /// All custom folders for the picker (unfiltered).
        public var customFolders: IdentifiedArrayOf<GLICustomFolder>
        /// User cleared custom folder this sheet session — do not auto-prefill again.
        public var didManuallyClearCustomFolder: Bool
        /// Sticky-default prefill policy for this sheet (set by parent entry point).
        public var defaultCustomFolderPrefillMode: DefaultCustomFolderPrefillMode
        /// Parent persist in flight — blocks Done/Cancel and disables save until failure clears or sheet dismisses.
        public var isSaving: Bool
        /// Live Example field. Spaces stay while typing; persist normalizes via codec.
        public var draftExampleText: String

        /// Persist-normalized example lines. Setter seeds `draftExampleText` via `encode`.
        public var example: [String] {
            get { GLIExampleListCodec.decode(draftExampleText) }
            set { draftExampleText = GLIExampleListCodec.encode(newValue) }
        }

        /// Source is forced by the selected custom folder and must not be edited/cleared.
        public var isSourceLocked: Bool {
            selectedCustomFolderID != nil
        }

        public var canSave: Bool {
            !isSaving
                && !wordPair.word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        /// Pair the parent persists. Meaning text is `captureMeaning`, not a field on the pair.
        public var pairForPersist: GLIWordPair {
            wordPair
        }

        /// Meaning #1 from the typed line + optional example. `nil` when both are blank.
        public var captureMeaning: GLIWordMeaning? {
            GLIWordMeaning.captureMeaning(
                text: meaningText,
                language: wordPair.targetLanguage,
                example: GLIExampleListCodec.encode(example)
            )
        }

        public init(
            wordPair: GLIWordPair,
            meaningText: String = "",
            didManuallySetSource: Bool = false,
            didManuallySetTarget: Bool = false,
            selectedCustomFolderID: UUID? = nil,
            customFolders: IdentifiedArrayOf<GLICustomFolder> = [],
            didManuallyClearCustomFolder: Bool = false,
            defaultCustomFolderPrefillMode: DefaultCustomFolderPrefillMode = .always,
            isSaving: Bool = false,
            draftExampleText: String = ""
        ) {
            self.wordPair = wordPair
            self.meaningText = meaningText
            self.didManuallySetSource = didManuallySetSource
            self.didManuallySetTarget = didManuallySetTarget
            self.selectedCustomFolderID = selectedCustomFolderID
            self.customFolders = customFolders
            self.didManuallyClearCustomFolder = didManuallyClearCustomFolder
            self.defaultCustomFolderPrefillMode = defaultCustomFolderPrefillMode
            self.isSaving = isSaving
            self.draftExampleText = draftExampleText
        }
    }

    @CasePathable
    public enum Action {
        case onAppear
        case wordChanged(String)
        case meaningTextChanged(String)
        /// Manual example edit. Live string; persist normalizes on Done.
        case exampleChanged(String)
        /// Manual source override (`nil` = clear / Unsorted path). Marks source as user-controlled.
        case sourceLanguageChanged(String?)
        /// Manual target override. Marks target as user-controlled.
        case targetLanguageChanged(String?)
        /// Manual custom-folder pick (`nil` clears). Updates sticky default immediately (set or clear).
        case customFolderPicked(UUID?)
        case customFolderCleared
        case customFoldersLoaded(Result<[GLICustomFolder], Error>)
        case cancelButtonTapped
        case doneButtonTapped
        case detectionResponse(String?)
        case targetDetectionResponse(String?)
        case delegate(Delegate)

        @CasePathable
        public enum Delegate {
            case wordAdded
        }
    }

    private enum CancelID {
        case detect
        case detectTarget
    }

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.languageDetector) var languageDetector
    @Dependency(\.targetLanguageDetector) var targetLanguageDetector
    @Dependency(\.continuousClock) var clock
    @Dependency(\.customFolders) var customFolders
    @Dependency(\.preferences) var preferences

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { [customFolders] send in
                    await send(.customFoldersLoaded(Result {
                        try await customFolders.fetch()
                    }))
                }

            case let .wordChanged(word):
                let word = GLICaptureFieldLimits.capped(word, to: GLICaptureFieldLimits.maxWordLength)
                state.wordPair.word = word
                guard !state.didManuallySetSource else {
                    return .none
                }
                return .run { [languageDetector, clock] send in
                    try await clock.sleep(for: Self.detectionDebounce)
                    let detected = languageDetector.detectSourceLanguage(word)
                    await send(.detectionResponse(detected))
                }
                .cancellable(id: CancelID.detect, cancelInFlight: true)

            case let .meaningTextChanged(meaningText):
                state.meaningText = GLICaptureFieldLimits.capped(
                    meaningText,
                    to: GLICaptureFieldLimits.maxMeaningLength
                )
                return detectTargetEffect(from: state.meaningText)

            case let .exampleChanged(example):
                state.draftExampleText = GLICaptureFieldLimits.capped(
                    example,
                    to: GLICaptureFieldLimits.maxExampleLength
                )
                return .none

            case let .sourceLanguageChanged(code):
                guard !state.isSourceLocked else {
                    return .none
                }
                state.didManuallySetSource = true
                state.wordPair.sourceLanguage = code
                Self.defaultTargetFromSourceIfNeeded(code, to: &state)
                Self.applyDefaultCustomFolderPrefill(to: &state, preferences: preferences)
                return .cancel(id: CancelID.detect)

            case let .targetLanguageChanged(code):
                state.didManuallySetTarget = true
                state.wordPair.targetLanguage = code
                return .none

            case let .customFolderPicked(id):
                guard let id else {
                    Self.clearCustomFolderSelection(state: &state)
                    preferences.clearDefaultCustomFolderID()
                    return Self.redetectSourceAfterUnlock(state: state)
                }
                guard let folder = state.customFolders[id: id] else {
                    reportIssue("customFolderPicked with id missing from customFolders: \(id)")
                    return .none
                }
                state.didManuallyClearCustomFolder = false
                Self.applyCustomFolder(folder, to: &state)
                preferences.setDefaultCustomFolderID(id)
                return .cancel(id: CancelID.detect)

            case .customFolderCleared:
                Self.clearCustomFolderSelection(state: &state)
                preferences.clearDefaultCustomFolderID()
                return Self.redetectSourceAfterUnlock(state: state)

            case let .customFoldersLoaded(.success(folders)):
                state.customFolders = IdentifiedArray(uniqueElements: folders)
                if let selectedID = state.selectedCustomFolderID {
                    if let folder = state.customFolders[id: selectedID] {
                        Self.applyCustomFolder(folder, to: &state)
                    } else {
                        reportIssue("selectedCustomFolderID missing from loaded customFolders: \(selectedID)")
                        state.selectedCustomFolderID = nil
                        Self.applyDefaultCustomFolderPrefill(to: &state, preferences: preferences)
                    }
                } else {
                    Self.applyDefaultCustomFolderPrefill(to: &state, preferences: preferences)
                }
                return .none

            case let .customFoldersLoaded(.failure(error)):
                reportIssue(error)
                return .none

            case .cancelButtonTapped:
                guard !state.isSaving else {
                    return .none
                }
                return .merge(
                    .cancel(id: CancelID.detect),
                    .cancel(id: CancelID.detectTarget),
                    .run { [dismiss] _ in
                        await dismiss()
                    }
                )

            case .doneButtonTapped:
                guard !state.isSaving else {
                    return .none
                }
                let trimmedWord = state.wordPair.word
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedMeaningText = state.meaningText
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedWord.isEmpty else {
                    return .none
                }
                state.wordPair.word = trimmedWord
                state.meaningText = trimmedMeaningText
                // Persist-normalize example lines (codec). Never generate.
                state.example = GLIExampleListCodec.decode(state.draftExampleText)

                if !state.didManuallySetSource {
                    let detected = languageDetector.detectSourceLanguage(trimmedWord)
                    Self.applyDetectedSource(detected, to: &state)
                    Self.applyDefaultCustomFolderPrefill(to: &state, preferences: preferences)
                }

                if !trimmedMeaningText.isEmpty {
                    let detectedTarget = targetLanguageDetector.detectTargetLanguage(trimmedMeaningText)
                    Self.applyDetectedTarget(detectedTarget, to: &state)
                }

                state.isSaving = true
                return .merge(
                    .cancel(id: CancelID.detect),
                    .cancel(id: CancelID.detectTarget),
                    .send(.delegate(.wordAdded))
                )

            case let .detectionResponse(code):
                guard !state.didManuallySetSource else {
                    return .none
                }
                Self.applyDetectedSource(code, to: &state)
                Self.applyDefaultCustomFolderPrefill(to: &state, preferences: preferences)
                return .none

            case let .targetDetectionResponse(code):
                Self.applyDetectedTarget(code, to: &state)
                return .none

            case .delegate:
                return .none
            }
        }
    }

    private static func applyDetectedSource(_ code: String?, to state: inout State) {
        state.wordPair.sourceLanguage = code
        defaultTargetFromSourceIfNeeded(code, to: &state)
    }

    /// Default target from source only when the user has not set target and meaning text is empty.
    /// Non-empty meaning text owns target via detection.
    private static func defaultTargetFromSourceIfNeeded(_ code: String?, to state: inout State) {
        guard !state.didManuallySetTarget else { return }
        guard let code else { return }
        guard !hasNonEmptyMeaningText(state.meaningText) else { return }
        state.wordPair.targetLanguage = code
    }

    private static func applyDetectedTarget(_ code: String?, to state: inout State) {
        guard !state.didManuallySetTarget else { return }
        guard let code else { return }
        state.wordPair.targetLanguage = code
    }

    private static func hasNonEmptyMeaningText(_ meaningText: String) -> Bool {
        !meaningText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func detectTargetEffect(from meaningText: String) -> Effect<Action> {
        let trimmed = meaningText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .cancel(id: CancelID.detectTarget)
        }
        return .run { [targetLanguageDetector, clock] send in
            try await clock.sleep(for: Self.detectionDebounce)
            let detected = targetLanguageDetector.detectTargetLanguage(trimmed)
            await send(.targetDetectionResponse(detected))
        }
        .cancellable(id: CancelID.detectTarget, cancelInFlight: true)
    }

    /// Prefill sticky-default custom folder per `defaultCustomFolderPrefillMode`.
    private static func applyDefaultCustomFolderPrefill(
        to state: inout State,
        preferences: GLIPreferencesClient
    ) {
        guard state.selectedCustomFolderID == nil else { return }
        guard !state.didManuallyClearCustomFolder else { return }
        guard let defaultID = preferences.defaultCustomFolderID() else { return }
        guard let folder = state.customFolders[id: defaultID] else { return }

        switch state.defaultCustomFolderPrefillMode {
        case .always:
            applyCustomFolder(folder, to: &state)
        case .matchPendingSource:
            guard let pendingSource = state.wordPair.sourceLanguage else { return }
            guard folder.sourceLanguage == pendingSource else { return }
            applyCustomFolder(folder, to: &state)
        }
    }

    private static func applyCustomFolder(_ folder: GLICustomFolder, to state: inout State) {
        state.selectedCustomFolderID = folder.id
        state.wordPair.sourceLanguage = folder.sourceLanguage
        state.didManuallySetSource = true
        if let target = folder.targetLanguage {
            state.wordPair.targetLanguage = target
        } else if !state.didManuallySetTarget {
            state.wordPair.targetLanguage = folder.sourceLanguage
        }
    }

    private static func clearCustomFolderSelection(state: inout State) {
        state.selectedCustomFolderID = nil
        state.didManuallyClearCustomFolder = true
        state.didManuallySetSource = false
    }

    /// After unlock, restore detect path when the word is non-empty.
    private static func redetectSourceAfterUnlock(state: State) -> Effect<Action> {
        let word = state.wordPair.word
        guard !word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .cancel(id: CancelID.detect)
        }
        return .run { send in
            @Dependency(\.languageDetector) var languageDetector
            @Dependency(\.continuousClock) var clock
            try await clock.sleep(for: Self.detectionDebounce)
            let detected = languageDetector.detectSourceLanguage(word)
            await send(.detectionResponse(detected))
        }
        .cancellable(id: CancelID.detect, cancelInFlight: true)
    }
}
