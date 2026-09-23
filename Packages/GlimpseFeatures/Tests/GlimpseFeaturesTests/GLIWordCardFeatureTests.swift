import ComposableArchitecture
import Foundation
import GlimpseCore
import GlimpseFeatures
import IssueReporting
import Testing

/// UUIDs produced by TCA's incrementing generator (`00000000-0000-0000-0000-%012x`).
private enum IncrementingUUID {
    static subscript(_ n: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012x", n))!
    }
}

@Suite("GLIWordCardFeature", .serialized)
@MainActor
struct GLIWordCardFeatureTests {
    private enum Failure: Error {
        case expected
    }

    private let wordID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let folderID = UUID(uuidString: "00000000-0000-0000-0000-0000000000F1")!

    // MARK: - Draft / validation

    @Test("state initializes its editable draft and validates a trimmed word")
    func draftInitializationAndValidation() {
        var state = makeState(meanings: [GLIWordMeaning(text: "hello")])

        #expect(state.draft.word == "hola")
        #expect(state.draft.meanings.map(\.text) == ["hello"])
        #expect(state.draft.targetLanguage == "en")
        #expect(state.canSave == false)

        state.isEditing = true
        state.draft.word = " \n "
        #expect(state.canSave == false)

        state.draft.word = " bonjour "
        #expect(state.canSave == true)
    }

    @Test("isAtMeaningCap is true at the 20-meaning limit")
    func meaningCap() {
        var state = makeState()
        state.draft.meanings = IdentifiedArrayOf(
            uniqueElements: (0..<20).map { GLIWordMeaning(text: "m\($0)") }
        )
        #expect(state.isAtMeaningCap == true)
        state.draft.meanings.removeLast()
        #expect(state.isAtMeaningCap == false)
    }

    // MARK: - Load meanings

    @Test("onAppear loads meanings and, with a known source, eligible custom folders")
    func onAppearLoadsMeaningsAndEligibleFolders() async {
        let meaning = GLIWordMeaning(text: "hello")
        let eligible = GLICustomFolder(id: folderID, name: "Travel", sourceLanguage: "es")
        let store = makeStore(
            fetchMeanings: { _ in [meaning] },
            fetchCustomFolders: { [eligible] }
        )

        // makeStore()'s default state is already .loading — no observable change here.
        await store.send(.view(.onAppear))
        await store.receive(\.meaningsLoaded) {
            $0.meaningsLoadState = .loaded([meaning])
            $0.draft = GLIWordCardFeature.State.Draft(
                wordPair: $0.wordPair,
                meanings: [meaning]
            )
        }
        await store.receive(\.customFoldersLoaded) {
            $0.allCustomFolders = [eligible]
        }
        await store.receive(\.membershipLoaded, nil as UUID?)
        #expect(store.state.eligibleCustomFolders == [eligible])
    }

    @Test("onAppear with Unsorted word loads allCustomFolders; eligibleCustomFolders stays empty")
    func onAppearUnsortedLoadsAllFolders() async {
        let anyFolder = GLICustomFolder(id: folderID, name: "Travel", sourceLanguage: "fr")
        var state = makeState()
        state.wordPair.sourceLanguage = nil
        let store = makeStore(
            initialState: state,
            fetchCustomFolders: { [anyFolder] }
        )

        // makeState()'s default is already .loading — no observable change here.
        await store.send(.view(.onAppear))
        await store.receive(\.meaningsLoaded) {
            $0.meaningsLoadState = .loaded([])
            $0.draft = GLIWordCardFeature.State.Draft(wordPair: $0.wordPair, meanings: [])
        }
        await store.receive(\.customFoldersLoaded) {
            $0.allCustomFolders = [anyFolder]
        }
        #expect(store.state.eligibleCustomFolders == [])
    }

    @Test("meanings load failure sets the failure flag and blocks edit")
    func meaningsLoadFailureBlocksEdit() async {
        let store = makeStore(fetchMeanings: { _ in throw Failure.expected })
        // Dual merge on onAppear — the folder load still fires; this test only cares about meanings.
        store.exhaustivity = .off

        // makeStore()'s default state is already .loading — no observable change here.
        await withExpectedIssue {
            await store.send(.view(.onAppear))
            await store.receive(\.meaningsLoadFailed) {
                $0.meaningsLoadState = .failed
            }
        }

        await store.send(.view(.editButtonTapped))
        #expect(store.state.isEditing == false)
    }

    // MARK: - Edit / cancel

