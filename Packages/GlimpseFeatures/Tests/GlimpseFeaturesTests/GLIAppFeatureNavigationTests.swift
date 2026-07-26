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
            $0.languageFolders = GLILanguageFoldersClient(fetchLanguageFolders: { [folder] })
            $0.wordPairs = GLIWordPairsClient(
                fetchWordPairs: { [] },
                save: { _ in }
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
            $0.languageFolders = GLILanguageFoldersClient(fetchLanguageFolders: { [folder] })
            $0.wordPairs = GLIWordPairsClient(
                fetchWordPairs: { [] },
                save: { _ in }
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
}
