import ComposableArchitecture
import Foundation
import GlimpseCore
import GlimpseFeatures
import IdentifiedCollections
import Testing

@Suite("GLIAddWordFeature")
@MainActor
struct GLIAddWordFeatureTests {
    private let pairID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let folderID = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!
    private let otherFolderID = UUID(uuidString: "00000000-0000-0000-0000-0000000000A2")!

    private var spanishFolder: GLICustomFolder {
        GLICustomFolder(
            id: folderID,
            name: "Travel",
            sourceLanguage: "es",
            targetLanguage: "en"
        )
    }

    private var frenchFolder: GLICustomFolder {
        GLICustomFolder(
            id: otherFolderID,
            name: "Paris",
            sourceLanguage: "fr"
        )
    }

    private func makeStore(
        word: String = "",
        meaningText: String = "",
        sourceLanguage: String? = nil,
        targetLanguage: String? = nil,
        didManuallySetSource: Bool = false,
        didManuallySetTarget: Bool = false,
        selectedCustomFolderID: UUID? = nil,
        customFolders: [GLICustomFolder] = [],
        didManuallyClearCustomFolder: Bool = false,
        defaultCustomFolderPrefillMode: GLIAddWordFeature.DefaultCustomFolderPrefillMode = .always,
        isSaving: Bool = false,
        draftExampleText: String = "",
        detectedLanguage: String? = "es",
        detectedTarget: String? = "en",
        preferences: GLIPreferencesClient = .inMemory(),
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
                didManuallySetTarget: didManuallySetTarget,
                selectedCustomFolderID: selectedCustomFolderID,
                customFolders: IdentifiedArray(uniqueElements: customFolders),
                didManuallyClearCustomFolder: didManuallyClearCustomFolder,
                defaultCustomFolderPrefillMode: defaultCustomFolderPrefillMode,
                isSaving: isSaving,
                draftExampleText: draftExampleText
            )
        ) {
            GLIAddWordFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect { dismiss() }
            $0.continuousClock = ImmediateClock()
            $0.languageDetector = GLILanguageDetectorClient(
                detectSourceLanguage: { _ in detectedLanguage }
            )
            $0.targetLanguageDetector = GLITargetLanguageDetectorClient(
                detectTargetLanguage: { _ in detectedTarget }
            )
            $0.preferences = preferences
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

    @Test("meaningTextChanged updates the meaning-text binding and applies target detection")
    func meaningTextChangedUpdatesMeaningText() async {
        let store = makeStore(word: "hola")

        await store.send(.meaningTextChanged("hello")) {
            $0.meaningText = "hello"
        }
        await store.receive(\.targetDetectionResponse) {
            $0.wordPair.targetLanguage = "en"
        }
    }

    @Test("empty meaningTextChanged cancels target detection and does not overwrite target")
    func emptyMeaningCancelsTargetDetection() async {
        let store = makeStore(word: "hola", targetLanguage: "fr")

        await store.send(.meaningTextChanged("hello")) {
            $0.meaningText = "hello"
        }
        await store.receive(\.targetDetectionResponse) {
            $0.wordPair.targetLanguage = "en"
        }
        await store.send(.meaningTextChanged("")) {
            $0.meaningText = ""
        }
        await store.finish()

        #expect(store.state.wordPair.targetLanguage == "en")
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

    @Test("source detection does not copy onto target when meaning is non-empty")
    func meaningOwnsTargetOnSourceDetection() async {
        let store = makeStore(meaningText: "hello", targetLanguage: "fr")

        await store.send(.wordChanged("hola")) {
            $0.wordPair.word = "hola"
        }
        await store.receive(\.detectionResponse) {
            $0.wordPair.sourceLanguage = "es"
        }
        #expect(store.state.wordPair.targetLanguage == "fr")
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
            $0.wordPair.targetLanguage = "en"
            $0.isSaving = true
        }
        await store.receive(\.delegate.wordAdded)
        await store.finish()

        #expect(didDismiss.value == false)
        #expect(store.state.wordPair.word == "hola")
        #expect(store.state.meaningText == "hello")
        #expect(store.state.isSaving == true)
    }

    @Test("doneButtonTapped trims the meaning text")
    func doneTrimsMeaningText() async {
        let store = makeStore(word: "hola", meaningText: "  hello  ")

        await store.send(.doneButtonTapped) {
            $0.wordPair.sourceLanguage = "es"
            $0.wordPair.targetLanguage = "en"
            $0.meaningText = "hello"
            $0.isSaving = true
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

    @Test("doneButtonTapped keeps existing target when meaning owns it and detector returns nil")
    func doneDoesNotCopySourceOntoTargetWhenMeaningPresent() async {
        let store = makeStore(
            word: "hola",
            meaningText: "hello",
            targetLanguage: "fr",
            detectedTarget: nil
        )

        await store.send(.doneButtonTapped) {
            $0.wordPair.sourceLanguage = "es"
            $0.isSaving = true
        }
        await store.receive(\.delegate.wordAdded)
        #expect(store.state.wordPair.targetLanguage == "fr")
    }

    @Test("wordChanged truncates past the word cap")
    func wordChangedCapsAtLimit() async {
        let pasted = String(repeating: "b", count: 800)
        let store = makeStore(didManuallySetSource: true)

        await store.send(.wordChanged(pasted)) {
            $0.wordPair.word = String(repeating: "b", count: GLICaptureFieldLimits.maxWordLength)
        }
        #expect(store.state.wordPair.word.count == GLICaptureFieldLimits.maxWordLength)
    }

    @Test("meaningTextChanged truncates past the meaning cap")
    func meaningTextChangedCapsAtLimit() async {
        let pasted = String(repeating: "d", count: 800)
        let store = makeStore(didManuallySetSource: true)

        await store.send(.meaningTextChanged(pasted)) {
            $0.meaningText = String(repeating: "d", count: GLICaptureFieldLimits.maxMeaningLength)
        }
        await store.receive(\.targetDetectionResponse) {
            $0.wordPair.targetLanguage = "en"
        }
        #expect(store.state.meaningText.count == GLICaptureFieldLimits.maxMeaningLength)
    }

    @Test("exampleChanged truncates past the example cap")
    func exampleChangedCapsAtLimit() async {
        let pasted = String(repeating: "e", count: 800)
        let store = makeStore(didManuallySetSource: true)

        await store.send(.exampleChanged(pasted)) {
            $0.draftExampleText = String(repeating: "e", count: GLICaptureFieldLimits.maxExampleLength)
        }
        #expect(store.state.draftExampleText.count == GLICaptureFieldLimits.maxExampleLength)
    }

    @Test("doneButtonTapped normalizes typed example lines via the codec")
    func doneNormalizesExampleViaCodec() async {
        let store = makeStore(
            word: "hola",
            meaningText: "hello",
            didManuallySetSource: true,
            draftExampleText: "  line one  \n\n  line two  "
        )

        await store.send(.doneButtonTapped) {
            $0.wordPair.targetLanguage = "en"
            $0.draftExampleText = "line one\nline two"
            $0.isSaving = true
        }
        await store.receive(\.delegate.wordAdded)

        let meaning = try #require(store.state.captureMeaning)
        #expect(meaning.text == "hello")
        #expect(meaning.example == "line one\nline two")
    }

    @Test("customFolderPicked locks source, sets preference, and sourceLanguageChanged is a no-op")
    func customFolderPickLocksSource() async {
        let preferences = GLIPreferencesClient.inMemory()
        let store = makeStore(
            customFolders: [spanishFolder],
            preferences: preferences
        )

        await store.send(.customFolderPicked(folderID)) {
            $0.selectedCustomFolderID = folderID
            $0.wordPair.sourceLanguage = "es"
            $0.wordPair.targetLanguage = "en"
            $0.didManuallySetSource = true
            $0.didManuallyClearCustomFolder = false
        }
        #expect(store.state.isSourceLocked == true)
        #expect(preferences.defaultCustomFolderID() == folderID)

        await store.send(.sourceLanguageChanged("fr"))
        #expect(store.state.wordPair.sourceLanguage == "es")
        #expect(store.state.isSourceLocked == true)
    }

    @Test("customFolderCleared unlocks source and redetects after debounce")
    func customFolderClearRedetects() async {
        let preferences = GLIPreferencesClient.inMemory(
            initialDefaultCustomFolderID: folderID
        )
        let store = makeStore(
            word: "hola",
            sourceLanguage: "es",
            targetLanguage: "en",
            didManuallySetSource: true,
            selectedCustomFolderID: folderID,
            customFolders: [spanishFolder],
            preferences: preferences
        )

        await store.send(.customFolderCleared) {
            $0.selectedCustomFolderID = nil
            $0.didManuallyClearCustomFolder = true
            $0.didManuallySetSource = false
        }
        await store.receive(\.detectionResponse) {
            $0.wordPair.sourceLanguage = "es"
            $0.wordPair.targetLanguage = "es"
        }
        #expect(store.state.isSourceLocked == false)
        #expect(preferences.defaultCustomFolderID() == nil)
    }

    @Test("always prefill applies even when pending source differs")
    func alwaysPrefillOverwritesMismatchedPendingSource() async {
        let store = makeStore(
            sourceLanguage: "fr",
            defaultCustomFolderPrefillMode: .always,
            preferences: .inMemory(initialDefaultCustomFolderID: folderID)
        )

        await store.send(.customFoldersLoaded(.success([spanishFolder]))) {
            $0.customFolders = IdentifiedArray(uniqueElements: [spanishFolder])
            $0.selectedCustomFolderID = folderID
            $0.wordPair.sourceLanguage = "es"
            $0.wordPair.targetLanguage = "en"
            $0.didManuallySetSource = true
        }
    }

    @Test("matchPendingSource prefills only when pending source matches folder source")
    func matchPendingSourcePrefillMatchAndMismatch() async {
        let matching = makeStore(
            sourceLanguage: "es",
            defaultCustomFolderPrefillMode: .matchPendingSource,
            preferences: .inMemory(initialDefaultCustomFolderID: folderID)
        )

        await matching.send(.customFoldersLoaded(.success([spanishFolder]))) {
            $0.customFolders = IdentifiedArray(uniqueElements: [spanishFolder])
            $0.selectedCustomFolderID = folderID
            $0.wordPair.sourceLanguage = "es"
            $0.wordPair.targetLanguage = "en"
            $0.didManuallySetSource = true
        }

        let mismatched = makeStore(
            sourceLanguage: "es",
            defaultCustomFolderPrefillMode: .matchPendingSource,
            preferences: .inMemory(initialDefaultCustomFolderID: otherFolderID)
        )

        await mismatched.send(.customFoldersLoaded(.success([frenchFolder]))) {
            $0.customFolders = IdentifiedArray(uniqueElements: [frenchFolder])
        }
        #expect(mismatched.state.selectedCustomFolderID == nil)
    }

    @Test("doneButtonTapped while isSaving is ignored")
    func doneIgnoredWhileSaving() async {
        let store = makeStore(
            word: "hola",
            didManuallySetSource: true,
            isSaving: true
        )

        await store.send(.doneButtonTapped)
        await store.finish()
        #expect(store.state.isSaving == true)
    }

    @Test("cancelButtonTapped while isSaving is ignored")
    func cancelIgnoredWhileSaving() async {
        let didDismiss = LockIsolated(false)
        let store = makeStore(
            word: "hola",
            didManuallySetSource: true,
            isSaving: true
        ) {
            didDismiss.setValue(true)
        }

        await store.send(.cancelButtonTapped)
        await store.finish()

        #expect(didDismiss.value == false)
        #expect(store.state.isSaving == true)
    }
}