    @Test("edit seeds one empty meaning row when the card has none")
    func editSeedsEmptyRowWhenNoMeanings() async {
        let store = makeStore(initialState: makeState(meanings: []))

        await store.send(.view(.editButtonTapped)) {
            $0.isEditing = true
            $0.draft.meanings = [
                GLIWordMeaning(id: IncrementingUUID[0], text: "", language: "en"),
            ]
        }
        #expect(store.state.draft.meanings.count == 1)
    }

    @Test("cancel discards every draft change")
    func cancelRestoresPersistedValues() async {
        let meaning = GLIWordMeaning(text: "hello")
        let store = makeStore(initialState: makeState(meanings: [meaning]))

        await store.send(.view(.editButtonTapped)) {
            $0.isEditing = true
        }
        await store.send(.view(.wordChanged("bonjour"))) {
            $0.draft.word = "bonjour"
        }
        await store.send(.view(.targetLanguageChanged("fr"))) {
            $0.didManuallySetTarget = true
            $0.draft.targetLanguage = "fr"
        }
        await store.send(.view(.cancelButtonTapped)) {
            $0.draft = GLIWordCardFeature.State.Draft(
                wordPair: $0.wordPair,
                meanings: [meaning]
            )
            $0.didManuallySetTarget = false
            $0.isEditing = false
        }
    }

    // MARK: - Add / remove meaning rows

    @Test("addMeaningTapped appends an empty row defaulted to the card target language")
    func addMeaningAppendsRow() async {
        var state = makeState(meanings: [])
        state.isEditing = true
        state.draft.targetLanguage = "fr"
        let store = makeStore(initialState: state)

        await store.send(.view(.addMeaningTapped)) {
            $0.draft.meanings.append(
                GLIWordMeaning(id: IncrementingUUID[0], text: "", language: "fr")
            )
        }
    }

    @Test("addMeaningTapped no-ops at the cap")
    func addMeaningNoOpsAtCap() async {
        var state = makeState()
        state.isEditing = true
        state.draft.meanings = IdentifiedArrayOf(
            uniqueElements: (0..<20).map { GLIWordMeaning(text: "m\($0)") }
        )
        let store = makeStore(initialState: state)

        await store.send(.view(.addMeaningTapped))
        #expect(store.state.draft.meanings.count == 20)
    }

    @Test("removeMeaningTapped drops the row")
    func removeMeaningDropsRow() async {
        let meaning = GLIWordMeaning(text: "hello")
        var state = makeState(meanings: [meaning])
        state.isEditing = true
        state.draft.meanings = [meaning]
        let store = makeStore(initialState: state)

        await store.send(.view(.removeMeaningTapped(id: meaning.id))) {
            $0.draft.meanings.remove(id: meaning.id)
        }
    }

    @Test("meaningTextChanged writes text and applies the detected language after the debounce")
    func meaningTextChangedRunsDetection() async {
        let meaning = GLIWordMeaning(text: "")
        var state = makeState(meanings: [])
        state.isEditing = true
        state.draft.meanings = [meaning]
        let store = makeStore(
            initialState: state,
            detectTargetLanguage: { _ in "fr" }
        )

        await store.send(.view(.meaningTextChanged(id: meaning.id, text: "bonjour"))) {
            $0.draft.meanings[id: meaning.id]?.text = "bonjour"
            $0.pendingLanguageDetectionID = meaning.id
        }
        await store.receive(\.languageDetectionResponse) {
            $0.pendingLanguageDetectionID = nil
            $0.draft.meanings[id: meaning.id]?.language = "fr"
            $0.draft.targetLanguage = "fr"
        }
    }

    // MARK: - Save

    @Test("save trims the word, drops the untouched empty seed row, and persists meanings")
    func saveDropsUntouchedEmptyRow() async {
        let replacedMeanings = LockIsolated<[GLIWordMeaning]>([])
        let updated = GLIWordPair(id: wordID, word: "bonjour", sourceLanguage: "es", targetLanguage: "en")
        var state = makeState(meanings: [])
        state.isEditing = true
        state.draft.word = "  bonjour \n"
        state.draft.meanings = [GLIWordMeaning(text: "")] // untouched Edit-seed row
        let store = makeStore(
            initialState: state,
            update: { _ in updated },
            replaceAll: { _, meanings in replacedMeanings.setValue(meanings) }
        )

        await store.send(.view(.saveButtonTapped)) {
            $0.isSaving = true
        }
        await store.receive(\.saveSucceeded) {
            $0.wordPair = updated
            $0.meaningsLoadState = .loaded([])
            $0.draft = GLIWordCardFeature.State.Draft(wordPair: updated, meanings: [])
            $0.isSaving = false
            $0.isEditing = false
            $0.lightHapticTick = 1
        }
        await store.receive(\.delegate.updated, updated)

        #expect(replacedMeanings.value.isEmpty)
    }

