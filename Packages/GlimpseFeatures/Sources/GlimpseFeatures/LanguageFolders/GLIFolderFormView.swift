import SwiftUI
import ComposableArchitecture
import GlimpseCore

/// Create (name + source language) / rename (name only) sheet for custom folders.
public struct GLIFolderFormView: View {
    @Bindable public var store: StoreOf<GLIFolderFormFeature>

    public init(store: StoreOf<GLIFolderFormFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        "Name",
                        text: $store.name.sending(\.nameChanged)
                    )
                    .textInputAutocapitalization(.sentences)
                    .accessibilityLabel("Folder name")
                }

                if store.showsSourceLanguagePicker {
                    Section {
                        Picker(
                            "Source",
                            selection: $store.sourceLanguage.sending(\.sourceLanguageChanged)
                        ) {
                            Text("Select")
                                .tag(String?.none)
                            ForEach(languageCodes, id: \.self) { code in
                                Text(displayName(for: code))
                                    .tag(Optional.some(code))
                            }
                        }
                        .accessibilityLabel("Source language")
                    } header: {
                        Text("Language")
                    } footer: {
                        Text("Source language is set when you create the folder and cannot be changed later.")
                    }
                }
            }
            .navigationTitle(store.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        store.send(.cancelButtonTapped)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        store.send(.saveButtonTapped)
                    }
                    .disabled(!store.canSave)
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
    }

    private var languageCodes: [String] {
        var codes = GLILanguageCodes.systemCodes
        if let source = store.sourceLanguage {
            codes.insert(source)
        }
        return codes.sorted()
    }

    private func displayName(for code: String) -> String {
        Locale.current.localizedString(forLanguageCode: code) ?? code
    }
}
