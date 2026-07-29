import ComposableArchitecture
import Foundation
import GlimpseCore
import GlimpseFeatures
import IdentifiedCollections
import Testing

@Suite("GLIAppFeature resume folder")
@MainActor
struct GLIAppFeatureResumeFolderTests {
    private let languageFolderID = UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!
    private let unsortedFolderID = UUID(uuidString: "00000000-0000-0000-0000-0000000000B2")!
    private let staleFolderID = UUID(uuidString: "00000000-0000-0000-0000-0000000000B3")!
    private let wordID = UUID(uuidString: "00000000-0000-0000-0000-0000000000B4")!

    @Test("waits for folders before restoring the pending destination")
    func waitsForFoldersBeforeRestoring() async {
        let languageFolder = makeLanguageFolder()
        let persistence = makePersistence(initialFolderID: languageFolderID)
        let store = makeStore(persistence: persistence)

        await store.send(.onAppear) {
            $0.pendingResumeFolderID = self.languageFolderID
            $0.hasLoadedPendingResume = true
        }
        #expect(store.state.path.isEmpty)
        #expect(store.state.didAttemptFolderRestore == false)

        await store.send(.languageFolders(.foldersLoaded(.success([languageFolder])))) {
            $0.languageFolders.folders = IdentifiedArray(uniqueElements: [languageFolder])
            $0.languageFolders.hasCompletedInitialLoad = true
            $0.hasCompletedInitialFolderLoad = true
            $0.didAttemptFolderRestore = true
            $0.pendingResumeFolderID = nil
            $0.path.append(
                .folderWords(
                    GLIFolderWordsFeature.State(
                        id: self.languageFolderID,
                        languageCode: "es"
                    )
                )
            )
        }
    }

    @Test("restores a language folder only once across later folder refreshes")
    func restoresLanguageFolderOnce() async {
        let languageFolder = makeLanguageFolder()
        let persistence = makePersistence(initialFolderID: languageFolderID)
        let store = makeStore(persistence: persistence)

        await store.send(.onAppear) {
            $0.pendingResumeFolderID = self.languageFolderID
            $0.hasLoadedPendingResume = true
        }
        await store.send(.languageFolders(.foldersLoaded(.success([languageFolder])))) {
            $0.languageFolders.folders = IdentifiedArray(uniqueElements: [languageFolder])
            $0.languageFolders.hasCompletedInitialLoad = true
            $0.hasCompletedInitialFolderLoad = true
            $0.didAttemptFolderRestore = true
            $0.pendingResumeFolderID = nil
            $0.path.append(
                .folderWords(
                    GLIFolderWordsFeature.State(
                        id: self.languageFolderID,
                        languageCode: "es"
                    )
                )
            )
        }

        await store.send(.languageFolders(.foldersLoaded(.success([languageFolder]))))
        #expect(store.state.path.count == 1)
        #expect(persistence.clearCount.value == 0)
    }

    @Test("restores Unsorted when that folder was last opened")
    func restoresUnsortedFolder() async {
        let unsorted = makeUnsortedFolder()
        let persistence = makePersistence(initialFolderID: unsortedFolderID)
        let store = makeStore(persistence: persistence)

        await store.send(.onAppear) {
            $0.pendingResumeFolderID = self.unsortedFolderID
            $0.hasLoadedPendingResume = true
        }
        await store.send(.languageFolders(.foldersLoaded(.success([unsorted])))) {
            $0.languageFolders.folders = IdentifiedArray(uniqueElements: [unsorted])
            $0.languageFolders.hasCompletedInitialLoad = true
            $0.hasCompletedInitialFolderLoad = true
            $0.didAttemptFolderRestore = true
            $0.pendingResumeFolderID = nil
            $0.path.append(
                .folderWords(
                    GLIFolderWordsFeature.State(
                        id: self.unsortedFolderID,
                        languageCode: GLILanguageFolder.unsortedCode
                    )
                )
            )
        }
    }