    @Test("save preserves custom-folder membership across the word-card update")
    func savePreservesCustomFolderID() async {
        let meaning = GLIWordMeaning(text: "hello")
        let updated = GLIWordPair(id: wordID, word: "hola", sourceLanguage: "es", targetLanguage: "en")
        let mergedWordPair: GLIWordPair = {
            var pair = updated
            pair.customFolderID = folderID
            return pair
        }()
        let assigned = LockIsolated<(UUID, UUID?, String?)?>(nil)
        var state = makeState(meanings: [meaning])
        state.wordPair.customFolderID = folderID
        state.isEditing = true
        state.draft.word = "hola"
        // A real actor's update only touches word/targetLanguage columns and returns the
        // full current row — customFolderID is already there, not merged in by the reducer.
        // Save still re-files that folder after replaceAll.
        let store = makeStore(
            initialState: state,
            update: { _ in mergedWordPair },
            assignCustomFolder: { wordID, customFolderID, targetLanguage in
                assigned.setValue((wordID, customFolderID, targetLanguage))
            }
        )

        await store.send(.view(.saveButtonTapped)) {
            $0.isSaving = true
        }
        await store.receive(\.saveSucceeded) {
            $0.wordPair = mergedWordPair
            $0.meaningsLoadState = .loaded([meaning])
            $0.draft = GLIWordCardFeature.State.Draft(
                wordPair: mergedWordPair,
                meanings: [meaning]
            )
            $0.isSaving = false
            $0.isEditing = false
            $0.lightHapticTick = 1
        }
        await store.receive(\.delegate.updated, mergedWordPair)
        #expect(store.state.wordPair.customFolderID == folderID)
        #expect(assigned.value?.0 == wordID)
        #expect(assigned.value?.1 == folderID)
        #expect(assigned.value?.2 == "en")
    }

    @Test("blank-word save is ignored")
    func blankWordDoesNotSave() async {
        let updates = LockIsolated(0)
        var state = makeState(meanings: [])
        state.isEditing = true
        state.draft.word = " \n "
        let store = makeStore(initialState: state, update: { update in
            updates.withValue { $0 += 1 }
            return GLIWordPair(id: wordID, word: update.word, sourceLanguage: "es")
        })

        await store.send(.view(.saveButtonTapped))
        await store.finish()

        #expect(updates.value == 0)
    }

    @Test("failed save keeps the draft and retry succeeds")
    func saveFailureAndRetry() async {
        let attempts = LockIsolated(0)
        let updated = GLIWordPair(id: wordID, word: "bonjour", sourceLanguage: "es", targetLanguage: "en")
        var state = makeState(meanings: [])
        state.isEditing = true
        state.draft.word = "bonjour"
        let store = makeStore(initialState: state, update: { _ in
            let attempt = attempts.withValue {
                $0 += 1
                return $0
            }
            guard attempt > 1 else {
                throw Failure.expected
            }
            return updated
        })

        await withExpectedIssue {
            await store.send(.view(.saveButtonTapped)) {
                $0.isSaving = true
            }
            await store.receive(\.saveFailed) {
                $0.isSaving = false
                $0.alert = saveFailureAlert()
            }
        }
        #expect(store.state.draft.word == "bonjour")

        await store.send(.alert(.presented(.retrySave))) {
            $0.alert = nil
        }
        await store.receive(\.view.saveButtonTapped) {
            $0.isSaving = true
        }
        await store.receive(\.saveSucceeded) {
            $0.wordPair = updated
            $0.meaningsLoadState = .loaded([])
            $0.draft = GLIWordCardFeature.State.Draft(wordPair: updated, meanings: [])
            $0.isSaving = false
            $0.isEditing = false
            $0.lightHapticTick = 1
        }
        await store.receive(\.delegate.updated, updated)

        #expect(attempts.value == 2)
    }

    // MARK: - Delete

    @Test("delete requires confirmation and publishes success")
    func deleteConfirmationAndSuccess() async {
        let deletedIDs = LockIsolated<[UUID]>([])
        let store = makeStore(delete: { wordID in
            deletedIDs.withValue { $0.append(wordID) }
        })

        await store.send(.view(.deleteButtonTapped)) {
            $0.alert = deleteConfirmationAlert()
        }
        await store.send(.alert(.presented(.confirmDelete))) {
            $0.alert = nil
        }
        await store.receive(\.deleteConfirmed) {
            $0.isDeleting = true
        }
        await store.receive(\.deleteSucceeded) {
            $0.isDeleting = false
        }
        await store.receive(\.delegate.deleted, wordID)

        #expect(deletedIDs.value == [wordID])
    }

