import ComposableArchitecture
import Foundation
import GlimpseCore
import SwiftUI

public struct GLIWordCardView: View {
    @Bindable public var store: StoreOf<GLIWordCardFeature>

    public init(store: StoreOf<GLIWordCardFeature>) {
        self.store = store
    }

    public var body: some View {
        List {
            Section("Word") {
                if store.isEditing {
                    let wordCounter = FieldCounter(
                        count: store.draft.word.count,
                        limit: GLICaptureFieldLimits.maxWordLength
                    )
                    GLICappedCaptureTextField(
                        "Word",
                        canonical: store.draft.word,
                        limit: GLICaptureFieldLimits.maxWordLength,
                        lineRange: 1...8,
                        send: { store.send(.view(.wordChanged($0))) }
                    )
                    .textInputAutocapitalization(.sentences)
                    .disabled(store.isSaving || store.isDeleting)
                    .accessibilityLabel("Word")
                    .safeAreaInset(edge: .bottom, alignment: .leading, spacing: wordCounter.isVisible ? 8 : 0) {
                        characterCounter(
                            isVisible: wordCounter.isVisible,
                            label: wordCounter.label,
                            accessibilityLabel: wordCounter.accessibilityLabel
                        )
                    }
                } else {
                    Text(store.wordPair.word)
                        .font(.title2.bold())
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("Word")
                        .accessibilityValue(Text(store.wordPair.word))
                }
            }

            meaningsSection

            Section {
                membershipSourceRow
                if store.isEditing {
                    Picker(
                        "Target",
                        selection: Binding(
                            get: { store.draft.targetLanguage },
                            set: { store.send(.view(.targetLanguageChanged($0))) }
                        )
                    ) {
                        Text("Not set")
                            .tag(String?.none)
                        ForEach(languageCodes, id: \.self) { code in
                            Text(languageName(for: code))
                                .tag(Optional.some(code))
                        }
                    }
                    .disabled(store.isSaving || store.isDeleting)
                    .accessibilityLabel("Target language")
                } else {
                    LabeledContent(
                        "Target",
                        value: languageName(for: store.wordPair.targetLanguage)
                    )
                    .accessibilityLabel("Target language")
                    .accessibilityValue(Text(
                        languageName(for: store.wordPair.targetLanguage)
                    ))
                }
                membershipCustomFolderRow
            } header: {
                Text("Languages & folder")
            }

            Section {
                if store.isDeleting {
                    HStack {
                        Text("Deleting")
                        Spacer()
                        ProgressView()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Deleting word")
                } else {
                    Button("Delete Word", role: .destructive) {
                        store.send(.view(.deleteButtonTapped))
                    }
                    .disabled(store.isSaving)
                    .frame(minHeight: 44)
                    .accessibilityHint("Asks for confirmation")
                }
            }
        }
        .navigationTitle("Word card")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if store.isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        store.send(.view(.cancelButtonTapped))
                    }
                    .disabled(store.isSaving || store.isDeleting)
                    .frame(minWidth: 44, minHeight: 44)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.view(.saveButtonTapped))
                    } label: {
                        if store.isSaving {
                            ProgressView()
                                .accessibilityLabel("Saving changes")
                        } else {
                            Text("Done")
                        }
                    }
                    .disabled(!store.canSave)
                    .frame(minWidth: 44, minHeight: 44)
                }
            } else {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        store.send(.view(.editButtonTapped))
                    }
                    .disabled(!store.canEdit)
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
        .alert($store.scope(\.alert, action: \.alert))
        .task {
            await store.send(.view(.onAppear)).finish()
        }
        .sensoryFeedback(.impact(weight: .light), trigger: store.lightHapticTick)
    }

    // MARK: - Meanings

    @ViewBuilder
    private var meaningsSection: some View {
        Section {
            if store.isEditing {
                ForEach(store.draft.meanings) { meaning in
                    meaningEditRow(meaning)
                }
                .onDelete { offsets in
                    for index in offsets {
                        store.send(.view(.removeMeaningTapped(id: store.draft.meanings[index].id)))
                    }
                }

                if !store.isAtMeaningCap {
                    Button("Add Meaning", systemImage: "plus") {
                        store.send(.view(.addMeaningTapped))
                    }
                    .frame(minHeight: 44)
                }
            } else {
                switch store.meaningsLoadState {
                case .loading:
                    HStack {
                        Text("Loading meanings")
                        Spacer()
                        ProgressView()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Loading meanings")
                case .failed:
                    Text("Couldn’t load meanings")
                        .foregroundStyle(.secondary)
                case let .loaded(meanings) where meanings.isEmpty:
                    Text("No meanings")
                        .foregroundStyle(.secondary)
                case let .loaded(meanings):
                    ForEach(meanings) { meaning in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(meaning.text)
                                .fixedSize(horizontal: false, vertical: true)
                            if let language = meaning.language, !language.isEmpty {
                                Text(languageName(for: language))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            if !meaning.example.isEmpty {
                                Text(meaning.example)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        } header: {
            Text("Meanings")
        }
    }

    @ViewBuilder
    private func meaningEditRow(_ meaning: GLIWordMeaning) -> some View {
        let textCounter = FieldCounter(
            count: meaning.text.count,
            limit: GLICaptureFieldLimits.maxMeaningLength
        )
        let exampleCounter = FieldCounter(
            count: meaning.example.count,
            limit: GLICaptureFieldLimits.maxExampleLength
        )

        VStack(alignment: .leading, spacing: 4) {
            GLICappedCaptureTextField(
                "Meaning",
                canonical: meaning.text,
                limit: GLICaptureFieldLimits.maxMeaningLength,
                lineRange: 1...8,
                send: { store.send(.view(.meaningTextChanged(id: meaning.id, text: $0))) }
            )
            .textInputAutocapitalization(.sentences)
            .disabled(store.isSaving || store.isDeleting)
            .accessibilityLabel("Meaning")
            .accessibilityHint("Optional")
            .safeAreaInset(edge: .bottom, alignment: .leading, spacing: textCounter.isVisible ? 8 : 0) {
                characterCounter(
                    isVisible: textCounter.isVisible,
                    label: textCounter.label,
                    accessibilityLabel: textCounter.accessibilityLabel
                )
            }

            GLICappedCaptureTextField(
                "Example",
                canonical: meaning.example,
                limit: GLICaptureFieldLimits.maxExampleLength,
                lineRange: 1...8,
                animatesCanonicalChange: true,
                send: { store.send(.view(.meaningExampleChanged(id: meaning.id, text: $0))) }
            )
            .textInputAutocapitalization(.sentences)
            .disabled(store.isSaving || store.isDeleting)
            .accessibilityLabel("Example")
            .accessibilityHint("Optional")
            .safeAreaInset(edge: .bottom, alignment: .leading, spacing: exampleCounter.isVisible ? 8 : 0) {
                characterCounter(
                    isVisible: exampleCounter.isVisible,
                    label: exampleCounter.label,
                    accessibilityLabel: exampleCounter.accessibilityLabel
                )
            }
            .padding(.leading, 16)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Membership

    @ViewBuilder
    private var membershipSourceRow: some View {
        if store.isSaving || store.isDeleting {
            LabeledContent(
                "Source",
                value: languageName(for: store.wordPair.sourceLanguage)
            )
        } else {
            Picker(
                "Source",
                selection: Binding(
                    get: { store.wordPair.sourceLanguage },
                    set: { store.send(.view(.sourceLanguagePicked($0))) }
                )
            ) {
                Text("Not set")
                    .tag(String?.none)
                ForEach(languageCodes, id: \.self) { code in
                    Text(languageName(for: code))
                        .tag(Optional.some(code))
                }
            }
            .accessibilityLabel("Source language")
        }
    }

    @ViewBuilder
    private var membershipCustomFolderRow: some View {
        let folders = store.isUnsorted ? store.allCustomFolders : store.eligibleCustomFolders
        if store.isSaving || store.isDeleting {
            LabeledContent(
                "Custom folder",
                value: customFolderName(for: store.wordPair.customFolderID, in: folders)
            )
        } else {
            Picker(
                "Custom folder",
                selection: Binding(
                    get: { store.wordPair.customFolderID },
                    set: { store.send(.view(.customFolderPicked($0))) }
                )
            ) {
                Text("None")
                    .tag(UUID?.none)
                ForEach(folders) { folder in
                    Text(folder.name)
                        .tag(Optional.some(folder.id))
                }
            }
            .accessibilityLabel("Custom folder")
        }
    }

    private func customFolderName(
        for id: UUID?,
        in folders: IdentifiedArrayOf<GLICustomFolder>
    ) -> String {
        guard let id, let folder = folders[id: id] else {
            return "None"
        }
        return folder.name
    }

    private var languageCodes: [String] {
        var codes = Set(Self.systemLanguageCodes)
        if let sourceLanguage = store.wordPair.sourceLanguage {
            codes.insert(sourceLanguage)
        }
        if let targetLanguage = store.draft.targetLanguage {
            codes.insert(targetLanguage)
        }
        return codes.sorted()
    }

    private static let systemLanguageCodes: [String] = {
        let codes = Locale.Language.systemLanguages.compactMap { language in
            language.languageCode?.identifier
        }
        return Array(Set(codes)).sorted()
    }()

    private func languageName(for code: String?) -> String {
        guard let code, !code.isEmpty else {
            return "Unknown"
        }
        return Locale.current.localizedString(forLanguageCode: code) ?? code
    }

    private func characterCounter(
        isVisible: Bool,
        label: String,
        accessibilityLabel: String
    ) -> some View {
        Text(label)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(accessibilityLabel)
            .opacity(isVisible ? 1 : 0)
            .accessibilityHidden(!isVisible)
            .frame(height: isVisible ? nil : 0)
            .clipped()
    }
}

/// Near-limit caption: visible when 20 or fewer characters remain. Same copy as Grab’s card.
private struct FieldCounter {
    var isVisible: Bool
    var label: String
    var accessibilityLabel: String

    init(count: Int, limit: Int) {
        isVisible = limit - count <= 20
        label = String(localized: "\(count)/\(limit)")
        accessibilityLabel = String(localized: "\(count) of \(limit) characters")
    }
}

#Preview {
    NavigationStack {
        GLIWordCardView(
            store: Store(
                initialState: GLIWordCardFeature.State(
                    wordPair: GLIWordPair(word: "hola", sourceLanguage: "es", targetLanguage: "en"),
                    meaningsLoadState: .loaded([GLIWordMeaning(text: "hello", example: "¡Hola! ¿Cómo estás?")])
                )
            ) {
                GLIWordCardFeature()
            }
        )
    }
}
