import SwiftUI
import ComposableArchitecture
import GlimpseCore

public struct GLIFolderWordsView: View {
    @Bindable public var store: StoreOf<GLIFolderWordsFeature>

    public init(store: StoreOf<GLIFolderWordsFeature>) {
        self.store = store
    }

    public var body: some View {
        Group {
            if !store.hasCompletedInitialLoad {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.words.isEmpty {
                ContentUnavailableView {
                    Label("No words yet", systemImage: "text.book.closed")
                } description: {
                    Text("Words you save in this folder will appear here.")
                } actions: {
                    if !store.identity.isCustom {
                        Button("Add", systemImage: "plus") {
                            store.send(.addButtonTapped)
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(minWidth: 44, minHeight: 44)
                    }
                }
            } else {
                List {
                    ForEach(store.words) { word in
                        Button {
                            store.send(.wordTapped(word.id))
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(word.word)
                                    .font(.body)
                                    .foregroundStyle(.primary)

                                if !word.translation.isEmpty {
                                    Text(word.translation)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .frame(minHeight: 44)
                        .accessibilityLabel(accessibilityLabel(for: word))
                    }
                }
            }
        }
        .navigationTitle(folderTitle)
        .toolbar {
            if !store.identity.isCustom {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.addButtonTapped)
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Add")
                }
            }
            if store.identity.isCustom {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Rename", systemImage: "pencil") {
                            store.send(.renameButtonTapped)
                        }
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            store.send(.deleteButtonTapped)
                        }
                    } label: {
                        Label("Folder Actions", systemImage: "ellipsis.circle")
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Folder Actions")
                }
            }
        }
        .sheet(item: $store.scope(\.addWord, action: \.addWord)) { store in
            GLIAddWordView(store: store)
        }
        .sheet(item: $store.scope(\.folderForm, action: \.folderForm)) { store in
            GLIFolderFormView(store: store)
        }
        .alert($store.scope(\.alert, action: \.alert))
        .task {
            await store.send(.onAppear).finish()
        }
    }

    private var folderTitle: String {
        if let name = store.customFolderName {
            return name
        }
        guard let languageCode = store.languageCode else {
            return ""
        }
        if languageCode == GLILanguageFolder.unsortedCode {
            return "Unsorted"
        }
        return Locale.current.localizedString(forLanguageCode: languageCode)
            ?? languageCode
    }

    private func accessibilityLabel(for word: GLIWordPair) -> String {
        if word.translation.isEmpty {
            return word.word
        }
        return "\(word.word), \(word.translation)"
    }
}

#Preview {
    NavigationStack {
        GLIFolderWordsView(
            store: Store(
                initialState: GLIFolderWordsFeature.State(
                    id: UUID(),
                    words: [
                        GLIWordPair(word: "hola", translation: "hello", sourceLanguage: "es"),
                        GLIWordPair(word: "gracias", translation: "", sourceLanguage: "es"),
                    ],
                    languageCode: "es",
                    hasCompletedInitialLoad: true
                )
            ) {
                GLIFolderWordsFeature()
            }
        )
    }
}
