import ComposableArchitecture
import Foundation
import GlimpseCore
import GlimpseFeatures
import IssueReporting
import Testing

@Suite("GLIWordCardFeature")
@MainActor
struct GLIWordCardFeatureTests {
    private enum Failure: Error {
        case expected
    }

    private let wordID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    @Test("example load failure keeps example nil, records failure, and blocks edit")
    func exampleLoadFailedKeepsExampleNilAndBlocksEdit() async {
        var state = makeState(example: nil)
        state.draft = GLIWordCardFeature.State.Draft(
            wordPair: state.wordPair,
            example: "Real sidecar text"
        )
        let store = makeStore(initialState: state)

        await store.send(.exampleLoadFailed) {
            $0.didFailExampleLoad = true
        }

        #expect(store.state.example == nil)
        #expect(store.state.didFailExampleLoad == true)
        #expect(store.state.draft.example == "Real sidecar text")

        await store.send(.view(.editButtonTapped))
        #expect(store.state.isEditing == false)
    }

    @Test("example load success clears the failure flag")
    func exampleLoadedClearsFailureFlag() async {
        var state = makeState(example: nil)
        state.didFailExampleLoad = true
        let store = makeStore(initialState: state)

        await store.send(.exampleLoaded("Loaded example")) {
            $0.didFailExampleLoad = false
            $0.example = "Loaded example"
            $0.draft = GLIWordCardFeature.State.Draft(
                wordPair: $0.wordPair,
                example: "Loaded example"
            )
        }
    }

    @Test("onAppear clears failure flag before refetching")
    func onAppearClearsFailureFlagBeforeFetch() async {
        var state = makeState(example: "Stale")
        state.didFailExampleLoad = true
        let store = TestStore(initialState: state) {
            GLIWordCardFeature()
        } withDependencies: {
            $0.cardMutations = GLICardMutationsClient(
                update: {
                    GLIWordPair(
                        id: $0.wordID,
                        word: $0.word,
                        translation: $0.translation
                    )
                },
                delete: { _ in }
            )
            $0.wordExamples = GLIWordExamplesClient(fetchExample: { _ in "Fresh" })
        }

        await store.send(.view(.onAppear)) {
            $0.didFailExampleLoad = false
            $0.example = nil
        }
        await store.receive(.exampleLoaded("Fresh")) {
            $0.example = "Fresh"
            $0.draft = GLIWordCardFeature.State.Draft(
                wordPair: $0.wordPair,
                example: "Fresh"
            )
        }
    }

    @Test("state initializes its editable draft and validates a trimmed word")
    func draftInitializationAndValidation() {
        var state = makeState(example: "Example")

        #expect(state.draft.word == "hola")
        #expect(state.draft.translation == "hello")
        #expect(state.draft.example == "Example")
        #expect(state.draft.targetLanguage == "en")
        #expect(state.canSave == false)

        state.isEditing = true
        state.draft.word = " \n "
        #expect(state.canSave == false)

        state.draft.word = " bonjour "
        #expect(state.canSave == true)
    }

    @Test("cancel discards every draft change")
    func cancelRestoresPersistedValues() async {
        let store = makeStore(example: "Old example")

        await store.send(.view(.editButtonTapped)) {
            $0.isEditing = true
        }
        await store.send(.view(.wordChanged("bonjour"))) {
            $0.draft.word = "bonjour"
        }
        await store.send(.view(.translationChanged(""))) {
            $0.draft.translation = ""
        }
        await store.send(.view(.exampleChanged(""))) {
            $0.draft.example = ""
        }
        await store.send(.view(.targetLanguageChanged("fr"))) {
            $0.draft.targetLanguage = "fr"
        }
        await store.send(.view(.cancelButtonTapped)) {
            $0.draft = GLIWordCardFeature.State.Draft(
                wordPair: $0.wordPair,
                example: "Old example"
            )
            $0.isEditing = false
        }
    }

