import ComposableArchitecture
import Foundation
import GlimpseCore
import IssueReporting

// Task: I1-T3 (origin), I1-T4 — docs/planning/l1-capture/I1-T4-word-card/
@Reducer
public struct GLIFolderWordsFeature {
    @ObservableState
    public struct State: Equatable {
        public var id: UUID
        public var languageCode: String
        public var words: IdentifiedArrayOf<GLIWordPair>
        /// `false` until the first fetch result (success or failure); stays `true` across observation refreshes.
        public var hasCompletedInitialLoad = false
        @Presents public var addWord: GLIAddWordFeature.State?

        public init(
            id: UUID,
            languageCode: String,
            words: IdentifiedArrayOf<GLIWordPair> = [],
            hasCompletedInitialLoad: Bool = false,
            addWord: GLIAddWordFeature.State? = nil
        ) {
            self.id = id
            self.languageCode = languageCode
            self.words = words
            self.hasCompletedInitialLoad = hasCompletedInitialLoad
            self.addWord = addWord
        }
    }

    @CasePathable
    public enum Action {
        case onAppear
        case wordsLoaded(Result<[GLIWordPair], Error>)
        case addButtonTapped
        /// Bubbles to `GLIAppFeature`, which appends `.wordCard` onto the nav path.
        case wordTapped(GLIWordPair.ID)
        case addWord(PresentationAction<GLIAddWordFeature.Action>)
    }

    private enum CancelID { case observe }

    @Dependency(\.wordPairs) var wordPairs

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                let folderID = state.id
                return .run { [wordPairs] send in
                    await send(.wordsLoaded(Result {
                        try await wordPairs.fetchWordPairsInFolder(folderID)
                    }))
                    for await _ in wordPairs.changes() {
                        await send(.wordsLoaded(Result {
                            try await wordPairs.fetchWordPairsInFolder(folderID)
                        }))
                    }
                }
                .cancellable(id: CancelID.observe, cancelInFlight: true)

            case let .wordsLoaded(.success(words)):
                state.words = IdentifiedArray(uniqueElements: words)
                state.hasCompletedInitialLoad = true
                return .none

            case let .wordsLoaded(.failure(error)):
                state.hasCompletedInitialLoad = true
                reportIssue(error)
                return .none

            case .addButtonTapped:
                if state.languageCode == GLILanguageFolder.unsortedCode {
                    state.addWord = GLIAddWordFeature.State(
                        wordPair: GLIWordPair(word: "", translation: "")
                    )
                } else {
                    let code = state.languageCode
                    state.addWord = GLIAddWordFeature.State(
                        wordPair: GLIWordPair(
                            word: "",
                            translation: "",
                            sourceLanguage: code,
                            targetLanguage: code
                        ),
                        didManuallySetSource: true
                    )
                }
                return .none

            case let .wordTapped(id):
                guard state.words[id: id] != nil else {
                    reportIssue("wordTapped with id missing from words list: \(id)")
                    return .none
                }
                // Handled by `GLIAppFeature` (path push).
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
            }
        }
        .ifLet(\.$addWord, action: \.addWord) {
            GLIAddWordFeature()
        }
    }
}
