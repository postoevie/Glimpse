import ComposableArchitecture
import Foundation
import GlimpseCore
import IssueReporting

// Task: I1-T4 (origin), I1-T5 — docs/planning/l1-capture/I1-T5-card-edit-delete/
@Reducer
public struct GLIWordCardFeature {
    @ObservableState
    public struct State: Equatable {
        public struct Draft: Equatable {
            public var word: String
            public var translation: String
            public var example: String
            public var targetLanguage: String?

            public init(wordPair: GLIWordPair, example: String) {
                word = wordPair.word
                translation = wordPair.translation
                self.example = example
                targetLanguage = wordPair.targetLanguage
            }
        }

        public var wordPair: GLIWordPair
        public var example: String?
        public var didFailExampleLoad = false
        public var draft: Draft
        public var isEditing = false
        public var isSaving = false
        public var isDeleting = false
        @Presents public var alert: AlertState<Action.Alert>?

        public var canSave: Bool {
            isEditing
                && !isSaving
                && !isDeleting
                && !draft.word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        public init(
            wordPair: GLIWordPair,
            example: String? = nil,
            didFailExampleLoad: Bool = false
        ) {
            self.wordPair = wordPair
            self.example = example
            self.didFailExampleLoad = didFailExampleLoad
            draft = Draft(wordPair: wordPair, example: example ?? "")
        }
    }

    @CasePathable
    public enum Action: ViewAction, Equatable {
        public enum View: Equatable {
            case onAppear
            case editButtonTapped
            case cancelButtonTapped
            case wordChanged(String)
            case translationChanged(String)
            case exampleChanged(String)
            case targetLanguageChanged(String?)
            case saveButtonTapped
            case deleteButtonTapped
        }

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
        case exampleLoaded(String)
        case exampleLoadFailed
        case saveSucceeded(GLIWordPair, example: String)
        case saveFailed
        case deleteConfirmed
        case deleteSucceeded
        case deleteFailed
    }

    private enum CancelID {
        case loadExample
    }

    @Dependency(\.wordExamples) private var wordExamples
    @Dependency(\.cardMutations) private var cardMutations

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                guard !state.isEditing else {
                    return .none
                }
                state.didFailExampleLoad = false
                state.example = nil
                let wordID = state.wordPair.id
                return .run { [wordExamples] send in
                    do {
                        let example = try await wordExamples.fetchExample(wordID)
                        await send(.exampleLoaded(example))
                    } catch is CancellationError {
                        return
                    } catch {
                        reportIssue(error)
                        await send(.exampleLoadFailed)
                    }
                }
                .cancellable(id: CancelID.loadExample, cancelInFlight: true)

            case let .exampleLoaded(example):
                state.didFailExampleLoad = false
                state.example = example
                if !state.isEditing {
                    state.draft = State.Draft(
                        wordPair: state.wordPair,
                        example: example
                    )
                }
                return .none

            case .exampleLoadFailed:
                state.didFailExampleLoad = true
                return .none

            case .view(.editButtonTapped):
                guard state.example != nil, !state.isDeleting else {
                    return .none
                }
                state.draft = State.Draft(
                    wordPair: state.wordPair,
                    example: state.example ?? ""
                )
                state.isEditing = true
                return .none

            case .view(.cancelButtonTapped):
                guard !state.isSaving, !state.isDeleting else {
                    return .none
                }
                state.draft = State.Draft(
                    wordPair: state.wordPair,
                    example: state.example ?? ""
                )
                state.isEditing = false
                return .none

            case let .view(.wordChanged(word)):
                guard state.isEditing, !state.isSaving, !state.isDeleting else {
                    return .none
                }
                state.draft.word = word
                return .none

            case let .view(.translationChanged(translation)):
                guard state.isEditing, !state.isSaving, !state.isDeleting else {
                    return .none
                }
                state.draft.translation = translation
                return .none

            case let .view(.exampleChanged(example)):
                guard state.isEditing, !state.isSaving, !state.isDeleting else {
                    return .none
                }
                state.draft.example = example
                return .none

            case let .view(.targetLanguageChanged(languageCode)):
                guard state.isEditing, !state.isSaving, !state.isDeleting else {
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
                    translation: state.draft.translation,
                    targetLanguage: state.draft.targetLanguage,
                    example: state.draft.example
                )
                return .run { [cardMutations] send in
                    let wordPair = try await cardMutations.update(update)
                    await send(.saveSucceeded(wordPair, example: update.example))
                } catch: { error, send in
                    reportIssue(error)
                    await send(.saveFailed)
                }

            case let .saveSucceeded(wordPair, example):
                state.wordPair = wordPair
                state.example = example
                state.draft = State.Draft(wordPair: wordPair, example: example)
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
}
