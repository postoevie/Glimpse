import SwiftUI
import ComposableArchitecture
import GlimpseCore
import IssueReporting

// Task: I1-T1 — docs/planning/l1-capture/I1-T1-add-word/
@Reducer
public struct GLIWordsFolderFeature {
    @ObservableState
    public struct State: Equatable {
        public var words: IdentifiedArrayOf<GLIWordPair> = []
        @Presents public var addWord: GLIAddWordFeature.State?

        public init(
            words: IdentifiedArrayOf<GLIWordPair> = [],
            addWord: GLIAddWordFeature.State? = nil
        ) {
            self.words = words
            self.addWord = addWord
        }
    }

    @CasePathable
    public enum Action {
        case onAppear
        case wordsLoaded(Result<[GLIWordPair], Error>)
        case addButtonTapped
        case addWord(PresentationAction<GLIAddWordFeature.Action>)
    }

    private enum CancelID { case observe }

    @Dependency(\.wordPairs) var wordPairs

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { [wordPairs] send in
                    await send(.wordsLoaded(Result { try await wordPairs.fetchAll() }))
                    for await _ in wordPairs.changes() {
                        await send(.wordsLoaded(Result { try await wordPairs.fetchAll() }))
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
                state.addWord = GLIAddWordFeature.State(
                    wordPair: GLIWordPair(word: "", translation: "")
                )
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

public struct GLIWordsFolderFeatureView: View {
    @Bindable public var store: StoreOf<GLIWordsFolderFeature>

    public init(store: StoreOf<GLIWordsFolderFeature>) {
        self.store = store
    }

    public var body: some View {
        Group {
            if store.words.isEmpty {
                ContentUnavailableView(
                    "No words yet",
                    systemImage: "text.book.closed",
                    description: Text("Tap + to add a word and translation.")
                )
            } else {
                List {
                    ForEach(store.words) { pair in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pair.word)
                                .font(.body)
                            Text(pair.translation)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Words")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    store.send(.addButtonTapped)
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .sheet(item: $store.scope(\.addWord, action: \.addWord)) { store in
            GLIAddWordFeatureView(store: store)
        }
        .task {
            await store.send(.onAppear).finish()
        }
    }
}

#Preview {
    NavigationStack {
        GLIWordsFolderFeatureView(
            store: Store(
                initialState: GLIWordsFolderFeature.State(
                    words: [
                        GLIWordPair(word: "hola", translation: "hello"),
                        GLIWordPair(word: "gracias", translation: "thank you"),
                    ]
                )
            ) {
                GLIWordsFolderFeature()
            }
        )
    }
}