    @Test("failed delete keeps the card and retry succeeds")
    func deleteFailureAndRetry() async {
        let attempts = LockIsolated(0)
        let store = makeStore(delete: { _ in
            let attempt = attempts.withValue {
                $0 += 1
                return $0
            }
            guard attempt > 1 else {
                throw Failure.expected
            }
        })

        await withExpectedIssue {
            await store.send(.deleteConfirmed) {
                $0.isDeleting = true
            }
            await store.receive(\.deleteFailed) {
                $0.isDeleting = false
                $0.alert = deleteFailureAlert()
            }
        }
        #expect(store.state.wordPair.id == wordID)

        await store.send(.alert(.presented(.retryDelete))) {
            $0.alert = nil
        }
        await store.receive(\.deleteConfirmed) {
            $0.isDeleting = true
        }
        await store.receive(\.deleteSucceeded) {
            $0.isDeleting = false
        }
        await store.receive(\.delegate.deleted, wordID)

        #expect(attempts.value == 2)
    }

    // MARK: - Membership

    @Test("sourceLanguagePicked from Unsorted moves the word to a language folder; eligibleCustomFolders now reflects it")
    func sourceLanguagePickedFromUnsortedLoadsEligible() async {
        let eligible = GLICustomFolder(id: folderID, name: "Travel", sourceLanguage: "es")
        var state = makeState(meanings: [])
        state.wordPair.sourceLanguage = nil
        let updated = GLIWordPair(id: wordID, word: "hola", sourceLanguage: "es", targetLanguage: "en")
        let store = makeStore(
            initialState: state,
            fetchMeanings: { _ in [] },
            updateSource: { _, source in
                #expect(source == "es")
                return updated
            },
            fetchCustomFolders: { [eligible] }
        )

        // allCustomFolders only loads on appear now — seed it before the membership pick.
        await store.send(.view(.onAppear)) {
            $0.meaningsLoadState = .loading
        }
        await store.receive(\.meaningsLoaded) {
            $0.meaningsLoadState = .loaded([])
            $0.draft = GLIWordCardFeature.State.Draft(wordPair: $0.wordPair, meanings: [])
        }
        await store.receive(\.customFoldersLoaded) {
            $0.allCustomFolders = [eligible]
        }
        #expect(store.state.eligibleCustomFolders == [])

        await store.send(.view(.sourceLanguagePicked("es")))
        await store.receive(\.sourceUpdateSucceeded) {
            $0.wordPair = updated
        }
        await store.receive(\.delegate.updated, updated)
        #expect(store.state.eligibleCustomFolders == [eligible])
    }

    @Test("sourceLanguagePicked to Not set moves the word to Unsorted; allCustomFolders stays available for the picker")
    func sourceLanguagePickedToNilLoadsAllFolders() async {
        let anyFolder = GLICustomFolder(id: folderID, name: "Travel", sourceLanguage: "fr")
        let updated = GLIWordPair(id: wordID, word: "hola", sourceLanguage: nil, targetLanguage: "en")
        let store = makeStore(
            fetchMeanings: { _ in [] },
            updateSource: { _, source in
                #expect(source == nil)
                return updated
            },
            fetchCustomFolders: { [anyFolder] }
        )

        // makeStore()'s default state is already .loading — no observable change here.
        await store.send(.view(.onAppear))
        await store.receive(\.meaningsLoaded) {
            $0.meaningsLoadState = .loaded([])
            $0.draft = GLIWordCardFeature.State.Draft(wordPair: $0.wordPair, meanings: [])
        }
        await store.receive(\.customFoldersLoaded) {
            $0.allCustomFolders = [anyFolder]
        }
        await store.receive(\.membershipLoaded, nil as UUID?)
        #expect(store.state.eligibleCustomFolders == []) // "fr" folder doesn't match default "es" source

        await store.send(.view(.sourceLanguagePicked(nil)))
        await store.receive(\.sourceUpdateSucceeded) {
            $0.wordPair = updated
        }
        await store.receive(\.delegate.updated, updated)
        #expect(store.state.isUnsorted == true)
        #expect(store.state.allCustomFolders == [anyFolder])
    }

    @Test("sourceLanguagePicked with the unchanged source is a no-op")
    func sourceLanguagePickedUnchangedNoOps() async {
        let store = makeStore(
            updateSource: { _, _ in
                Issue.record("updateSource should not be called for an unchanged source")
                return GLIWordPair(id: wordID, word: "hola", sourceLanguage: "es")
            }
        )

        await store.send(.view(.sourceLanguagePicked("es")))
    }

