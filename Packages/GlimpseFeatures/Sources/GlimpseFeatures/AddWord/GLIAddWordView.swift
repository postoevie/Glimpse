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
                    TextField(
                        "Word",
                        text: $store.wordPair.word.sending(\.wordChanged)
                    )
                    .textInputAutocapitalization(.sentences)
                    .accessibilityLabel("Word")

                    TextField(
                        "Translation",
                        text: $store.wordPair.translation.sending(\.translationChanged),
                        prompt: Text("Optional")
                    )
                    .textInputAutocapitalization(.sentences)
                    .accessibilityLabel("Translation")
                    .accessibilityHint("Optional")
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
                    .accessibilityLabel("Source language")

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
                    Text("Source updates from the word when possible. Unsorted is used when unknown.")
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
                    .frame(minWidth: 44, minHeight: 44)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        store.send(.doneButtonTapped)
                    }
                    .disabled(!store.canSave)
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
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

    private func displayName(for code: String) -> String {
        Locale.current.localizedString(forLanguageCode: code) ?? code
    }
}

/// Keeps existing sheet call sites compiling while the view type matches `GLILanguageFoldersView` naming.
public typealias GLIAddWordFeatureView = GLIAddWordView

#Preview {
    GLIAddWordView(
        store: Store(
            initialState: GLIAddWordFeature.State(
                wordPair: GLIWordPair(word: "hola", translation: "", sourceLanguage: "es", targetLanguage: "es")
            )
        ) {
            GLIAddWordFeature()
        }
    )
}
