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
        meaningText: String = "",
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
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage
                ),
                meaningText: meaningText,
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

    @Test("meaningTextChanged updates the meaning-text binding")
    func meaningTextChangedUpdatesMeaningText() async {
        let store = makeStore(word: "hola")

        await store.send(.meaningTextChanged("hello")) {
            $0.meaningText = "hello"
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
        let store = makeStore(word: "hola", meaningText: "hello") {
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
        #expect(store.state.meaningText == "hello")
    }

    @Test("doneButtonTapped trims the meaning text")
    func doneTrimsMeaningText() async {
        let store = makeStore(word: "hola", meaningText: "  hello  ")

        await store.send(.doneButtonTapped) {
            $0.wordPair.sourceLanguage = "es"
            $0.wordPair.targetLanguage = "es"
            $0.meaningText = "hello"
        }
        await store.receive(\.delegate.wordAdded)
    }

    @Test("doneButtonTapped with whitespace/empty word does nothing")
    func doneWithEmptyWordDoesNothing() async {
        let didDismiss = LockIsolated(false)
        let store = makeStore(word: "   ", meaningText: "") {
            didDismiss.setValue(true)
        }

        await store.send(.doneButtonTapped)
        await store.finish()

        #expect(didDismiss.value == false)
        #expect(store.state.wordPair.word == "   ")
    }
}
