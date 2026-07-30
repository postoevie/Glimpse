import ComposableArchitecture
import Foundation
import GlimpseCore
import GlimpseFeatures
import IdentifiedCollections
import IssueReporting
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
        wordPairs: GLIWordPairsClient,
        languageFolders: GLILanguageFoldersClient? = nil,
        customFolders: GLICustomFoldersClient? = nil
    ) -> TestStoreOf<GLIFolderWordsFeature> {
        let resolvedLanguageCode = languageCode
        let folderID = folderID
        return TestStore(
            initialState: initialState ?? GLIFolderWordsFeature.State(
                id: folderID,
                languageCode: languageCode
            )
        ) {
            GLIFolderWordsFeature()
        } withDependencies: {
            $0.wordPairs = wordPairs
            $0.languageFolders = languageFolders ?? GLILanguageFoldersClient(
                fetchLanguageFolders: { [] },
                fetchLanguageFolder: { id in
                    guard id == folderID else { return nil }
                    return GLILanguageFolder(id: folderID, languageCode: resolvedLanguageCode)
                }
            )
            $0.customFolders = customFolders ?? GLICustomFoldersClient(
                fetch: { [] },
                create: { name, sourceLanguage in
                    GLICustomFolder(name: name, sourceLanguage: sourceLanguage)
                },
                rename: { id, name in
                    GLICustomFolder(id: id, name: name, sourceLanguage: "es")
                },
                delete: { _ in }
            )
            $0.languageDetector = GLILanguageDetectorClient(
                detectSourceLanguage: { _ in "es" }
            )
            $0.wordExamples = GLIWordExamplesClient(fetchExample: { _ in "" })
        }
    }

    private func finishedChangesWordPairs(
        fetchInFolder: @escaping @Sendable (UUID) async throws -> [GLIWordPair] = { _ in [] },
        fetchInCustomFolder: @escaping @Sendable (UUID) async throws -> [GLIWordPair] = { _ in [] },
        save: @escaping @Sendable (GLIWordPair) async throws -> Void = { _ in }
    ) -> GLIWordPairsClient {
        GLIWordPairsClient(
            fetchWordPairs: { [] },
            fetchWordPairsInFolder: fetchInFolder,
            fetchWordPairsInCustomFolder: fetchInCustomFolder,
            save: save,
            changes: { AsyncStream { $0.finish() } }
        )
    }

    private func customFoldersClient(
        name: String = "Travel"
    ) -> GLICustomFoldersClient {
        let folderID = folderID
        return GLICustomFoldersClient(
            fetch: { [] },
            fetchCustomFolder: { id in
                guard id == folderID else { return nil }
                return GLICustomFolder(id: folderID, name: name, sourceLanguage: "es")
            },
            create: { name, sourceLanguage in
                GLICustomFolder(name: name, sourceLanguage: sourceLanguage)
            },
            rename: { id, name in
                GLICustomFolder(id: id, name: name, sourceLanguage: "es")
            },
            delete: { _ in }
        )
    }

    @Test("onAppear loads words via fetchWordPairsInFolder into the list")
    func onAppearLoadsWords() async {
        let pair = GLIWordPair(id: pairID, word: "hola", translation: "hello", sourceLanguage: "es")
        let expectedFolderID = folderID
        let fetchedFolderID = LockIsolated<UUID?>(nil)
        let store = makeStore(
            initialState: GLIFolderWordsFeature.State(identity: .language(folderID)),
            wordPairs: finishedChangesWordPairs(fetchInFolder: { id in
                fetchedFolderID.setValue(id)
                return [pair]
            })
        )

        await store.send(.onAppear)
        await store.receive(\.contentLoaded) {
            $0.languageCode = "es"
            $0.words = IdentifiedArray(uniqueElements: [pair])
            $0.hasCompletedInitialLoad = true
        }
        await store.finish()
        #expect(fetchedFolderID.value == expectedFolderID)
    }

    @Test("onAppear with empty folder leaves words empty")
    func onAppearEmptyLoad() async {
        let store = makeStore(
            initialState: GLIFolderWordsFeature.State(identity: .language(folderID)),
            wordPairs: finishedChangesWordPairs()
        )

        await store.send(.onAppear)
        await store.receive(\.contentLoaded) {
            $0.languageCode = "es"
            $0.hasCompletedInitialLoad = true
        }
        await store.finish()
        #expect(store.state.words.isEmpty)
    }

    @Test("onAppear for custom folder loads via fetchWordPairsInCustomFolder")
    func onAppearCustomFolderLoadsWords() async {
        let pair = GLIWordPair(id: pairID, word: "hola", translation: "hello", sourceLanguage: "es")
        let expectedFolderID = folderID
        let fetchedCustomID = LockIsolated<UUID?>(nil)
        let fetchedLanguageID = LockIsolated<UUID?>(nil)
        let store = makeStore(
            initialState: GLIFolderWordsFeature.State(identity: .custom(folderID)),
            wordPairs: finishedChangesWordPairs(
                fetchInFolder: { id in
                    fetchedLanguageID.setValue(id)
                    return []
                },
                fetchInCustomFolder: { id in
                    fetchedCustomID.setValue(id)
                    return [pair]
                }
            ),
            customFolders: customFoldersClient()
        )

        await store.send(.onAppear)
        await store.receive(\.contentLoaded) {
            $0.customFolderName = "Travel"
            $0.words = IdentifiedArray(uniqueElements: [pair])
            $0.hasCompletedInitialLoad = true
        }
        await store.finish()
        #expect(fetchedCustomID.value == expectedFolderID)
        #expect(fetchedLanguageID.value == nil)
    }

    @Test("onAppear for empty custom folder leaves words empty after initial load")
    func onAppearCustomFolderEmptyLoad() async {
        let store = makeStore(
            initialState: GLIFolderWordsFeature.State(identity: .custom(folderID)),
            wordPairs: finishedChangesWordPairs(),
            customFolders: customFoldersClient()
        )

        await store.send(.onAppear)
        await store.receive(\.contentLoaded) {
            $0.customFolderName = "Travel"
            $0.hasCompletedInitialLoad = true
        }
        await store.finish()
        #expect(store.state.words.isEmpty)
    }

    @Test("onAppear for missing language folder fails load, reports issue, and completes empty")
    func onAppearMissingLanguageFolder() async {
        let store = makeStore(
            initialState: GLIFolderWordsFeature.State(identity: .language(folderID)),
            wordPairs: finishedChangesWordPairs(),
            languageFolders: GLILanguageFoldersClient(
                fetchLanguageFolders: { [] },
                fetchLanguageFolder: { _ in nil }
            )
        )

        await withExpectedIssue("folder missing for identity") {
            await store.send(.onAppear)
            await store.receive(\.contentLoaded.failure) {
                $0.hasCompletedInitialLoad = true
            }
        }
        await store.finish()
        #expect(store.state.words.isEmpty)
        #expect(store.state.languageCode == nil)
    }

    @Test("after save, changes stream triggers contentLoaded refresh")
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
        await store.receive(\.contentLoaded)
        #expect(store.state.words.isEmpty)

        await store.send(.addWord(.presented(.doneButtonTapped)))
        await store.receive(\.addWord.presented.delegate.wordAdded)
        await store.receive(\.contentLoaded)
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

    @Test("wordTapped with known id does not mutate folder state")
    func wordTappedKnownIdIsNoOp() async {
        let pair = GLIWordPair(
            id: pairID,
            word: "hola",
            translation: "hello",
            sourceLanguage: "es"
        )
        let store = makeStore(
            initialState: GLIFolderWordsFeature.State(
                id: folderID,
                words: IdentifiedArray(uniqueElements: [pair]),
                languageCode: "es",
                hasCompletedInitialLoad: true
            ),
            wordPairs: finishedChangesWordPairs()
        )

        await store.send(.wordTapped(pairID))
        #expect(store.state.words[id: pairID] == pair)
    }

    @Test("wordTapped with missing id reports issue and does not mutate")
    func wordTappedMissingIdIsNoOp() async {
        let missingID = UUID(uuidString: "00000000-0000-0000-0000-000000000099")!
        let store = makeStore(
            initialState: GLIFolderWordsFeature.State(
                id: folderID,
                languageCode: "es",
                hasCompletedInitialLoad: true
            ),
            wordPairs: finishedChangesWordPairs()
        )

        await withExpectedIssue("wordTapped with id missing from words list") {
            await store.send(.wordTapped(missingID))
        }
        #expect(store.state.words.isEmpty)
    }

    @Test("renameButtonTapped on custom folder presents rename form with current name")
    func renameButtonPresentsForm() async {
        let store = makeStore(
            initialState: GLIFolderWordsFeature.State(
                identity: .custom(folderID),
                customFolderName: "Travel",
                hasCompletedInitialLoad: true
            ),
            wordPairs: finishedChangesWordPairs(),
            customFolders: customFoldersClient()
        )

        await store.send(.renameButtonTapped) {
            $0.folderForm = GLIFolderFormFeature.State(
                mode: .rename(folderID),
                name: "Travel"
            )
        }
    }

    @Test("renameButtonTapped on language folder reports issue")
    func renameButtonOnLanguageFolderReportsIssue() async {
        let store = makeStore(
            initialState: GLIFolderWordsFeature.State(
                identity: .language(folderID),
                languageCode: "es",
                hasCompletedInitialLoad: true
            ),
            wordPairs: finishedChangesWordPairs()
        )

        await withExpectedIssue("renameButtonTapped on non-custom folder") {
            await store.send(.renameButtonTapped)
        }
        #expect(store.state.folderForm == nil)
    }

    @Test("folderForm saved renames custom folder, updates title, and dismisses")
    func folderFormSavedRenamesAndUpdatesTitle() async {
        let renamedName = LockIsolated<String?>(nil)
        let store = makeStore(
            initialState: GLIFolderWordsFeature.State(
                identity: .custom(folderID),
                customFolderName: "Travel",
                hasCompletedInitialLoad: true,
                folderForm: GLIFolderFormFeature.State(
                    mode: .rename(folderID),
                    name: "Trips"
                )
            ),
            wordPairs: finishedChangesWordPairs(),
            customFolders: GLICustomFoldersClient(
                fetch: { [] },
                fetchCustomFolder: { id in
                    guard id == folderID else { return nil }
                    return GLICustomFolder(id: folderID, name: "Travel", sourceLanguage: "es")
                },
                create: { name, sourceLanguage in
                    GLICustomFolder(name: name, sourceLanguage: sourceLanguage)
                },
                rename: { id, name in
                    renamedName.setValue(name)
                    return GLICustomFolder(id: id, name: name, sourceLanguage: "es")
                },
                delete: { _ in }
            )
        )

        await store.send(.folderForm(.presented(.delegate(.saved))))
        await store.receive(\.customFolderRenamed) {
            $0.customFolderName = "Trips"
        }
        await store.receive(\.folderForm.dismiss) {
            $0.folderForm = nil
        }
        #expect(renamedName.value == "Trips")
        #expect(store.state.customFolderName == "Trips")
    }

    @Test("deleteButtonTapped on custom folder presents confirm alert")
    func deleteButtonPresentsAlert() async {
        let store = makeStore(
            initialState: GLIFolderWordsFeature.State(
                identity: .custom(folderID),
                customFolderName: "Travel",
                hasCompletedInitialLoad: true
            ),
            wordPairs: finishedChangesWordPairs(),
            customFolders: customFoldersClient()
        )

        await store.send(.deleteButtonTapped) {
            $0.alert = AlertState {
                TextState("Delete Folder?")
            } actions: {
                ButtonState(
                    role: .destructive,
                    action: .confirmDeleteCustomFolder
                ) {
                    TextState("Delete")
                }
                ButtonState(role: .cancel) {
                    TextState("Cancel")
                }
            } message: {
                TextState("Words stay in their language folders.")
            }
        }
    }

    @Test("confirm delete deletes custom folder and delegates folderDeleted")
    func confirmDeleteDelegatesFolderDeleted() async {
        let deletedID = LockIsolated<UUID?>(nil)
        let store = makeStore(
            initialState: GLIFolderWordsFeature.State(
                identity: .custom(folderID),
                customFolderName: "Travel",
                hasCompletedInitialLoad: true,
                alert: AlertState {
                    TextState("Delete Folder?")
                } actions: {
                    ButtonState(
                        role: .destructive,
                        action: .confirmDeleteCustomFolder
                    ) {
                        TextState("Delete")
                    }
                    ButtonState(role: .cancel) {
                        TextState("Cancel")
                    }
                } message: {
                    TextState("Words stay in their language folders.")
                }
            ),
            wordPairs: finishedChangesWordPairs(),
            customFolders: GLICustomFoldersClient(
                fetch: { [] },
                fetchCustomFolder: { id in
                    guard id == folderID else { return nil }
                    return GLICustomFolder(id: folderID, name: "Travel", sourceLanguage: "es")
                },
                create: { name, sourceLanguage in
                    GLICustomFolder(name: name, sourceLanguage: sourceLanguage)
                },
                rename: { id, name in
                    GLICustomFolder(id: id, name: name, sourceLanguage: "es")
                },
                delete: { id in deletedID.setValue(id) }
            )
        )

        await store.send(.alert(.presented(.confirmDeleteCustomFolder))) {
            $0.alert = nil
        }
        await store.receive(\.delegate.folderDeleted)
        #expect(deletedID.value == folderID)
    }

    @Test("deleteButtonTapped on language folder reports issue")
    func deleteButtonOnLanguageFolderReportsIssue() async {
        let store = makeStore(
            initialState: GLIFolderWordsFeature.State(
                identity: .language(folderID),
                languageCode: "es",
                hasCompletedInitialLoad: true
            ),
            wordPairs: finishedChangesWordPairs()
        )

        await withExpectedIssue("deleteButtonTapped on non-custom folder") {
            await store.send(.deleteButtonTapped)
        }
        #expect(store.state.alert == nil)
    }
}