    @Test("customFolderPicked while Unsorted adopts the folder's source; eligibleCustomFolders reflects it afterward")
    func customFolderPickedFromUnsortedAdoptsSource() async {
        var state = makeState(meanings: [])
        state.wordPair.sourceLanguage = nil
        let updated = GLIWordPair(
            id: wordID,
            word: "hola",
            sourceLanguage: "es",
            targetLanguage: "en",
            customFolderID: folderID
        )
        let eligible = GLICustomFolder(id: folderID, name: "Travel", sourceLanguage: "es")
        let store = makeStore(
            initialState: state,
            fetchMeanings: { _ in [] },
            updateCustomFolder: { _, id in
                #expect(id == folderID)
                return updated
            },
            fetchCustomFolders: { [eligible] }
        )

        await store.send(.view(.onAppear)) {
            $0.meaningsLoadState = .loading
        }
        await store.receive(\.meaningsLoaded) {
            $0.meaningsLoadState = .loaded([])
            $0.draft = GLIWordCardFeature.State.Draft(wordPair: $0.wordPair, meanings: [])
        }
        await store.receive(\.customFoldersLoaded) {
            $0.allCustomFolders = [eligible]
        }
        #expect(store.state.eligibleCustomFolders == [])

        await store.send(.view(.customFolderPicked(folderID)))
        await store.receive(\.customFolderUpdateSucceeded) {
            $0.wordPair = updated
        }
        await store.receive(\.delegate.updated, updated)
        #expect(store.state.eligibleCustomFolders == [eligible])
    }

    @Test("customFolderPicked(nil) routes through customFolderCleared and clears membership")
    func customFolderPickedNilClears() async {
        var state = makeState(meanings: [])
        state.wordPair.customFolderID = folderID
        let cleared = GLIWordPair(id: wordID, word: "hola", sourceLanguage: "es", targetLanguage: "en")
        let store = makeStore(
            initialState: state,
            updateCustomFolder: { _, id in
                #expect(id == nil)
                return cleared
            }
        )

        await store.send(.view(.customFolderPicked(nil)))
        await store.receive(\.view.customFolderCleared)
        await store.receive(\.customFolderUpdateSucceeded) {
            $0.wordPair = cleared
        }
        await store.receive(\.delegate.updated, cleared)
    }

    @Test("membership actions are blocked while saving or deleting")
    func membershipBlockedWhileSavingOrDeleting() async {
        var state = makeState(meanings: [])
        state.isDeleting = true
        let store = makeStore(
            initialState: state,
            updateSource: { _, _ in
                Issue.record("updateSource should not be called while deleting")
                return GLIWordPair(id: wordID, word: "hola")
            },
            updateCustomFolder: { _, _ in
                Issue.record("updateCustomFolder should not be called while deleting")
                return GLIWordPair(id: wordID, word: "hola")
            }
        )

        await withExpectedIssue {
            await store.send(.view(.sourceLanguagePicked("fr")))
        }
        await withExpectedIssue {
            await store.send(.view(.customFolderPicked(folderID)))
        }
        await withExpectedIssue {
            await store.send(.view(.customFolderCleared))
        }
    }

    // MARK: - Caps, detection, membership scan

    @Test("word, meaning, and example changes are capped")
    func fieldChangesAreCapped() async {
        let meaning = GLIWordMeaning(text: "")
        var state = makeState(meanings: [])
        state.isEditing = true
        state.draft.meanings = [meaning]
        let store = makeStore(initialState: state)
        let longWord = String(repeating: "w", count: GLICaptureFieldLimits.maxWordLength + 1)
        let longMeaning = String(repeating: "m", count: GLICaptureFieldLimits.maxMeaningLength + 1)
        let longExample = String(repeating: "e", count: GLICaptureFieldLimits.maxExampleLength + 1)

        await store.send(.view(.wordChanged(longWord))) {
            $0.draft.word = String(longWord.prefix(GLICaptureFieldLimits.maxWordLength))
        }
        await store.send(.view(.meaningTextChanged(id: meaning.id, text: longMeaning))) {
            $0.draft.meanings[id: meaning.id]?.text = String(
                longMeaning.prefix(GLICaptureFieldLimits.maxMeaningLength)
            )
            $0.pendingLanguageDetectionID = meaning.id
        }
        await store.receive(\.languageDetectionResponse) {
            $0.pendingLanguageDetectionID = nil
        }
        await store.send(.view(.meaningExampleChanged(id: meaning.id, text: longExample))) {
            $0.draft.meanings[id: meaning.id]?.example = String(
                longExample.prefix(GLICaptureFieldLimits.maxExampleLength)
            )
        }
    }

