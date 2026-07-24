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
        sourceLanguage: String? = nil,
        targetLanguage: String? = nil,
        didManuallySetSource: Bool = false,
        didManuallySetTarget: Bool = false,
        detectedLanguage: String? = "es",
        dismiss: @escaping @Sendable () -> Void = {}
    ) -> TestStoreOf<GLIAddWordFeature> {
        TestStore(
            initialState: GLIAddWordFeature.State(
                wordPair: GLIWordPair(
                    id: pairID,
                    word: word,
                    translation: translation,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage
                ),
                didManuallySetSource: didManuallySetSource,
                didManuallySetTarget: didManuallySetTarget
            )
        ) {
            GLIAddWordFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect { dismiss() }
            $0.continuousClock = ImmediateClock()
            $0.languageDetector = GLILanguageDetectorClient(
                detectSourceLanguage: { _ in detectedLanguage }
            )
        }
    }

    @Test("wordChanged updates word and applies debounced detection")
    func wordChangedUpdatesWordAndDetects() async {
        let store = makeStore()

        await store.send(.wordChanged("hola")) {
            $0.wordPair.word = "hola"
        }
        await store.receive(\.detectionResponse) {
            $0.wordPair.sourceLanguage = "es"
            $0.wordPair.targetLanguage = "es"
        }
    }

    @Test("translationChanged updates translation binding")
    func translationChangedUpdatesTranslation() async {
        let store = makeStore(word: "hola")

        await store.send(.translationChanged("hello")) {
            $0.wordPair.translation = "hello"
        }
    }

    @Test("sourceLanguageChanged marks manual and defaults target")
    func sourceLanguageChangedDefaultsTarget() async {
        let store = makeStore(word: "hola")

        await store.send(.sourceLanguageChanged("fr")) {
            $0.didManuallySetSource = true
            $0.wordPair.sourceLanguage = "fr"
            $0.wordPair.targetLanguage = "fr"
        }
    }

    @Test("targetLanguageChanged marks manual and is not overwritten by detection")
    func targetManualSurvivesDetection() async {
        let store = makeStore(word: "hola", targetLanguage: "en", didManuallySetTarget: true)

        await store.send(GLIAddWordFeature.Action.wordChanged("hola!")) {
            $0.wordPair.word = "hola!"
        }
        await store.receive(\.detectionResponse) {
            $0.wordPair.sourceLanguage = "es"
            // target stays "en"
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

    @Test("doneButtonTapped sends wordAdded with sync detection")
    func doneSendsDelegateWithoutDismiss() async {
        let didDismiss = LockIsolated(false)
        let store = makeStore(word: "hola", translation: "hello") {
            didDismiss.setValue(true)
        }

        await store.send(.doneButtonTapped) {
            $0.wordPair.sourceLanguage = "es"
            $0.wordPair.targetLanguage = "es"
        }
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
