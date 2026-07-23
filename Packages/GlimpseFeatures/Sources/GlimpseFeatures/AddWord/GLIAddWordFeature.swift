import SwiftUI
import ComposableArchitecture
import GlimpseCore

// Task: I1-T1 — docs/planning/l1-capture/I1-T1-add-word/
@Reducer
public struct GLIAddWordFeature {

    @ObservableState
    public struct State: Equatable {
        public var wordPair: GLIWordPair

        public init(wordPair: GLIWordPair) {
            self.wordPair = wordPair
        }
    }

    @CasePathable
    public enum Action {
        case wordChanged(String)
        case translationChanged(String)
        case cancelButtonTapped
        case doneButtonTapped
        case delegate(Delegate)

        @CasePathable
        public enum Delegate {
            case wordAdded
        }
    }

    @Dependency(\.dismiss) var dismiss

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .wordChanged(word):
                state.wordPair.word = word
                return .none

            case let .translationChanged(translation):
                state.wordPair.translation = translation
                return .none

            case .cancelButtonTapped:
                return .run { [dismiss] _ in
                    await dismiss()
                }

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
                return .send(.delegate(.wordAdded))

            case .delegate:
                return .none
            }
        }
    }
}

public struct GLIAddWordFeatureView: View {

    @Bindable public var store: StoreOf<GLIAddWordFeature>

    public init(store: StoreOf<GLIAddWordFeature>) {
        self.store = store
    }

    private var canSave: Bool {
        !store.wordPair.word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var body: some View {
        NavigationStack {
            Form {
                TextField(
                    "Word",
                    text: $store.wordPair.word.sending(\.wordChanged)
                )
                TextField(
                    "Translation",
                    text: $store.wordPair.translation.sending(\.translationChanged)
                )
            }
            .navigationTitle("Add Word")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        store.send(.cancelButtonTapped)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        store.send(.doneButtonTapped)
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}