    @Test("a manual target pick is not overwritten by meaning-language detection")
    func manualTargetBlocksDetectionOverwrite() async {
        let meaning = GLIWordMeaning(text: "")
        var state = makeState(meanings: [])
        state.isEditing = true
        state.draft.meanings = [meaning]
        let store = makeStore(
            initialState: state,
            detectTargetLanguage: { _ in "fr" }
        )

        await store.send(.view(.targetLanguageChanged("de"))) {
            $0.didManuallySetTarget = true
            $0.draft.targetLanguage = "de"
        }
        await store.send(.view(.meaningTextChanged(id: meaning.id, text: "bonjour"))) {
            $0.draft.meanings[id: meaning.id]?.text = "bonjour"
            $0.pendingLanguageDetectionID = meaning.id
        }
        await store.receive(\.languageDetectionResponse) {
            $0.pendingLanguageDetectionID = nil
            $0.draft.meanings[id: meaning.id]?.language = "fr"
        }
        #expect(store.state.draft.targetLanguage == "de")
    }

    @Test("starting detection on another row settles the previous row without changing the card target")
    func switchingRowsSettlesPreviousDetection() async {
        let clock = TestClock()
        let first = GLIWordMeaning(text: "")
        let second = GLIWordMeaning(text: "")
        var state = makeState(meanings: [])
        state.isEditing = true
        state.draft.meanings = [first, second]
        let store = makeStore(
            initialState: state,
            detectTargetLanguage: { text in
                if text.contains("bonjour") { return "fr" }
                if text.contains("hola") { return "es" }
                return nil
            },
            clock: clock
        )

        await store.send(.view(.meaningTextChanged(id: first.id, text: "hola"))) {
            $0.draft.meanings[id: first.id]?.text = "hola"
            $0.pendingLanguageDetectionID = first.id
        }
        await store.send(.view(.meaningTextChanged(id: second.id, text: "bonjour"))) {
            $0.draft.meanings[id: second.id]?.text = "bonjour"
            $0.draft.meanings[id: first.id]?.language = "es"
            $0.pendingLanguageDetectionID = second.id
        }
        await clock.advance(by: .milliseconds(400))
        await store.receive(\.languageDetectionResponse) {
            $0.pendingLanguageDetectionID = nil
            $0.draft.meanings[id: second.id]?.language = "fr"
            $0.draft.targetLanguage = "fr"
        }
    }

    @Test("removing the pending row cancels its detection")
    func removePendingRowCancelsDetection() async {
        let clock = TestClock()
        let meaning = GLIWordMeaning(text: "")
        var state = makeState(meanings: [])
        state.isEditing = true
        state.draft.meanings = [meaning]
        let store = makeStore(
            initialState: state,
            detectTargetLanguage: { _ in "fr" },
            clock: clock
        )

        await store.send(.view(.meaningTextChanged(id: meaning.id, text: "bonjour"))) {
            $0.draft.meanings[id: meaning.id]?.text = "bonjour"
            $0.pendingLanguageDetectionID = meaning.id
        }
        await store.send(.view(.removeMeaningTapped(id: meaning.id))) {
            $0.draft.meanings.remove(id: meaning.id)
            $0.pendingLanguageDetectionID = nil
        }
        await clock.advance(by: .milliseconds(400))
        await store.finish()
    }

    @Test("save trims meaning text and normalizes the example")
    func saveNormalizesMeaningAndExample() async {
        let meaning = GLIWordMeaning(text: "  hello  ", example: "  one  \n\n  two  ")
        let normalized = GLIWordMeaning(id: meaning.id, text: "hello", example: "one\ntwo")
        let replacedMeanings = LockIsolated<[GLIWordMeaning]>([])
        let updated = GLIWordPair(id: wordID, word: "hola", sourceLanguage: "es", targetLanguage: "en")
        var state = makeState(meanings: [])
        state.isEditing = true
        state.draft.meanings = [meaning]
        let store = makeStore(
            initialState: state,
            update: { _ in updated },
            replaceAll: { _, meanings in replacedMeanings.setValue(meanings) }
        )

        await store.send(.view(.saveButtonTapped)) {
            $0.isSaving = true
        }
        await store.receive(\.saveSucceeded) {
            $0.wordPair = updated
            $0.meaningsLoadState = .loaded([normalized])
            $0.draft = GLIWordCardFeature.State.Draft(wordPair: updated, meanings: [normalized])
            $0.isSaving = false
            $0.isEditing = false
            $0.lightHapticTick = 1
        }
        await store.receive(\.delegate.updated, updated)
        #expect(replacedMeanings.value == [normalized])
    }

