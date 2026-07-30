import ComposableArchitecture
import Foundation
import GlimpseCore
import GlimpseFeatures
import IdentifiedCollections
import Testing

@Suite("GLIAppFeature navigation")
@MainActor
struct GLIAppFeatureNavigationTests {
    private let folderID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let wordID = UUID(uuidString: "00000000-0000-0000-0000-000000000010")!

    @Test("folderTapped pushes folderWords destination with language id only")
    func folderTappedPushesFolderWords() async {
        let store = TestStore(
            initialState: GLIAppFeature.State()
        ) {
            GLIAppFeature()
        } withDependencies: {
            $0.lastOpenedFolder = .inMemory()
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
        }

        await store.send(.languageFolders(.folderTapped(folderID))) {
            $0.path.append(
                .folderWords(
                    GLIFolderWordsFeature.State(identity: .language(folderID))
                )
            )
        }
    }

    @Test("folderTapped for Unsorted pushes folderWords with language id only")
    func folderTappedPushesUnsorted() async {
        let unsortedID = UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!
        let store = TestStore(
            initialState: GLIAppFeature.State()
        ) {
            GLIAppFeature()
        } withDependencies: {
            $0.lastOpenedFolder = .inMemory()
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
        }

        await store.send(.languageFolders(.folderTapped(unsortedID))) {
            $0.path.append(
                .folderWords(
                    GLIFolderWordsFeature.State(identity: .language(unsortedID))
                )
            )
        }
    }

    @Test("customFolderTapped pushes folderWords with custom id only")
    func customFolderTappedPushesFolderWords() async {
        let customID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let store = TestStore(
            initialState: GLIAppFeature.State()
        ) {
            GLIAppFeature()
        } withDependencies: {
            $0.lastOpenedFolder = .inMemory()
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
        }

        await store.send(.languageFolders(.customFolderTapped(customID))) {
            $0.path.append(
                .folderWords(
                    GLIFolderWordsFeature.State(identity: .custom(customID))
                )
            )
        }
    }

    @Test("wordTapped from folderWords appends wordCard")
    func wordTappedAppendsWordCard() async throws {
        let pair = GLIWordPair(
            id: wordID,
            word: "hola",
            translation: "hello",
            sourceLanguage: "es"
        )
        let store = TestStore(
            initialState: GLIAppFeature.State(
                path: StackState([
                    .folderWords(
                        GLIFolderWordsFeature.State(
                            id: folderID,
                            words: IdentifiedArray(uniqueElements: [pair]),
                            languageCode: "es",
                            hasCompletedInitialLoad: true
                        )
                    )
                ])
            )
        ) {
            GLIAppFeature()
        } withDependencies: {
            $0.lastOpenedFolder = .inMemory()
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
        }

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
                .wordCard(GLIWordCardFeature.State(wordPair: pair))
            )
        }
    }

    @Test("folderDeleted from custom folderWords pops that destination")
    func folderDeletedPopsFolderWords() async throws {
        let customID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let store = TestStore(
            initialState: GLIAppFeature.State(
                path: StackState([
                    .folderWords(
                        GLIFolderWordsFeature.State(
                            identity: .custom(customID),
                            customFolderName: "Travel",
                            hasCompletedInitialLoad: true
                        )
                    )
                ])
            )
        ) {
            GLIAppFeature()
        } withDependencies: {
            $0.lastOpenedFolder = .inMemory()
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
        }

        let folderPathID = try #require(store.state.path.ids.first)
        await store.send(
            .path(
                .element(
                    id: folderPathID,
                    action: .folderWords(.delegate(.folderDeleted))
                )
            )
        ) {
            $0.path.removeLast()
        }
        #expect(store.state.path.isEmpty)
    }
}
