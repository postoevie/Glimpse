import ComposableArchitecture
import GlimpseCore

// Task: I1-T1 (origin), I1-T2 — docs/planning/l1-capture/I1-T2-language-folders/
@Reducer
public struct GLIAddWordFeature {

    /// Debounce after word text settles before running detection; Done also sync-detects if source was not overridden.
    private static let detectionDebounce: Duration = .milliseconds(400)

    @ObservableState
    public struct State: Equatable {
        public var wordPair: GLIWordPair
        /// User picked source in the UI — skip auto-detection overwrite.
        public var didManuallySetSource: Bool
        /// User picked target in the UI — skip defaulting target from source.
        public var didManuallySetTarget: Bool

        public var canSave: Bool {
            !wordPair.word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        public init(
            wordPair: GLIWordPair,
            didManuallySetSource: Bool = false,
            didManuallySetTarget: Bool = false
        ) {
            self.wordPair = wordPair
            self.didManuallySetSource = didManuallySetSource
            self.didManuallySetTarget = didManuallySetTarget
        }
    }

    @CasePathable
    public enum Action {
        case wordChanged(String)
        case translationChanged(String)
        /// Manual source override (`nil` = clear / Unsorted path). Marks source as user-controlled.
        case sourceLanguageChanged(String?)
        /// Manual target override. Marks target as user-controlled.
        case targetLanguageChanged(String?)
        case cancelButtonTapped
        case doneButtonTapped
        case detectionResponse(String?)
        case delegate(Delegate)

        @CasePathable
        public enum Delegate {
            case wordAdded
        }
    }

    private enum CancelID { case detect }

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.languageDetector) var languageDetector
    @Dependency(\.continuousClock) var clock

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .wordChanged(word):
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

            case let .translationChanged(translation):
                state.wordPair.translation = translation
                return .none

            case let .sourceLanguageChanged(code):
                state.didManuallySetSource = true
                state.wordPair.sourceLanguage = code
                if !state.didManuallySetTarget, let code {
                    state.wordPair.targetLanguage = code
                }
                return .cancel(id: CancelID.detect)

            case let .targetLanguageChanged(code):
                state.didManuallySetTarget = true
                state.wordPair.targetLanguage = code
                return .none

            case .cancelButtonTapped:
                return .merge(
                    .cancel(id: CancelID.detect),
                    .run { [dismiss] _ in
                        await dismiss()
                    }
                )

            case .doneButtonTapped:
                let trimmedWord = state.wordPair.word
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedTranslation = state.wordPair.translation
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedWord.isEmpty else {
                    return .none
                }
                state.wordPair.word = trimmedWord
                state.wordPair.translation = trimmedTranslation
                // Never generate translation — only persist what the user typed.

                if !state.didManuallySetSource {
                    let detected = languageDetector.detectSourceLanguage(trimmedWord)
                    Self.applyDetectedSource(detected, to: &state)
                }

                return .merge(
                    .cancel(id: CancelID.detect),
                    .send(.delegate(.wordAdded))
                )

            case let .detectionResponse(code):
                guard !state.didManuallySetSource else {
                    return .none
                }
                Self.applyDetectedSource(code, to: &state)
                return .none

            case .delegate:
                return .none
            }
        }
    }

    private static func applyDetectedSource(_ code: String?, to state: inout State) {
        state.wordPair.sourceLanguage = code
        if !state.didManuallySetTarget, let code {
            state.wordPair.targetLanguage = code
        }
    }
}
