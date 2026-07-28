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
                    TextField(
                        "Word",
                        text: Binding(
                            get: { store.draft.word },
                            set: { store.send(.view(.wordChanged($0))) }
                        ),
                        axis: .vertical
                    )
                    .lineLimit(2...6)
                    .textInputAutocapitalization(.sentences)
                    .disabled(store.isSaving || store.isDeleting)
                    .accessibilityLabel("Word")
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

            Section("Translation") {
                if store.isEditing {
                    TextField(
                        "Translation",
                        text: Binding(
                            get: { store.draft.translation },
                            set: { store.send(.view(.translationChanged($0))) }
                        ),
                        prompt: Text("Optional"),
                        axis: .vertical
                    )
                    .lineLimit(2...6)
                    .textInputAutocapitalization(.sentences)
                    .disabled(store.isSaving || store.isDeleting)
                    .accessibilityLabel("Translation")
                    .accessibilityHint("Optional")
                } else if store.wordPair.translation.isEmpty {
                    Text("No translation")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Translation")
                        .accessibilityValue("No translation")
                } else {
                    Text(store.wordPair.translation)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("Translation")
                        .accessibilityValue(Text(store.wordPair.translation))
                }
            }

            Section("Example") {
                if store.isEditing {
                    TextField(
                        "Example",
                        text: Binding(
                            get: { store.draft.example },
                            set: { store.send(.view(.exampleChanged($0))) }
                        ),
                        prompt: Text("Optional"),
                        axis: .vertical
                    )
                    .lineLimit(3...8)
                    .textInputAutocapitalization(.sentences)
                    .disabled(store.isSaving || store.isDeleting)
                    .accessibilityLabel("Example")
                    .accessibilityHint("Optional")
                } else if store.didFailExampleLoad {
                    Text("Couldn't load example")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Example")
                        .accessibilityValue("Couldn't load example")
                } else if let example = store.example {
                    if example.isEmpty {
                        Text("No example")
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Example")
                            .accessibilityValue("No example")
                    } else {
                        Text(example)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("Example")
                            .accessibilityValue(Text(example))
                    }
                } else {
                    HStack {
                        Text("Loading example")
                        Spacer()
                        ProgressView()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Loading example")
                }
            }

            Section {
                LabeledContent(
                    "Source",
                    value: languageName(for: store.wordPair.sourceLanguage)
                )
                .accessibilityLabel("Source language")
                .accessibilityValue(Text(
                    languageName(for: store.wordPair.sourceLanguage)
                ))

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
            } header: {
                Text("Languages")
            } footer: {
                if store.isEditing {
                    Text("Source language and folder stay unchanged.")
                }
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
                    .disabled(
                        store.example == nil
                            || store.didFailExampleLoad
                            || store.isDeleting
                    )
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
        .alert($store.scope(\.alert, action: \.alert))
        .task {
            await store.send(.view(.onAppear)).finish()
        }
    }

    private var languageCodes: [String] {
        var codes = Set(Self.systemLanguageCodes)
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
}
