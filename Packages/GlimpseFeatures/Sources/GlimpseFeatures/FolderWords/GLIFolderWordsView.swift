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
            if store.words.isEmpty {
                ContentUnavailableView {
                    Label("No words yet", systemImage: "text.book.closed")
                } description: {
                    Text("Words you save in this folder will appear here.")
                } actions: {
                    Button("Add", systemImage: "plus") {
                        store.send(.addButtonTapped)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(minWidth: 44, minHeight: 44)
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
        .sheet(item: $store.scope(\.addWord, action: \.addWord)) { store in
            GLIAddWordView(store: store)
        }
        .task {
            await store.send(.onAppear).finish()
        }
    }

    private var folderTitle: String {
        if store.languageCode == GLILanguageFolder.unsortedCode {
            return "Unsorted"
        }
        return Locale.current.localizedString(forLanguageCode: store.languageCode)
            ?? store.languageCode
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
                    languageCode: "es",
                    words: [
                        GLIWordPair(word: "hola", translation: "hello", sourceLanguage: "es"),
                        GLIWordPair(word: "gracias", translation: "", sourceLanguage: "es"),
                    ]
                )
            ) {
                GLIFolderWordsFeature()
            }
        )
    }
}
