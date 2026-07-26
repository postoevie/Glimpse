import ComposableArchitecture
import Foundation
import GlimpseCore
import IssueReporting

// Task: I1-T3 — docs/planning/l1-capture/I1-T3-folder-word-list/
@Reducer
public struct GLIFolderWordsFeature {
    @ObservableState
    public struct State: Equatable {
        public var id: UUID
        public var languageCode: String
        public var words: IdentifiedArrayOf<GLIWordPair>
        @Presents public var addWord: GLIAddWordFeature.State?

        public init(
            id: UUID,
            languageCode: String,
            words: IdentifiedArrayOf<GLIWordPair> = [],
            addWord: GLIAddWordFeature.State? = nil
        ) {
            self.id = id
            self.languageCode = languageCode
            self.words = words
            self.addWord = addWord
        }
    }

    @CasePathable
    public enum Action {
        case onAppear
        case wordsLoaded(Result<[GLIWordPair], Error>)
        case addButtonTapped
        /// Reserved for I1-T4 word card — no-op for now.
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
                return .none

            case let .wordsLoaded(.failure(error)):
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

            case .wordTapped:
                // I1-T4 — open word card.
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
