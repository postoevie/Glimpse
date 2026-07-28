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

    @Test("example load failure leaves example nil and sets failure flag")
    func exampleLoadFailedLeavesNilAndFlag() async {
        let store = TestStore(
            initialState: GLIWordCardFeature.State(
                wordPair: GLIWordPair(
                    id: wordID,
                    word: "hola",
                    translation: "hello",
                    sourceLanguage: "es",
                    targetLanguage: "en"
                ),
                example: "Stale"
            )
        ) {
            GLIWordCardFeature()
        } withDependencies: {
            $0.wordExamples = GLIWordExamplesClient(fetchExample: { _ in
                throw Failure.expected
            })
        }

        await store.send(.view(.onAppear)) {
            $0.didFailExampleLoad = false
            $0.example = nil
        }
        await store.receive(\.exampleLoadFailed) {
            $0.didFailExampleLoad = true
        }
        #expect(store.state.example == nil)
        #expect(store.state.didFailExampleLoad == true)
    }

    @Test("exampleLoaded sets example and clears failure flag")
    func exampleLoadedClearsFailureFlag() async {
        var state = GLIWordCardFeature.State(
            wordPair: GLIWordPair(
                id: wordID,
                word: "hola",
                translation: "hello",
                sourceLanguage: "es"
            )
        )
        state.didFailExampleLoad = true
        let store = TestStore(initialState: state) {
            GLIWordCardFeature()
        } withDependencies: {
            $0.wordExamples = GLIWordExamplesClient(fetchExample: { _ in "" })
        }

        await store.send(.exampleLoaded("Loaded example")) {
            $0.didFailExampleLoad = false
            $0.example = "Loaded example"
        }
    }
}
