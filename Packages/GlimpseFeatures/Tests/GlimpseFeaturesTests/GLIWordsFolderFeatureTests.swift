import ComposableArchitecture
import Foundation
import GlimpseCore
import GlimpseFeatures
import IdentifiedCollections
import Testing

@Suite("GLIWordsFolderFeature")
@MainActor
struct GLIWordsFolderFeatureTests {
    private let pairID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let draftID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    private func makeStore(
        initialState: GLIWordsFolderFeature.State = .init(),
        wordPairs: GLIWordPairsClient
    ) -> TestStoreOf<GLIWordsFolderFeature> {
        TestStore(initialState: initialState) {
            GLIWordsFolderFeature()
        } withDependencies: {
            $0.wordPairs = wordPairs
        }
    }

    private func finishedChangesClient(
        fetchAll: @escaping @Sendable () async throws -> [GLIWordPair],
        save: @escaping @Sendable (GLIWordPair) async throws -> Void = { _ in }
    ) -> GLIWordPairsClient {
        GLIWordPairsClient(
            fetchAll: fetchAll,
            save: save,
            changes: { AsyncStream { $0.finish() } }
        )
    }

    @Test("addButtonTapped presents AddWord sheet with empty draft")
    func addButtonPresentsSheet() async throws {
        let store = makeStore(wordPairs: finishedChangesClient(fetchAll: { [] }))
        // Random UUID on GLIWordPair() — assert via state, not exact id match.
        store.exhaustivity = .off

        await store.send(.addButtonTapped)

        let draft = try #require(store.state.addWord)
        #expect(draft.wordPair.word == "")
        #expect(draft.wordPair.translation == "")
    }

    @Test("onAppear loads words via fetchAll into the list")
    func onAppearLoadsWords() async {
        let existing = GLIWordPair(id: pairID, word: "hola", translation: "hello")
        let store = makeStore(
            wordPairs: finishedChangesClient(fetchAll: { [existing] })
        )

        await store.send(.onAppear)
        // Case-path receive: Action carries Result<…, Error> (not Equatable).
        await store.receive(\.wordsLoaded) {
            $0.words = IdentifiedArray(uniqueElements: [existing])
        }
        await store.finish()
    }

    @Test("wordsLoaded success replaces the words list")
    func wordsLoadedUpdatesList() async {
        let pair = GLIWordPair(id: pairID, word: "gracias", translation: "thank you")
        let store = makeStore(wordPairs: finishedChangesClient(fetchAll: { [] }))

        await store.send(.wordsLoaded(.success([pair]))) {
            $0.words = IdentifiedArray(uniqueElements: [pair])
        }
    }

    @Test("delegate wordAdded persists via wordPairs.save then dismisses without local append")
    func wordAddedSavesWithoutLocalAppend() async {
        let saved = LockIsolated<[GLIWordPair]>([])
        let draft = GLIWordPair(id: draftID, word: "hola", translation: "hello")
        let store = makeStore(
            initialState: GLIWordsFolderFeature.State(
                addWord: GLIAddWordFeature.State(wordPair: draft)
            ),
            wordPairs: finishedChangesClient(
                fetchAll: { [] },
                save: { pair in saved.withValue { $0.append(pair) } }
            )
        )

        await store.send(.addWord(.presented(.delegate(.wordAdded))))
        await store.receive(\.addWord.dismiss) {
            $0.addWord = nil
        }
        await store.finish()

        #expect(saved.value == [draft])
        // Parent does not append locally — list stays empty until fetchAll / changes.
        #expect(store.state.words.isEmpty)
        #expect(store.state.addWord == nil)
    }

    @Test("after save, changes stream triggers wordsLoaded refresh")
    func changesStreamRefreshesListAfterSave() async {
        let draft = GLIWordPair(id: draftID, word: "hola", translation: "hello")
        let stored = LockIsolated<[GLIWordPair]>([])
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self)

        let store = makeStore(
            initialState: GLIWordsFolderFeature.State(
                addWord: GLIAddWordFeature.State(wordPair: draft)
            ),
            wordPairs: GLIWordPairsClient(
                fetchAll: { stored.value },
                save: { pair in
                    stored.withValue { $0.append(pair) }
                    continuation.yield(())
                },
                changes: { stream }
            )
        )
        // Long-lived observe loop — assert critical outcomes only.
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.receive(\.wordsLoaded)
        #expect(store.state.words.isEmpty)

        await store.send(.addWord(.presented(.doneButtonTapped)))
        await store.receive(\.addWord.presented.delegate.wordAdded)
        // save → dismiss sheet; changes yield → observe loop fetchAll → wordsLoaded
        await store.receive(\.wordsLoaded)
        #expect(stored.value == [draft])
        #expect(store.state.words == IdentifiedArray(uniqueElements: [draft]))

        continuation.finish()
        await store.finish()
        #expect(store.state.addWord == nil)
    }
}
