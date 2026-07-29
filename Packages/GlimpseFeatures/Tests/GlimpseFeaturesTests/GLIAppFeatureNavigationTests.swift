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

    @Test("folderTapped pushes folderWords destination with folder id and languageCode")
    func folderTappedPushesFolderWords() async {
        let folder = GLILanguageFolder(id: folderID, languageCode: "es")
        let store = TestStore(
            initialState: GLIAppFeature.State(
                languageFolders: GLILanguageFoldersFeature.State(
                    folders: IdentifiedArray(uniqueElements: [folder])
                )
            )
        ) {
            GLIAppFeature()
        } withDependencies: {
            $0.lastOpenedFolder = .inMemory()
            $0.languageFolders = GLILanguageFoldersClient(fetchLanguageFolders: { [folder] })
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
                    GLIFolderWordsFeature.State(
                        id: folderID,
                        languageCode: "es"
                    )
                )
            )
        }
    }

    @Test("folderTapped for Unsorted pushes folderWords with unsorted languageCode")
    func folderTappedPushesUnsorted() async {
        let folder = GLILanguageFolder(
            id: folderID,
            languageCode: GLILanguageFolder.unsortedCode
        )
        let store = TestStore(
            initialState: GLIAppFeature.State(
                languageFolders: GLILanguageFoldersFeature.State(
                    folders: IdentifiedArray(uniqueElements: [folder])
                )
            )
        ) {
            GLIAppFeature()
        } withDependencies: {
            $0.lastOpenedFolder = .inMemory()
            $0.languageFolders = GLILanguageFoldersClient(fetchLanguageFolders: { [folder] })
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
                    GLIFolderWordsFeature.State(
                        id: folderID,
                        languageCode: GLILanguageFolder.unsortedCode
                    )
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
                            languageCode: "es",
                            words: IdentifiedArray(uniqueElements: [pair]),
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
}