    @Test("save settles the pending meaning before persist")
    func saveSettlesPendingDetection() async {
        let clock = TestClock()
        let meaning = GLIWordMeaning(text: "")
        let replacedMeanings = LockIsolated<[GLIWordMeaning]>([])
        var state = makeState(meanings: [])
        state.isEditing = true
        state.draft.word = "hola"
        state.draft.meanings = [meaning]
        let store = makeStore(
            initialState: state,
            replaceAll: { _, meanings in replacedMeanings.setValue(meanings) },
            detectTargetLanguage: { _ in "fr" },
            clock: clock
        )

        await store.send(.view(.meaningTextChanged(id: meaning.id, text: "bonjour"))) {
            $0.draft.meanings[id: meaning.id]?.text = "bonjour"
            $0.pendingLanguageDetectionID = meaning.id
        }
        await store.send(.view(.saveButtonTapped)) {
            $0.pendingLanguageDetectionID = nil
            $0.draft.meanings[id: meaning.id]?.language = "fr"
            $0.draft.targetLanguage = "fr"
            $0.isSaving = true
        }
        let stored = GLIWordMeaning(id: meaning.id, text: "bonjour", language: "fr")
        let updated = GLIWordPair(id: wordID, word: "hola", sourceLanguage: "es", targetLanguage: "fr")
        await store.receive(\.saveSucceeded) {
            $0.wordPair = updated
            $0.meaningsLoadState = .loaded([stored])
            $0.draft = GLIWordCardFeature.State.Draft(wordPair: updated, meanings: [stored])
            $0.isSaving = false
            $0.isEditing = false
            $0.lightHapticTick = 1
        }
        await store.receive(\.delegate.updated, updated)
        await clock.advance(by: .milliseconds(400))
        await store.finish()
        #expect(replacedMeanings.value == [stored])
    }

    @Test("failed custom-folder filing on save keeps the draft")
    func saveAssignCustomFolderFailure() async {
        var state = makeState(meanings: [])
        state.isEditing = true
        state.wordPair.customFolderID = folderID
        state.draft.word = "hola"
        let store = makeStore(
            initialState: state,
            assignCustomFolder: { _, _, _ in throw Failure.expected }
        )

        await withExpectedIssue {
            await store.send(.view(.saveButtonTapped)) {
                $0.isSaving = true
            }
            await store.receive(\.saveFailed) {
                $0.isSaving = false
                $0.alert = saveFailureAlert()
            }
        }
        #expect(store.state.isEditing == true)
        #expect(store.state.lightHapticTick == 0)
        #expect(store.state.draft.word == "hola")
    }

    @Test("onAppear with Unsorted clears a stale custom folder id")
    func unsortedOnAppearClearsStaleCustomFolder() async {
        var state = makeState()
        state.wordPair.sourceLanguage = nil
        state.wordPair.customFolderID = folderID
        let store = makeStore(initialState: state)

        await store.send(.view(.onAppear)) {
            $0.wordPair.customFolderID = nil
        }
        await store.receive(\.meaningsLoaded) {
            $0.meaningsLoadState = .loaded([])
            $0.draft = GLIWordCardFeature.State.Draft(wordPair: $0.wordPair, meanings: [])
        }
        await store.receive(\.customFoldersLoaded)
        #expect(store.state.wordPair.customFolderID == nil)
    }

    @Test("onAppear applies membership from the source-matching folder scan")
    func onAppearLoadsMembershipFromScan() async {
        let wordID = wordID
        let folderID = folderID
        let otherID = UUID(uuidString: "00000000-0000-0000-0000-0000000000F2")!
        let matching = GLICustomFolder(id: folderID, name: "Travel", sourceLanguage: "es")
        let other = GLICustomFolder(id: otherID, name: "French", sourceLanguage: "fr")
        let store = makeStore(
            fetchCustomFolders: { [other, matching] },
            fetchWordPairsInCustomFolder: { id in
                guard id == folderID else { return [] }
                return [GLIWordPair(id: wordID, word: "hola", sourceLanguage: "es", targetLanguage: "en")]
            }
        )

        await store.send(.view(.onAppear))
        await store.receive(\.meaningsLoaded) {
            $0.meaningsLoadState = .loaded([])
            $0.draft = GLIWordCardFeature.State.Draft(wordPair: $0.wordPair, meanings: [])
        }
        await store.receive(\.customFoldersLoaded) {
            $0.allCustomFolders = [other, matching]
        }
        await store.receive(\.membershipLoaded, folderID as UUID?) {
            $0.wordPair.customFolderID = folderID
        }
    }

    // MARK: - Helpers

    private func makeState(
        meanings: [GLIWordMeaning]? = nil,
        didFailMeaningsLoad: Bool = false
    ) -> GLIWordCardFeature.State {
        let meaningsLoadState: GLIWordCardFeature.State.MeaningsLoadState
        if didFailMeaningsLoad {
            meaningsLoadState = .failed
        } else if let meanings {
            meaningsLoadState = .loaded(IdentifiedArrayOf(uniqueElements: meanings))
        } else {
            meaningsLoadState = .loading
        }
        return GLIWordCardFeature.State(
            wordPair: GLIWordPair(
                id: wordID,
                word: "hola",
                sourceLanguage: "es",
                targetLanguage: "en"
            ),
            meaningsLoadState: meaningsLoadState
        )
    }

