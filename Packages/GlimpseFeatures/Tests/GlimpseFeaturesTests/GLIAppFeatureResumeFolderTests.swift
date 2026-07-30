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
    private let customFolderID = UUID(uuidString: "00000000-0000-0000-0000-0000000000B5")!

    @Test("validates persisted language folder via SwiftData and pushes when it exists")
    func restoresExistingLanguageFolder() async throws {
        let persistence = makePersistence(initial: .language(languageFolderID))
        let folderID = languageFolderID
        let folder = makeLanguageFolder()
        let store = makeStore(
            persistence: persistence,
            fetchLanguageFolder: { id in
                guard id == folderID else { return nil }
                return folder
            }
        )
        store.exhaustivity = .off

        await store.send(.onAppear) {
            $0.hasLoadedPendingResume = true
            $0.didAttemptFolderRestore = true
        }
        await store.receive(\.resumeFolderValidated)
        let languagePathID = try #require(store.state.path.ids.first)
        #expect(store.state.path.count == 1)
        #expect(store.state.path[id: languagePathID, case: \.folderWords]?.identity == .language(folderID))

        #expect(persistence.clearCount.value == 0)
        #expect(persistence.stored.value == .language(languageFolderID))
    }

    @Test("restores a language folder only once across later folder refreshes")
    func restoresLanguageFolderOnce() async throws {
        let languageFolder = makeLanguageFolder()
        let persistence = makePersistence(initial: .language(languageFolderID))
        let folderID = languageFolderID
        let store = makeStore(
            persistence: persistence,
            fetchLanguageFolder: { id in
                guard id == folderID else { return nil }
                return languageFolder
            }
        )
        store.exhaustivity = .off

        await store.send(.onAppear) {
            $0.hasLoadedPendingResume = true
            $0.didAttemptFolderRestore = true
        }
        await store.receive(\.resumeFolderValidated)
        let restoredPathID = try #require(store.state.path.ids.first)
        #expect(store.state.path.count == 1)
        #expect(store.state.path[id: restoredPathID, case: \.folderWords]?.identity == .language(folderID))

        await store.send(.languageFolders(.foldersLoaded(.success([languageFolder])))) {
            $0.languageFolders.folders = IdentifiedArray(uniqueElements: [languageFolder])
            $0.languageFolders.hasCompletedLanguageFoldersLoad = true
        }
        #expect(store.state.path.count == 1)
        #expect(persistence.clearCount.value == 0)
    }

    @Test("restores Unsorted when that folder was last opened")
    func restoresUnsortedFolder() async throws {
        let persistence = makePersistence(initial: .language(unsortedFolderID))
        let folderID = unsortedFolderID
        let folder = makeUnsortedFolder()
        let store = makeStore(
            persistence: persistence,
            fetchLanguageFolder: { id in
                guard id == folderID else { return nil }
                return folder
            }
        )
        store.exhaustivity = .off

        await store.send(.onAppear) {
            $0.hasLoadedPendingResume = true
            $0.didAttemptFolderRestore = true
        }
        await store.receive(\.resumeFolderValidated)
        let unsortedPathID = try #require(store.state.path.ids.first)
        #expect(store.state.path.count == 1)
        #expect(store.state.path[id: unsortedPathID, case: \.folderWords]?.identity == .language(folderID))
    }

    @Test("stale language id clears persistence and stays at root")
    func staleLanguageIDClearsAndStaysAtRoot() async {
        let persistence = makePersistence(initial: .language(staleFolderID))
        let store = makeStore(
            persistence: persistence,
            fetchLanguageFolder: { _ in nil }
        )

        await store.send(.onAppear) {
            $0.hasLoadedPendingResume = true
            $0.didAttemptFolderRestore = true
        }
        await store.receive(\.resumeFolderValidated)

        #expect(store.state.path.isEmpty)
        #expect(persistence.stored.value == nil)
        #expect(persistence.clearCount.value == 1)
    }

    @Test("folder tap persists a language destination")
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
                    GLIFolderWordsFeature.State(identity: .language(self.languageFolderID))
                )
            )
        }

        #expect(persistence.stored.value == .language(languageFolderID))
        #expect(persistence.saved.value == [.language(languageFolderID)])
    }

    @Test("custom folder tap persists a custom destination")
    func customFolderTapPersists() async {
        let customFolder = makeCustomFolder()
        let persistence = makePersistence()
        let store = makeStore(
            persistence: persistence,
            initialState: GLIAppFeature.State(
                languageFolders: GLILanguageFoldersFeature.State(
                    customFolders: IdentifiedArray(uniqueElements: [customFolder])
                ),
                hasLoadedPendingResume: true,
                hasCompletedInitialFolderLoad: true,
                didAttemptFolderRestore: true
            )
        )

        await store.send(.languageFolders(.customFolderTapped(customFolderID))) {
            $0.path.append(
                .folderWords(
                    GLIFolderWordsFeature.State(identity: .custom(self.customFolderID))
                )
            )
        }

        #expect(persistence.stored.value == .custom(customFolderID))
        #expect(persistence.saved.value == [.custom(customFolderID)])
    }

    @Test("validates persisted custom folder via SwiftData and pushes when it exists")
    func restoresExistingCustomFolder() async throws {
        let persistence = makePersistence(initial: .custom(customFolderID))
        let folderID = customFolderID
        let folder = makeCustomFolder()
        let store = makeStore(
            persistence: persistence,
            fetchCustomFolder: { id in
                guard id == folderID else { return nil }
                return folder
            }
        )
        store.exhaustivity = .off

        await store.send(.onAppear) {
            $0.hasLoadedPendingResume = true
            $0.didAttemptFolderRestore = true
        }
        await store.receive(\.resumeFolderValidated)
        let customPathID = try #require(store.state.path.ids.first)
        #expect(store.state.path.count == 1)
        #expect(store.state.path[id: customPathID, case: \.folderWords]?.identity == .custom(folderID))

        #expect(persistence.clearCount.value == 0)
        #expect(persistence.stored.value == .custom(customFolderID))
    }

    @Test("stale custom id clears persistence and stays at root")
    func staleCustomIDClearsAndStaysAtRoot() async {
        let persistence = makePersistence(initial: .custom(customFolderID))
        let store = makeStore(
            persistence: persistence,
            fetchCustomFolder: { _ in nil }
        )

        await store.send(.onAppear) {
            $0.hasLoadedPendingResume = true
            $0.didAttemptFolderRestore = true
        }
        await store.receive(\.resumeFolderValidated)

        #expect(store.state.path.isEmpty)
        #expect(persistence.stored.value == nil)
        #expect(persistence.clearCount.value == 1)
    }

    @Test("popping back to root clears persisted folder destination")
    func rootPopClears() async throws {
        let languageFolder = makeLanguageFolder()
        let persistence = makePersistence(initial: .language(languageFolderID))
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
                GLIFolderWordsFeature.State(identity: .language(languageFolderID))
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
        let persistence = makePersistence(initial: .language(languageFolderID))
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
                    words: IdentifiedArray(uniqueElements: [word]),
                    languageCode: "es"
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

        #expect(persistence.stored.value == .language(languageFolderID))
        #expect(persistence.clearCount.value == 0)
        #expect(persistence.saved.value.isEmpty)
        #expect(store.state.path.count == 2)
    }

    @Test("capture sheet over a folder does not clear persisted folder")
    func sheetPresenceDoesNotClearFolder() async throws {
        let languageFolder = makeLanguageFolder()
        let persistence = makePersistence(initial: .language(languageFolderID))
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
                GLIFolderWordsFeature.State(identity: .language(languageFolderID))
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
        #expect(persistence.stored.value == .language(languageFolderID))
        #expect(persistence.clearCount.value == 0)
        #expect(store.state.path.count == 1)
    }

    // MARK: - Helpers

    private struct Persistence {
        let stored: LockIsolated<GLILastOpenedFolder?>
        let saved: LockIsolated<[GLILastOpenedFolder]>
        let clearCount: LockIsolated<Int>

        var client: GLILastOpenedFolderClient {
            GLILastOpenedFolderClient(
                load: { stored.value },
                save: { destination in
                    stored.setValue(destination)
                    saved.withValue { $0.append(destination) }
                },
                clearToRoot: {
                    stored.setValue(nil)
                    clearCount.withValue { $0 += 1 }
                }
            )
        }
    }

    private func makePersistence(initial: GLILastOpenedFolder? = nil) -> Persistence {
        Persistence(
            stored: LockIsolated(initial),
            saved: LockIsolated([]),
            clearCount: LockIsolated(0)
        )
    }

    private func makeStore(
        persistence: Persistence,
        initialState: GLIAppFeature.State = GLIAppFeature.State(),
        fetchLanguageFolder: @escaping @Sendable (UUID) async throws -> GLILanguageFolder? = { _ in nil },
        fetchCustomFolder: @escaping @Sendable (UUID) async throws -> GLICustomFolder? = { _ in nil }
    ) -> TestStoreOf<GLIAppFeature> {
        TestStore(initialState: initialState) {
            GLIAppFeature()
        } withDependencies: {
            $0.lastOpenedFolder = persistence.client
            $0.languageFolders = GLILanguageFoldersClient(
                fetchLanguageFolders: { [] },
                fetchLanguageFolder: fetchLanguageFolder
            )
            $0.customFolders = GLICustomFoldersClient(
                fetch: { [] },
                fetchCustomFolder: fetchCustomFolder,
                create: { name, sourceLanguage in
                    GLICustomFolder(name: name, sourceLanguage: sourceLanguage)
                },
                rename: { id, name in
                    GLICustomFolder(id: id, name: name, sourceLanguage: "es")
                },
                delete: { _ in }
            )
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

    private func makeCustomFolder() -> GLICustomFolder {
        GLICustomFolder(
            id: customFolderID,
            name: "Travel",
            sourceLanguage: "es"
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
