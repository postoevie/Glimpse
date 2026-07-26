import ComposableArchitecture
import Foundation
import GlimpseCore
import GlimpseFeatures
import IdentifiedCollections
import Testing

@Suite("GLIFolderWordsFeature")
@MainActor
struct GLIFolderWordsFeatureTests {
    private let folderID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let pairID = UUID(uuidString: "00000000-0000-0000-0000-000000000010")!
    private let draftID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    private func makeStore(
        languageCode: String = "es",
        initialState: GLIFolderWordsFeature.State? = nil,
        wordPairs: GLIWordPairsClient
    ) -> TestStoreOf<GLIFolderWordsFeature> {
        TestStore(
            initialState: initialState ?? GLIFolderWordsFeature.State(
                id: folderID,
                languageCode: languageCode
            )
        ) {
            GLIFolderWordsFeature()
        } withDependencies: {
            $0.wordPairs = wordPairs
            $0.languageDetector = GLILanguageDetectorClient(
                detectSourceLanguage: { _ in "es" }
            )
        }
    }

    private func finishedChangesWordPairs(
        fetchInFolder: @escaping @Sendable (UUID) async throws -> [GLIWordPair] = { _ in [] },
        save: @escaping @Sendable (GLIWordPair) async throws -> Void = { _ in }
    ) -> GLIWordPairsClient {
        GLIWordPairsClient(
            fetchWordPairs: { [] },
            fetchWordPairsInFolder: fetchInFolder,
            save: save,
            changes: { AsyncStream { $0.finish() } }
        )
    }

    @Test("onAppear loads words via fetchWordPairsInFolder into the list")
    func onAppearLoadsWords() async {
        let pair = GLIWordPair(id: pairID, word: "hola", translation: "hello", sourceLanguage: "es")
        let expectedFolderID = folderID
        let fetchedFolderID = LockIsolated<UUID?>(nil)
        let store = makeStore(
            wordPairs: finishedChangesWordPairs(fetchInFolder: { id in
                fetchedFolderID.setValue(id)
                return [pair]
            })
        )

        await store.send(.onAppear)
        await store.receive(\.wordsLoaded) {
            $0.words = IdentifiedArray(uniqueElements: [pair])
        }
        await store.finish()
        #expect(fetchedFolderID.value == expectedFolderID)
    }

    @Test("onAppear with empty folder leaves words empty")
    func onAppearEmptyLoad() async {
        let store = makeStore(wordPairs: finishedChangesWordPairs())

        await store.send(.onAppear)
        await store.receive(\.wordsLoaded)
        await store.finish()
        #expect(store.state.words.isEmpty)
    }

    @Test("after save, changes stream triggers wordsLoaded refresh")
    func changesStreamRefreshesWordsAfterSave() async {
        let draft = GLIWordPair(
            id: draftID,
            word: "hola",
            translation: "hello",
            sourceLanguage: "es",
            targetLanguage: "es"
        )
        let words = LockIsolated<[GLIWordPair]>([])
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self)

        let store = makeStore(
            initialState: GLIFolderWordsFeature.State(
                id: folderID,
                languageCode: "es",
                addWord: GLIAddWordFeature.State(
                    wordPair: draft,
                    didManuallySetSource: true
                )
            ),
            wordPairs: GLIWordPairsClient(
                fetchWordPairs: { [] },
                fetchWordPairsInFolder: { _ in words.value },
                save: { _ in
                    words.withValue { $0 = [draft] }
                    continuation.yield(())
                },
                changes: { stream }
            )
        )
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.receive(\.wordsLoaded)
        #expect(store.state.words.isEmpty)

        await store.send(.addWord(.presented(.doneButtonTapped)))
        await store.receive(\.addWord.presented.delegate.wordAdded)
        await store.receive(\.wordsLoaded)
        #expect(words.value == [draft])
        #expect(store.state.words == IdentifiedArray(uniqueElements: [draft]))

        continuation.finish()
        await store.finish()
        #expect(store.state.addWord == nil)
    }

    @Test("addButtonTapped from language folder opens addWord with prefilled source and didManuallySetSource")
    func addButtonFromLanguageFolderPrefills() async throws {
        let store = makeStore(languageCode: "es", wordPairs: finishedChangesWordPairs())
        store.exhaustivity = .off

        await store.send(.addButtonTapped)

        let draft = try #require(store.state.addWord)
        #expect(draft.wordPair.word == "")
        #expect(draft.wordPair.translation == "")
        #expect(draft.wordPair.sourceLanguage == "es")
        #expect(draft.wordPair.targetLanguage == "es")
        #expect(draft.didManuallySetSource == true)
    }

    @Test("addButtonTapped from Unsorted opens blank draft without forced source")
    func addButtonFromUnsortedBlankDraft() async throws {
        let store = makeStore(
            languageCode: GLILanguageFolder.unsortedCode,
            wordPairs: finishedChangesWordPairs()
        )
        store.exhaustivity = .off

        await store.send(.addButtonTapped)

        let draft = try #require(store.state.addWord)
        #expect(draft.wordPair.word == "")
        #expect(draft.wordPair.translation == "")
        #expect(draft.wordPair.sourceLanguage == nil)
        #expect(draft.wordPair.targetLanguage == nil)
        #expect(draft.didManuallySetSource == false)
    }

    @Test("delegate wordAdded persists via wordPairs.save then dismisses")
    func wordAddedSavesAndDismisses() async {
        let saved = LockIsolated<[GLIWordPair]>([])
        let draft = GLIWordPair(
            id: draftID,
            word: "hola",
            translation: "hello",
            sourceLanguage: "es",
            targetLanguage: "es"
        )
        let store = makeStore(
            initialState: GLIFolderWordsFeature.State(
                id: folderID,
                languageCode: "es",
                addWord: GLIAddWordFeature.State(
                    wordPair: draft,
                    didManuallySetSource: true
                )
            ),
            wordPairs: finishedChangesWordPairs(
                save: { pair in saved.withValue { $0.append(pair) } }
            )
        )

        await store.send(.addWord(.presented(.delegate(.wordAdded))))
        await store.receive(\.addWord.dismiss) {
            $0.addWord = nil
        }
        await store.finish()

        #expect(saved.value == [draft])
        #expect(store.state.addWord == nil)
    }
}