    private func makeStore(
        initialState: GLIWordCardFeature.State? = nil,
        update: @escaping @Sendable (GLIWordCardUpdate) async throws -> GLIWordPair = {
            GLIWordPair(id: $0.wordID, word: $0.word, sourceLanguage: "es", targetLanguage: $0.targetLanguage)
        },
        delete: @escaping @Sendable (UUID) async throws -> Void = { _ in },
        fetchMeanings: @escaping @Sendable (GLIWordPair.ID) async throws -> [GLIWordMeaning] = { _ in [] },
        replaceAll: @escaping @Sendable (GLIWordPair.ID, [GLIWordMeaning]) async throws -> Void = { _, _ in },
        updateSource: @escaping @Sendable (GLIWordPair.ID, String?) async throws -> GLIWordPair = { id, source in
            GLIWordPair(id: id, word: "hola", sourceLanguage: source, targetLanguage: "en")
        },
        updateCustomFolder: @escaping @Sendable (GLIWordPair.ID, UUID?) async throws -> GLIWordPair = { id, folderID in
            GLIWordPair(id: id, word: "hola", sourceLanguage: "es", targetLanguage: "en", customFolderID: folderID)
        },
        fetchCustomFolders: @escaping @Sendable () async throws -> [GLICustomFolder] = { [] },
        fetchWordPairsInCustomFolder: @escaping @Sendable (UUID) async throws -> [GLIWordPair] = { _ in [] },
        assignCustomFolder: @escaping @Sendable (GLIWordPair.ID, UUID?, String?) async throws -> Void = { _, _, _ in },
        detectTargetLanguage: @escaping @Sendable (String) -> String? = { _ in nil },
        clock: any Clock<Duration> & Sendable = ImmediateClock()
    ) -> TestStoreOf<GLIWordCardFeature> {
        TestStore(initialState: initialState ?? makeState()) {
            GLIWordCardFeature()
        } withDependencies: {
            $0.cardMutations = GLICardMutationsClient(update: update, delete: delete)
            $0.wordMeanings = GLIWordMeaningsClient(
                fetch: fetchMeanings,
                replaceAll: replaceAll,
                firstMeanings: { _ in [:] },
                fetchAll: { _ in [:] }
            )
            $0.customFolders = GLICustomFoldersClient(
                fetch: fetchCustomFolders,
                create: { _, _ in throw Failure.expected },
                rename: { _, _ in throw Failure.expected },
                delete: { _ in }
            )
            $0.wordPairs = GLIWordPairsClient(
                fetchWordPairs: { [] },
                fetchWordPairsInCustomFolder: fetchWordPairsInCustomFolder,
                save: { _ in }
            )
            $0.wordPairMembership = GLIWordPairMembershipClient(
                assignCustomFolder: assignCustomFolder,
                updateSource: updateSource,
                updateCustomFolder: updateCustomFolder,
                pruneEmptyLanguageFolders: {}
            )
            $0.targetLanguageDetector = GLITargetLanguageDetectorClient(
                detectTargetLanguage: detectTargetLanguage
            )
            $0.continuousClock = clock
            $0.uuid = .incrementing
        }
    }

    private func saveFailureAlert() -> AlertState<GLIWordCardFeature.Action.Alert> {
        AlertState {
            TextState("Couldn’t save changes")
        } actions: {
            ButtonState(action: .retrySave) {
                TextState("Retry")
            }
            ButtonState(role: .cancel) {
                TextState("Cancel")
            }
        } message: {
            TextState("Your edits are still here.")
        }
    }

    private func deleteConfirmationAlert() -> AlertState<GLIWordCardFeature.Action.Alert> {
        AlertState {
            TextState("Delete this word?")
        } actions: {
            ButtonState(role: .destructive, action: .confirmDelete) {
                TextState("Delete")
            }
            ButtonState(role: .cancel) {
                TextState("Cancel")
            }
        } message: {
            TextState("This action can’t be undone.")
        }
    }

    private func deleteFailureAlert() -> AlertState<GLIWordCardFeature.Action.Alert> {
        AlertState {
            TextState("Couldn’t delete word")
        } actions: {
            ButtonState(role: .destructive, action: .retryDelete) {
                TextState("Retry")
            }
            ButtonState(role: .cancel) {
                TextState("Cancel")
            }
        } message: {
            TextState("The word is still on this card.")
        }
    }
}
