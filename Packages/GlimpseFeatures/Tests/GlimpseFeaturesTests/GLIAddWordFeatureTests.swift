import ComposableArchitecture
import Foundation
import GlimpseCore
import GlimpseFeatures
import Testing

@Suite("GLIAddWordFeature")
@MainActor
struct GLIAddWordFeatureTests {
    private let pairID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    private func makeStore(
        word: String = "",
        translation: String = "",
        dismiss: @escaping @Sendable () -> Void = {}
    ) -> TestStoreOf<GLIAddWordFeature> {
        TestStore(
            initialState: GLIAddWordFeature.State(
                wordPair: GLIWordPair(id: pairID, word: word, translation: translation)
            )
        ) {
            GLIAddWordFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect { dismiss() }
        }
    }

    @Test("wordChanged updates word binding")
    func wordChangedUpdatesWord() async {
        let store = makeStore()

        await store.send(.wordChanged("hola")) {
            $0.wordPair.word = "hola"
        }
    }

    @Test("translationChanged updates translation binding")
    func translationChangedUpdatesTranslation() async {
        let store = makeStore(word: "hola")

        await store.send(.translationChanged("hello")) {
            $0.wordPair.translation = "hello"
        }
    }

    @Test("cancelButtonTapped dismisses without delegate")
    func cancelDismisses() async {
        let didDismiss = LockIsolated(false)
        let store = makeStore {
            didDismiss.setValue(true)
        }

        await store.send(.cancelButtonTapped)
        await store.finish()

        #expect(didDismiss.value == true)
    }

    @Test("doneButtonTapped sends wordAdded without dismissing")
    func doneSendsDelegateWithoutDismiss() async {
        let didDismiss = LockIsolated(false)
        let store = makeStore(word: "hola", translation: "hello") {
            didDismiss.setValue(true)
        }

        await store.send(.doneButtonTapped)
        await store.receive(\.delegate.wordAdded)
        await store.finish()

        #expect(didDismiss.value == false)
        #expect(store.state.wordPair.word == "hola")
        #expect(store.state.wordPair.translation == "hello")
    }

    @Test("doneButtonTapped with whitespace/empty word does nothing")
    func doneWithEmptyWordDoesNothing() async {
        let didDismiss = LockIsolated(false)
        let store = makeStore(word: "   ", translation: "") {
            didDismiss.setValue(true)
        }

        await store.send(.doneButtonTapped)
        await store.finish()

        #expect(didDismiss.value == false)
        #expect(store.state.wordPair.word == "   ")
    }
}
