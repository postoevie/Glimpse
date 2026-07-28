import ComposableArchitecture
import Foundation
import GlimpseCore
import GlimpseFeatures
import IdentifiedCollections
import Testing

@Suite("GLILanguageFoldersFeature")
@MainActor
struct GLILanguageFoldersFeatureTests {
    private let folderID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let draftID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    private func makeStore(
        initialState: GLILanguageFoldersFeature.State = .init(),
        languageFolders: GLILanguageFoldersClient,
        wordPairs: GLIWordPairsClient
    ) -> TestStoreOf<GLILanguageFoldersFeature> {
        TestStore(initialState: initialState) {
            GLILanguageFoldersFeature()
        } withDependencies: {
            $0.languageFolders = languageFolders
            $0.wordPairs = wordPairs
            // AddWord child calls languageDetector on Done when source isn't manual.
            $0.languageDetector = GLILanguageDetectorClient(
                detectSourceLanguage: { _ in "es" }
            )
        }
    }

    private func finishedChangesWordPairs(
        save: @escaping @Sendable (GLIWordPair) async throws -> Void = { _ in }
    ) -> GLIWordPairsClient {
        GLIWordPairsClient(
            fetchWordPairs: { [] },
            save: save,
            changes: { AsyncStream { $0.finish() } }
        )
    }

    private func foldersClient(
        fetch: @escaping @Sendable () async throws -> [GLILanguageFolder]
    ) -> GLILanguageFoldersClient {
        GLILanguageFoldersClient(fetchLanguageFolders: fetch)
    }

    @Test("addButtonTapped presents AddWord sheet with empty draft")
    func addButtonPresentsSheet() async throws {
        let store = makeStore(
            languageFolders: foldersClient(fetch: { [] }),
            wordPairs: finishedChangesWordPairs()
        )
        // Random UUID on GLIWordPair() — assert via state, not exact id match.
        store.exhaustivity = .off

        await store.send(.addButtonTapped)

        let draft = try #require(store.state.addWord)
        #expect(draft.wordPair.word == "")
        #expect(draft.wordPair.translation == "")
        #expect(draft.wordPair.sourceLanguage == nil)
        #expect(draft.wordPair.targetLanguage == nil)
    }

    @Test("onAppear loads folders via fetchLanguageFolders into the list")
    func onAppearLoadsFolders() async {
        let existing = GLILanguageFolder(id: folderID, languageCode: "es")
        let store = makeStore(
            languageFolders: foldersClient(fetch: { [existing] }),
            wordPairs: finishedChangesWordPairs()
        )

        await store.send(.onAppear)
        await store.receive(\.foldersLoaded) {
            $0.folders = IdentifiedArray(uniqueElements: [existing])
            $0.hasCompletedInitialLoad = true
        }
        await store.finish()
    }

    @Test("foldersLoaded success replaces the folders list")
    func foldersLoadedUpdatesList() async {
        let folder = GLILanguageFolder(id: folderID, languageCode: "unsorted")
        let store = makeStore(
            languageFolders: foldersClient(fetch: { [] }),
            wordPairs: finishedChangesWordPairs()
        )

        await store.send(.foldersLoaded(.success([folder]))) {
            $0.folders = IdentifiedArray(uniqueElements: [folder])
            $0.hasCompletedInitialLoad = true
        }
    }

    @Test("folderTapped is a no-op until I1-T3")
    func folderTappedNoOp() async {
        let folder = GLILanguageFolder(id: folderID, languageCode: "es")
        let store = makeStore(
            initialState: GLILanguageFoldersFeature.State(
                folders: IdentifiedArray(uniqueElements: [folder])
            ),
            languageFolders: foldersClient(fetch: { [folder] }),
            wordPairs: finishedChangesWordPairs()
        )

        await store.send(.folderTapped(folderID))
        #expect(store.state.folders == IdentifiedArray(uniqueElements: [folder]))
        #expect(store.state.addWord == nil)
    }

    @Test("delegate wordAdded persists via wordPairs.save then dismisses without local append")
    func wordAddedSavesWithoutLocalAppend() async {
        let saved = LockIsolated<[GLIWordPair]>([])
        let draft = GLIWordPair(id: draftID, word: "hola", translation: "hello")
        let store = makeStore(
            initialState: GLILanguageFoldersFeature.State(
                addWord: GLIAddWordFeature.State(wordPair: draft)
            ),
            languageFolders: foldersClient(fetch: { [] }),
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
        // Parent does not append locally — list stays empty until fetchLanguageFolders / changes.
        #expect(store.state.folders.isEmpty)
        #expect(store.state.addWord == nil)
    }

    @Test("after save, changes stream triggers foldersLoaded refresh")
    func changesStreamRefreshesFoldersAfterSave() async {
        let draft = GLIWordPair(id: draftID, word: "hola", translation: "hello", sourceLanguage: "es")
        let folders = LockIsolated<[GLILanguageFolder]>([])
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self)
        let esFolder = GLILanguageFolder(id: folderID, languageCode: "es")

        let store = makeStore(
            initialState: GLILanguageFoldersFeature.State(
                addWord: GLIAddWordFeature.State(wordPair: draft)
            ),
            languageFolders: foldersClient(fetch: { folders.value }),
            wordPairs: GLIWordPairsClient(
                fetchWordPairs: { [] },
                save: { _ in
                    folders.withValue { $0 = [esFolder] }
                    continuation.yield(())
                },
                changes: { stream }
            )
        )
        // Long-lived observe loop — assert critical outcomes only.
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.receive(\.foldersLoaded)
        #expect(store.state.folders.isEmpty)

        await store.send(.addWord(.presented(.doneButtonTapped)))
        await store.receive(\.addWord.presented.delegate.wordAdded)
        // save → dismiss sheet; changes yield → observe loop fetchLanguageFolders → foldersLoaded
        await store.receive(\.foldersLoaded)
        #expect(folders.value == [esFolder])
        #expect(store.state.folders == IdentifiedArray(uniqueElements: [esFolder]))

        continuation.finish()
        await store.finish()
        #expect(store.state.addWord == nil)
    }
}