    @Test("save trims the word, preserves source identity, and publishes the updated card")
    func saveSuccess() async {
        let updates = LockIsolated<[GLIWordCardUpdate]>([])
        let updated = GLIWordPair(
            id: wordID,
            word: "bonjour",
            translation: "",
            sourceLanguage: "es",
            targetLanguage: "fr"
        )
        let store = makeStore(example: "Old example") { update in
            updates.withValue { $0.append(update) }
            return updated
        }

        await store.send(.view(.editButtonTapped)) {
            $0.isEditing = true
        }
        await store.send(.view(.wordChanged("  bonjour \n"))) {
            $0.draft.word = "  bonjour \n"
        }
        await store.send(.view(.translationChanged(""))) {
            $0.draft.translation = ""
        }
        await store.send(.view(.exampleChanged(""))) {
            $0.draft.example = ""
        }
        await store.send(.view(.targetLanguageChanged("fr"))) {
            $0.draft.targetLanguage = "fr"
        }
        await store.send(.view(.saveButtonTapped)) {
            $0.isSaving = true
        }
        await store.receive(.saveSucceeded(updated, example: "")) {
            $0.wordPair = updated
            $0.example = ""
            $0.draft = GLIWordCardFeature.State.Draft(wordPair: updated, example: "")
            $0.isSaving = false
            $0.isEditing = false
        }
        await store.receive(.delegate(.updated(updated)))

        #expect(
            updates.value == [
                GLIWordCardUpdate(
                    wordID: wordID,
                    word: "bonjour",
                    translation: "",
                    targetLanguage: "fr",
                    example: ""
                )
            ]
        )
        #expect(store.state.wordPair.sourceLanguage == "es")
    }

    @Test("blank-word save is ignored")
    func blankWordDoesNotSave() async {
        let updates = LockIsolated(0)
        var state = makeState(example: "")
        state.isEditing = true
        state.draft.word = " \n "
        let store = makeStore(initialState: state) { update in
            updates.withValue { $0 += 1 }
            return GLIWordPair(
                id: update.wordID,
                word: update.word,
                translation: update.translation
            )
        }

        await store.send(.view(.saveButtonTapped))
        await store.finish()

        #expect(updates.value == 0)
    }

    @Test("failed save keeps the draft and retry succeeds")
    func saveFailureAndRetry() async {
        let attempts = LockIsolated(0)
        let updated = GLIWordPair(
            id: wordID,
            word: "bonjour",
            translation: "hello",
            sourceLanguage: "es",
            targetLanguage: "en"
        )
        var state = makeState(example: "Example")
        state.isEditing = true
        state.draft.word = "bonjour"
        let store = makeStore(initialState: state) { _ in
            let attempt = attempts.withValue {
                $0 += 1
                return $0
            }
            guard attempt > 1 else {
                throw Failure.expected
            }
            return updated
        }

        await withExpectedIssue {
            await store.send(.view(.saveButtonTapped)) {
                $0.isSaving = true
            }
            await store.receive(.saveFailed) {
                $0.isSaving = false
                $0.alert = saveFailureAlert()
            }
        }
        #expect(store.state.draft.word == "bonjour")

        await store.send(.alert(.presented(.retrySave))) {
            $0.alert = nil
        }
        await store.receive(.view(.saveButtonTapped)) {
            $0.isSaving = true
        }
        await store.receive(.saveSucceeded(updated, example: "Example")) {
            $0.wordPair = updated
            $0.example = "Example"
            $0.draft = GLIWordCardFeature.State.Draft(wordPair: updated, example: "Example")
            $0.isSaving = false
            $0.isEditing = false
        }
        await store.receive(.delegate(.updated(updated)))

        #expect(attempts.value == 2)
    }

    @Test("delete requires confirmation and publishes success")
    func deleteConfirmationAndSuccess() async {
        let deletedIDs = LockIsolated<[UUID]>([])
        let store = makeStore(delete: { wordID in
            deletedIDs.withValue { $0.append(wordID) }
        })

        await store.send(.view(.deleteButtonTapped)) {
            $0.alert = deleteConfirmationAlert()
        }
        await store.send(.alert(.presented(.confirmDelete))) {
            $0.alert = nil
        }
        await store.receive(.deleteConfirmed) {
            $0.isDeleting = true
        }
        await store.receive(.deleteSucceeded) {
            $0.isDeleting = false
        }
        await store.receive(.delegate(.deleted(wordID)))

        #expect(deletedIDs.value == [wordID])
    }

    @Test("failed delete keeps the card and retry succeeds")
    func deleteFailureAndRetry() async {
        let attempts = LockIsolated(0)
        let store = makeStore(delete: { _ in
            let attempt = attempts.withValue {
                $0 += 1
                return $0
            }
            guard attempt > 1 else {
                throw Failure.expected
            }
        })

        await withExpectedIssue {
            await store.send(.deleteConfirmed) {
                $0.isDeleting = true
            }
            await store.receive(.deleteFailed) {
                $0.isDeleting = false
                $0.alert = deleteFailureAlert()
            }
        }
        #expect(store.state.wordPair.id == wordID)

        await store.send(.alert(.presented(.retryDelete))) {
            $0.alert = nil
        }
        await store.receive(.deleteConfirmed) {
            $0.isDeleting = true
        }
        await store.receive(.deleteSucceeded) {
            $0.isDeleting = false
        }
        await store.receive(.delegate(.deleted(wordID)))

        #expect(attempts.value == 2)
    }

    private func makeState(example: String? = nil) -> GLIWordCardFeature.State {
        GLIWordCardFeature.State(
            wordPair: GLIWordPair(
                id: wordID,
                word: "hola",
                translation: "hello",
                sourceLanguage: "es",
                targetLanguage: "en"
            ),
            example: example
        )
    }

    private func makeStore(
        example: String? = nil,
        update: @escaping @Sendable (GLIWordCardUpdate) async throws -> GLIWordPair = {
            GLIWordPair(
                id: $0.wordID,
                word: $0.word,
                translation: $0.translation,
                sourceLanguage: "es",
                targetLanguage: $0.targetLanguage
            )
        },
        delete: @escaping @Sendable (UUID) async throws -> Void = { _ in }
    ) -> TestStoreOf<GLIWordCardFeature> {
        makeStore(initialState: makeState(example: example), update: update, delete: delete)
    }

    private func makeStore(
        initialState: GLIWordCardFeature.State,
        update: @escaping @Sendable (GLIWordCardUpdate) async throws -> GLIWordPair = {
            GLIWordPair(
                id: $0.wordID,
                word: $0.word,
                translation: $0.translation,
                sourceLanguage: "es",
                targetLanguage: $0.targetLanguage
            )
        },
        delete: @escaping @Sendable (UUID) async throws -> Void = { _ in }
    ) -> TestStoreOf<GLIWordCardFeature> {
        TestStore(initialState: initialState) {
            GLIWordCardFeature()
        } withDependencies: {
            $0.cardMutations = GLICardMutationsClient(update: update, delete: delete)
            $0.wordExamples = GLIWordExamplesClient(fetchExample: { _ in "" })
        }
    }

    private func saveFailureAlert() -> AlertState<GLIWordCardFeature.Action.Alert> {
        AlertState {
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
    }

    private func deleteConfirmationAlert() -> AlertState<GLIWordCardFeature.Action.Alert> {
        AlertState {
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
    }

    private func deleteFailureAlert() -> AlertState<GLIWordCardFeature.Action.Alert> {
        AlertState {
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
    }
}
