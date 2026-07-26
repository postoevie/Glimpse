import ComposableArchitecture
import GlimpseCore
import IssueReporting

// Task: I1-T1 (origin), I1-T2, I1-T3 — docs/planning/l1-capture/I1-T2-language-folders/
@Reducer
public struct GLILanguageFoldersFeature {
    @ObservableState
    public struct State: Equatable {
        public var folders: IdentifiedArrayOf<GLILanguageFolder> = []
        @Presents public var addWord: GLIAddWordFeature.State?

        public init(
            folders: IdentifiedArrayOf<GLILanguageFolder> = [],
            addWord: GLIAddWordFeature.State? = nil
        ) {
            self.folders = folders
            self.addWord = addWord
        }
    }

    @CasePathable
    public enum Action {
        case onAppear
        case foldersLoaded(Result<[GLILanguageFolder], Error>)
        case addButtonTapped
        /// Bubbles to `GLIAppFeature`, which appends `.folderWords` onto the nav path.
        case folderTapped(GLILanguageFolder.ID)
        case addWord(PresentationAction<GLIAddWordFeature.Action>)
    }

    private enum CancelID { case observe }

    @Dependency(\.languageFolders) var languageFolders
    @Dependency(\.wordPairs) var wordPairs

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { [languageFolders, wordPairs] send in
                    await send(.foldersLoaded(Result {
                        try await languageFolders.fetchLanguageFolders()
                    }))
                    for await _ in wordPairs.changes() {
                        await send(.foldersLoaded(Result {
                            try await languageFolders.fetchLanguageFolders()
                        }))
                    }
                }
                .cancellable(id: CancelID.observe, cancelInFlight: true)

            case let .foldersLoaded(.success(folders)):
                state.folders = IdentifiedArray(uniqueElements: folders)
                return .none

            case let .foldersLoaded(.failure(error)):
                reportIssue(error)
                return .none

            case .addButtonTapped:
                state.addWord = GLIAddWordFeature.State(
                    wordPair: GLIWordPair(word: "", translation: "")
                )
                return .none

            case .folderTapped:
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
