import ComposableArchitecture
import Foundation
import GlimpseCore
import GlimpseFeatures
import IdentifiedCollections
import Testing

@Suite("GLIAppFeature card reconciliation")
@MainActor
struct GLIAppFeatureCardReconciliationTests {
    private let folderID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let wordID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    private let otherWordID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!

    @Test("updated card replaces the preceding folder snapshot without changing navigation")
    func updateReconcilesFolderSnapshot() async throws {
        let original = makeWord(id: wordID, word: "hola")
        let updated = makeWord(id: wordID, word: "hola!", translation: "hello!")
        let initialState = makeState(words: [original])
        let pathIDs = Array(initialState.path.ids)
        let folderPathID = try #require(pathIDs.first)
        let cardPathID = try #require(pathIDs.last)
        let store = TestStore(initialState: initialState) {
            GLIAppFeature()
        } withDependencies: {
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

        await store.send(
            .path(
                .element(
                    id: cardPathID,
                    action: .wordCard(.delegate(.updated(updated)))
                )
            )
        ) {
            $0.path[id: folderPathID, case: \.folderWords]?.words[id: self.wordID] = updated
        }

        #expect(Array(store.state.path.ids) == pathIDs)
        let folder = try #require(
            store.state.path[id: folderPathID, case: \.folderWords]
        )
        #expect(folder.id == folderID)
        #expect(folder.languageCode == "es")
        #expect(folder.words[id: wordID] == updated)
    }

    @Test("deleted card removes only its row and pops only the card destination")
    func deleteReconcilesFolderAndPopsCard() async throws {
        let deleted = makeWord(id: wordID, word: "hola")
        let remaining = makeWord(id: otherWordID, word: "adiós")
        let initialState = makeState(words: [deleted, remaining])
        let pathIDs = Array(initialState.path.ids)
        let folderPathID = try #require(pathIDs.first)
        let cardPathID = try #require(pathIDs.last)
        let store = TestStore(initialState: initialState) {
            GLIAppFeature()
        } withDependencies: {
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

        await store.send(
            .path(
                .element(
                    id: cardPathID,
                    action: .wordCard(.delegate(.deleted(wordID)))
                )
            )
        ) {
            $0.path[id: folderPathID, case: \.folderWords]?.words.remove(id: self.wordID)
            $0.path.removeLast()
        }

        #expect(Array(store.state.path.ids) == [folderPathID])
        let folder = try #require(
            store.state.path[id: folderPathID, case: \.folderWords]
        )
        #expect(folder.id == folderID)
        #expect(folder.languageCode == "es")
        #expect(folder.words.elements == [remaining])
    }

    private func makeState(words: [GLIWordPair]) -> GLIAppFeature.State {
        var state = GLIAppFeature.State()
        state.path.append(
            .folderWords(
                GLIFolderWordsFeature.State(
                    id: folderID,
                    languageCode: "es",
                    words: IdentifiedArray(uniqueElements: words)
                )
            )
        )
        state.path.append(
            .wordCard(
                GLIWordCardFeature.State(
                    wordPair: words[0],
                    example: "Example"
                )
            )
        )
        return state
    }

    private func makeWord(
        id: UUID,
        word: String,
        translation: String = "translation"
    ) -> GLIWordPair {
        GLIWordPair(
            id: id,
            word: word,
            translation: translation,
            sourceLanguage: "es",
            targetLanguage: "en"
        )
    }
}