    @Test("stale pending ID falls back to root and clears persistence")
    func staleIDFallsBackAndClears() async {
        let languageFolder = makeLanguageFolder()
        let persistence = makePersistence(initialFolderID: staleFolderID)
        let store = makeStore(persistence: persistence)

        await store.send(.onAppear) {
            $0.pendingResumeFolderID = self.staleFolderID
            $0.hasLoadedPendingResume = true
        }
        await store.send(.languageFolders(.foldersLoaded(.success([languageFolder])))) {
            $0.languageFolders.folders = IdentifiedArray(uniqueElements: [languageFolder])
            $0.languageFolders.hasCompletedInitialLoad = true
            $0.hasCompletedInitialFolderLoad = true
            $0.didAttemptFolderRestore = true
            $0.pendingResumeFolderID = nil
        }

        #expect(store.state.path.isEmpty)
        #expect(persistence.stored.value == nil)
        #expect(persistence.clearCount.value == 1)
    }

    @Test("folder tap persists the opened folder ID")
    func folderTapPersists() async {
        let languageFolder = makeLanguageFolder()
        let persistence = makePersistence()
        let store = makeStore(
            persistence: persistence,
            initialState: GLIAppFeature.State(
                languageFolders: GLILanguageFoldersFeature.State(
                    folders: IdentifiedArray(uniqueElements: [languageFolder])
                ),
                hasLoadedPendingResume: true,
                hasCompletedInitialFolderLoad: true,
                didAttemptFolderRestore: true
            )
        )

        await store.send(.languageFolders(.folderTapped(languageFolderID))) {
            $0.path.append(
                .folderWords(
                    GLIFolderWordsFeature.State(
                        id: self.languageFolderID,
                        languageCode: "es"
                    )
                )
            )
        }

        #expect(persistence.stored.value == languageFolderID)
        #expect(persistence.savedIDs.value == [languageFolderID])
    }

    @Test("popping back to root clears persisted folder destination")
    func rootPopClears() async throws {
        let languageFolder = makeLanguageFolder()
        let persistence = makePersistence(initialFolderID: languageFolderID)
        var initialState = GLIAppFeature.State(
            languageFolders: GLILanguageFoldersFeature.State(
                folders: IdentifiedArray(uniqueElements: [languageFolder])
            ),
            hasLoadedPendingResume: true,
            hasCompletedInitialFolderLoad: true,
            didAttemptFolderRestore: true
        )
        initialState.path.append(
            .folderWords(
                GLIFolderWordsFeature.State(
                    id: languageFolderID,
                    languageCode: "es"
                )
            )
        )
        let store = makeStore(persistence: persistence, initialState: initialState)
        let folderPathID = try #require(store.state.path.ids.first)

        await store.send(.path(.popFrom(id: folderPathID))) {
            $0.path.removeAll()
        }

        #expect(persistence.stored.value == nil)
        #expect(persistence.clearCount.value == 1)
    }

    @Test("card presence keeps storing only the containing folder")
    func cardPresenceKeepsFolderPersistence() async throws {
        let languageFolder = makeLanguageFolder()
        let word = makeWord()
        let persistence = makePersistence(initialFolderID: languageFolderID)
        var initialState = GLIAppFeature.State(
            languageFolders: GLILanguageFoldersFeature.State(
                folders: IdentifiedArray(uniqueElements: [languageFolder])
            ),
            hasLoadedPendingResume: true,
            hasCompletedInitialFolderLoad: true,
            didAttemptFolderRestore: true
        )
        initialState.path.append(
            .folderWords(
                GLIFolderWordsFeature.State(
                    id: languageFolderID,
                    languageCode: "es",
                    words: IdentifiedArray(uniqueElements: [word])
                )
            )
        )
        let store = makeStore(persistence: persistence, initialState: initialState)
        let folderPathID = try #require(store.state.path.ids.first)

        await store.send(
            .path(
                .element(
                    id: folderPathID,
                    action: .folderWords(.wordTapped(wordID))
                )
            )
        ) {
            $0.path.append(
                .wordCard(GLIWordCardFeature.State(wordPair: word))
            )
        }

        #expect(persistence.stored.value == languageFolderID)
        #expect(persistence.clearCount.value == 0)
        #expect(persistence.savedIDs.value.isEmpty)
        #expect(store.state.path.count == 2)
    }

