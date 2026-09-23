import ComposableArchitecture
import Foundation
import GlimpseCore
import GlimpseFeatures
import IdentifiedCollections
import IssueReporting
import Testing

@Suite("GLILanguageFoldersFeature")
@MainActor
struct GLILanguageFoldersFeatureTests {
    private let folderID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let draftID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    private enum UnusedClientError: Error, Sendable {
        case unused
    }

    private enum SaveError: Error {
        case boom
    }

    private var wordSaveFailedAlert: AlertState<GLILanguageFoldersFeature.Action.Alert> {
        AlertState {
            TextState("Couldn't save word")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("OK")
            }
        } message: {
            TextState("Your draft is still here.")
        }
    }

    private func makeStore(
        initialState: GLILanguageFoldersFeature.State = .init(),
        languageFolders: GLILanguageFoldersClient,
        wordPairs: GLIWordPairsClient,
        customFolders: GLICustomFoldersClient? = nil,
        preferences: GLIPreferencesClient = .inMemory(),
        wordPairMembership: GLIWordPairMembershipClient? = nil
    ) -> TestStoreOf<GLILanguageFoldersFeature> {
        let customFolders = customFolders ?? finishedChangesCustomFolders()
        return TestStore(initialState: initialState) {
            GLILanguageFoldersFeature()
        } withDependencies: {
            $0.languageFolders = languageFolders
            $0.wordPairs = wordPairs
            $0.customFolders = customFolders
            // AddWord child calls languageDetector on Done when source isn't manual.
            $0.languageDetector = GLILanguageDetectorClient(
                detectSourceLanguage: { _ in "es" }
            )
            $0.targetLanguageDetector = GLITargetLanguageDetectorClient(
                detectTargetLanguage: { _ in nil }
            )
            $0.wordMeanings = GLIWordMeaningsClient(
                fetch: { _ in [] },
                replaceAll: { _, _ in },
                firstMeanings: { _ in [:] },
                fetchAll: { _ in [:] }
            )
            $0.preferences = preferences
            $0.wordPairMembership = wordPairMembership ?? stubMembership()
        }
    }

    private func stubMembership(
        assignCustomFolder: @escaping @Sendable (UUID, UUID?, String?) async throws -> Void = { _, _, _ in }
    ) -> GLIWordPairMembershipClient {
        GLIWordPairMembershipClient(
            assignCustomFolder: assignCustomFolder,
            updateSource: { _, _ in throw UnusedClientError.unused },
            updateCustomFolder: { _, _ in throw UnusedClientError.unused },
            pruneEmptyLanguageFolders: {}
        )
    }

    private func finishedChangesCustomFolders(
        fetch: @escaping @Sendable () async throws -> [GLICustomFolder] = { [] }
    ) -> GLICustomFoldersClient {
        GLICustomFoldersClient(
            fetch: fetch,
            create: { name, sourceLanguage in
                GLICustomFolder(name: name, sourceLanguage: sourceLanguage)
            },
            rename: { id, name in
                GLICustomFolder(id: id, name: name, sourceLanguage: "es")
            },
            delete: { _ in },
            changes: { AsyncStream { $0.finish() } }
        )
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
        #expect(draft.meaningText == "")
        #expect(draft.wordPair.sourceLanguage == nil)
        #expect(draft.wordPair.targetLanguage == nil)
        #expect(draft.defaultCustomFolderPrefillMode == .always)
    }

    @Test("onAppear loads folders via fetchLanguageFolders into the list")
    func onAppearLoadsFolders() async {
        let existing = GLILanguageFolder(id: folderID, languageCode: "es")
        let store = makeStore(
            languageFolders: foldersClient(fetch: { [existing] }),
            wordPairs: finishedChangesWordPairs()
        )
        // Dual observe merge — skip exact receive order; assert final gate + lists.
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.skipReceivedActions()
        #expect(store.state.folders == IdentifiedArray(uniqueElements: [existing]))
        #expect(store.state.customFolders.isEmpty)
        #expect(store.state.hasCompletedLanguageFoldersLoad)
        #expect(store.state.hasCompletedCustomFoldersLoad)
        #expect(store.state.hasCompletedInitialLoad)
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
            $0.hasCompletedLanguageFoldersLoad = true
            // Initial load waits for custom folders too.
        }
        #expect(!store.state.hasCompletedInitialLoad)
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
        let draft = GLIWordPair(id: draftID, word: "hola")
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
        let draft = GLIWordPair(id: draftID, word: "hola", sourceLanguage: "es")
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

    @Test("wordAdded with selected custom folder assigns it and sets the sticky default")
    func wordAddedAssignsSelectedCustomFolder() async {
        let customFolderID = UUID(uuidString: "00000000-0000-0000-0000-0000000000C1")!
        let draft = GLIWordPair(
            id: draftID,
            word: "hola",
            sourceLanguage: "es",
            targetLanguage: "en"
        )
        let assigned = LockIsolated<(UUID, UUID?, String?)?>(nil)
        let preferences = GLIPreferencesClient.inMemory()
        let store = makeStore(
            initialState: GLILanguageFoldersFeature.State(
                addWord: GLIAddWordFeature.State(
                    wordPair: draft,
                    selectedCustomFolderID: customFolderID
                )
            ),
            languageFolders: foldersClient(fetch: { [] }),
            wordPairs: finishedChangesWordPairs(),
            preferences: preferences,
            wordPairMembership: stubMembership(
                assignCustomFolder: { wordID, folderID, target in
                    assigned.setValue((wordID, folderID, target))
                }
            )
        )

        await store.send(.addWord(.presented(.delegate(.wordAdded))))
        await store.receive(\.addWord.dismiss) {
            $0.addWord = nil
        }
        await store.finish()

        #expect(assigned.value?.0 == draftID)
        #expect(assigned.value?.1 == customFolderID)
        #expect(assigned.value?.2 == "en")
        #expect(preferences.defaultCustomFolderID() == customFolderID)
    }

    @Test("wordAdded without a custom folder assigns nil and clears the sticky default")
    func wordAddedClearsCustomFolderPreference() async {
        let customFolderID = UUID(uuidString: "00000000-0000-0000-0000-0000000000C1")!
        let draft = GLIWordPair(
            id: draftID,
            word: "hola",
            sourceLanguage: "es",
            targetLanguage: "en"
        )
        let assigned = LockIsolated<(UUID, UUID?, String?)?>(nil)
        let preferences = GLIPreferencesClient.inMemory(
            initialDefaultCustomFolderID: customFolderID
        )
        let store = makeStore(
            initialState: GLILanguageFoldersFeature.State(
                addWord: GLIAddWordFeature.State(wordPair: draft)
            ),
            languageFolders: foldersClient(fetch: { [] }),
            wordPairs: finishedChangesWordPairs(),
            preferences: preferences,
            wordPairMembership: stubMembership(
                assignCustomFolder: { wordID, folderID, target in
                    assigned.setValue((wordID, folderID, target))
                }
            )
        )

        await store.send(.addWord(.presented(.delegate(.wordAdded))))
        await store.receive(\.addWord.dismiss) {
            $0.addWord = nil
        }
        await store.finish()

        #expect(assigned.value?.0 == draftID)
        #expect(assigned.value?.1 == nil)
        #expect(assigned.value?.2 == "en")
        #expect(preferences.defaultCustomFolderID() == nil)
    }

    @Test("word save failure keeps the sheet and presents the draft-still-here alert")
    func wordSaveFailureKeepsSheetAndPresentsAlert() async {
        let draft = GLIWordPair(
            id: draftID,
            word: "hola",
            sourceLanguage: "es",
            targetLanguage: "en"
        )
        let store = makeStore(
            initialState: GLILanguageFoldersFeature.State(
                addWord: GLIAddWordFeature.State(
                    wordPair: draft,
                    isSaving: true
                )
            ),
            languageFolders: foldersClient(fetch: { [] }),
            wordPairs: finishedChangesWordPairs(save: { _ in throw SaveError.boom })
        )

        await withExpectedIssue {
            await store.send(.addWord(.presented(.delegate(.wordAdded))))
            await store.receive(\.wordSaveFailed) {
                $0.addWord?.isSaving = false
                $0.alert = wordSaveFailedAlert
            }
        }
        await store.finish()

        #expect(store.state.addWord != nil)
        #expect(store.state.alert != nil)
    }
}
