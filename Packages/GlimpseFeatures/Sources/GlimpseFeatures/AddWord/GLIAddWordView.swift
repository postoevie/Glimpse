import SwiftUI
import ComposableArchitecture
import GlimpseCore

public struct GLIAddWordView: View {
    @Bindable public var store: StoreOf<GLIAddWordFeature>

    public init(store: StoreOf<GLIAddWordFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    GLICappedCaptureTextField(
                        "Word",
                        canonical: store.wordPair.word,
                        limit: GLICaptureFieldLimits.maxWordLength,
                        send: { store.send(.wordChanged($0)) }
                    )
                    .textInputAutocapitalization(.sentences)
                    .accessibilityLabel("Word")
                    .safeAreaInset(edge: .bottom, alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            characterCounter(
                                isVisible: showsWordCount,
                                label: wordCountLabel,
                                accessibilityLabel: wordCountAccessibilityLabel
                            )
                            sourceLanguageStatusLabel
                        }
                    }
                }

                Section {
                    GLICappedCaptureTextField(
                        "Meaning",
                        prompt: "Optional",
                        canonical: store.meaningText,
                        limit: GLICaptureFieldLimits.maxMeaningLength,
                        send: { store.send(.meaningTextChanged($0)) }
                    )
                    .textInputAutocapitalization(.sentences)
                    .accessibilityLabel("Meaning")
                    .accessibilityHint("Optional")
                    .safeAreaInset(edge: .bottom, alignment: .leading, spacing: showsMeaningCount ? 8 : 0) {
                        characterCounter(
                            isVisible: showsMeaningCount,
                            label: meaningCountLabel,
                            accessibilityLabel: meaningCountAccessibilityLabel
                        )
                    }
                } header: {
                    Text("Meaning")
                }

                Section {
                    GLICappedCaptureTextField(
                        "Example",
                        prompt: "Optional",
                        canonical: store.draftExampleText,
                        limit: GLICaptureFieldLimits.maxExampleLength,
                        lineRange: 1...8,
                        send: { store.send(.exampleChanged($0)) }
                    )
                    .textInputAutocapitalization(.sentences)
                    .accessibilityLabel("Example")
                    .accessibilityHint("Optional")
                    .safeAreaInset(edge: .bottom, alignment: .leading, spacing: showsExampleCount ? 8 : 0) {
                        characterCounter(
                            isVisible: showsExampleCount,
                            label: exampleCountLabel,
                            accessibilityLabel: exampleCountAccessibilityLabel
                        )
                    }
                } header: {
                    Text("Example")
                }

                Section {
                    Picker(
                        "Custom folder",
                        selection: $store.selectedCustomFolderID.sending(\.customFolderPicked)
                    ) {
                        Text("None")
                            .tag(UUID?.none)
                        ForEach(store.customFolders) { folder in
                            Text(folder.name)
                                .tag(Optional.some(folder.id))
                        }
                    }
                    .accessibilityLabel("Custom folder")
                    .accessibilityValue(selectedCustomFolderAccessibilityValue)

                    if store.selectedCustomFolderID != nil {
                        Button("Clear") {
                            store.send(.customFolderCleared)
                        }
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityLabel("Clear custom folder")
                    }
                } header: {
                    Text("Custom folder")
                }

                Section {
                    Picker(
                        "Source",
                        selection: $store.wordPair.sourceLanguage.sending(\.sourceLanguageChanged)
                    ) {
                        Text("Unsorted")
                            .tag(String?.none)
                        ForEach(languageCodes, id: \.self) { code in
                            Text(displayName(for: code))
                                .tag(Optional.some(code))
                        }
                    }
                    .disabled(store.isSourceLocked)
                    .accessibilityLabel("Source language")
                    .accessibilityHint(
                        "Locked by the selected custom folder",
                        isEnabled: store.isSourceLocked
                    )

                    Picker(
                        "Target",
                        selection: $store.wordPair.targetLanguage.sending(\.targetLanguageChanged)
                    ) {
                        Text("Not set")
                            .tag(String?.none)
                        ForEach(languageCodes, id: \.self) { code in
                            Text(displayName(for: code))
                                .tag(Optional.some(code))
                        }
                    }
                    .accessibilityLabel("Target language")
                } header: {
                    Text("Languages")
                } footer: {
                    if store.isSourceLocked {
                        Text("Source is set by the custom folder and can’t be changed until you clear the folder.")
                    } else {
                        Text("Source updates from the word when possible. Unsorted is used when unknown.")
                    }
                }
            }
            .navigationTitle("Add Word")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        store.send(.cancelButtonTapped)
                    }
                    .disabled(store.isSaving)
                    .frame(minWidth: 44, minHeight: 44)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.doneButtonTapped)
                    } label: {
                        if store.isSaving {
                            ProgressView()
                                .accessibilityLabel("Saving")
                        } else {
                            Text("Done")
                        }
                    }
                    .disabled(!store.canSave)
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
            .task {
                await store.send(.onAppear).finish()
            }
        }
    }

    private var showsWordCount: Bool {
        GLICaptureFieldLimits.maxWordLength - store.wordPair.word.count <= 20
    }

    private var wordCountLabel: String {
        String(localized: "\(store.wordPair.word.count)/\(GLICaptureFieldLimits.maxWordLength)")
    }

    private var wordCountAccessibilityLabel: String {
        String(localized: "\(store.wordPair.word.count) of \(GLICaptureFieldLimits.maxWordLength) characters")
    }

    private var showsMeaningCount: Bool {
        GLICaptureFieldLimits.maxMeaningLength - store.meaningText.count <= 20
    }

    private var meaningCountLabel: String {
        String(localized: "\(store.meaningText.count)/\(GLICaptureFieldLimits.maxMeaningLength)")
    }

    private var meaningCountAccessibilityLabel: String {
        String(localized: "\(store.meaningText.count) of \(GLICaptureFieldLimits.maxMeaningLength) characters")
    }

    private var showsExampleCount: Bool {
        GLICaptureFieldLimits.maxExampleLength - store.draftExampleText.count <= 20
    }

    private var exampleCountLabel: String {
        String(localized: "\(store.draftExampleText.count)/\(GLICaptureFieldLimits.maxExampleLength)")
    }

    private var exampleCountAccessibilityLabel: String {
        String(localized: "\(store.draftExampleText.count) of \(GLICaptureFieldLimits.maxExampleLength) characters")
    }

    /// System languages plus any codes already on the draft (e.g. detection).
    private var languageCodes: [String] {
        var codes = Set(Self.systemLanguageCodes)
        if let source = store.wordPair.sourceLanguage {
            codes.insert(source)
        }
        if let target = store.wordPair.targetLanguage {
            codes.insert(target)
        }
        return codes.sorted()
    }

    private static let systemLanguageCodes: [String] = {
        let codes = Locale.Language.systemLanguages.compactMap { language in
            language.languageCode?.identifier
        }
        return Array(Set(codes)).sorted()
    }()

    private var selectedCustomFolderName: String? {
        guard let id = store.selectedCustomFolderID else { return nil }
        return store.customFolders[id: id]?.name
    }

    private var selectedCustomFolderAccessibilityValue: String {
        selectedCustomFolderName ?? String(localized: "None")
    }

    private func displayName(for code: String) -> String {
        Locale.current.localizedString(forLanguageCode: code) ?? code
    }

    private var sourceLanguageStatusText: String {
        if let code = store.wordPair.sourceLanguage {
            return displayName(for: code)
        }
        return String(localized: "Enter more text or set the language manually.")
    }

    private var sourceLanguageStatusLabel: some View {
        Text(sourceLanguageStatusText)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(sourceLanguageStatusText)
    }

    @ViewBuilder
    private func characterCounter(
        isVisible: Bool,
        label: String,
        accessibilityLabel: String
    ) -> some View {
        if isVisible {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(accessibilityLabel)
        }
    }
}

/// Keeps existing sheet call sites compiling while the view type matches `GLILanguageFoldersView` naming.
public typealias GLIAddWordFeatureView = GLIAddWordView

#Preview {
    GLIAddWordView(
        store: Store(
            initialState: GLIAddWordFeature.State(
                wordPair: GLIWordPair(word: "hola", sourceLanguage: "es", targetLanguage: "es")
            )
        ) {
            GLIAddWordFeature()
        }
    )
}