    @Test("capture sheet over a folder does not clear persisted folder")
    func sheetPresenceDoesNotClearFolder() async throws {
        let languageFolder = makeLanguageFolder()
        let persistence = makePersistence(initialFolderID: languageFolderID)
        var initialState = GLIAppFeature.State(
            languageFolders: GLILanguageFoldersFeature.State(
                folders: IdentifiedArray(uniqueElements: [languageFolder])
            ),
            hasLoadedPendingResume: true,
            hasCompletedInitialFolderLoad: true,
            didAttemptFolderRestore: true
        )
        initialState.path.append(
            .folderWords(
                GLIFolderWordsFeature.State(
                    id: languageFolderID,
                    languageCode: "es"
                )
            )
        )
        let store = makeStore(persistence: persistence, initialState: initialState)
        store.exhaustivity = .off
        let folderPathID = try #require(store.state.path.ids.first)

        // Non-exhaustive: draft WordPair IDs are generated at presentation time.
        await store.send(
            .path(
                .element(
                    id: folderPathID,
                    action: .folderWords(.addButtonTapped)
                )
            )
        )

        #expect(store.state.path[id: folderPathID, case: \.folderWords]?.addWord != nil)
        #expect(persistence.stored.value == languageFolderID)
        #expect(persistence.clearCount.value == 0)
        #expect(store.state.path.count == 1)
    }

    // MARK: - Helpers

    private struct Persistence {
        let stored: LockIsolated<UUID?>
        let savedIDs: LockIsolated<[UUID]>
        let clearCount: LockIsolated<Int>

        var client: GLILastOpenedFolderClient {
            GLILastOpenedFolderClient(
                load: { stored.value },
                saveFolder: { id in
                    stored.setValue(id)
                    savedIDs.withValue { $0.append(id) }
                },
                clearToRoot: {
                    stored.setValue(nil)
                    clearCount.withValue { $0 += 1 }
                }
            )
        }
    }

    private func makePersistence(initialFolderID: UUID? = nil) -> Persistence {
        Persistence(
            stored: LockIsolated(initialFolderID),
            savedIDs: LockIsolated([]),
            clearCount: LockIsolated(0)
        )
    }

    private func makeStore(
        persistence: Persistence,
        initialState: GLIAppFeature.State = GLIAppFeature.State()
    ) -> TestStoreOf<GLIAppFeature> {
        TestStore(initialState: initialState) {
            GLIAppFeature()
        } withDependencies: {
            $0.lastOpenedFolder = persistence.client
            $0.languageFolders = GLILanguageFoldersClient(fetchLanguageFolders: { [] })
            $0.wordPairs = GLIWordPairsClient(
                fetchWordPairs: { [] },
                save: { _ in }
            )
            $0.wordExamples = GLIWordExamplesClient(fetchExample: { _ in "" })
            $0.cardMutations = GLICardMutationsClient(
                update: { update in
                    GLIWordPair(
                        id: update.wordID,
                        word: update.word,
                        translation: update.translation
                    )
                },
                delete: { _ in }
            )
            $0.languageDetector = GLILanguageDetectorClient(detectSourceLanguage: { _ in nil })
        }
    }

    private func makeLanguageFolder() -> GLILanguageFolder {
        GLILanguageFolder(id: languageFolderID, languageCode: "es")
    }

    private func makeUnsortedFolder() -> GLILanguageFolder {
        GLILanguageFolder(
            id: unsortedFolderID,
            languageCode: GLILanguageFolder.unsortedCode
        )
    }

    private func makeWord() -> GLIWordPair {
        GLIWordPair(
            id: wordID,
            word: "hola",
            translation: "hello",
            sourceLanguage: "es",
            targetLanguage: "en"
        )
    }
}
