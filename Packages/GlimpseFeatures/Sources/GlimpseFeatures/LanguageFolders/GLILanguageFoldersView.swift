import SwiftUI
import ComposableArchitecture
import GlimpseCore

public struct GLILanguageFoldersView: View {
    @Bindable public var store: StoreOf<GLILanguageFoldersFeature>

    public init(store: StoreOf<GLILanguageFoldersFeature>) {
        self.store = store
    }

    public var body: some View {
        Group {
            if store.folders.isEmpty {
                ContentUnavailableView {
                    Label("No folders yet", systemImage: "folder")
                } description: {
                    Text("Tap Add to save a word. Folders appear by language.")
                } actions: {
                    Button("Add", systemImage: "plus") {
                        store.send(.addButtonTapped)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(minWidth: 44, minHeight: 44)
                }
            } else {
                List {
                    ForEach(store.folders) { folder in
                        Text(displayName(for: folder))
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 2)
                            .accessibilityLabel(displayName(for: folder))
                    }
                }
            }
        }
        .navigationTitle("Folders")
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

    private func displayName(for folder: GLILanguageFolder) -> String {
        if folder.isUnsorted {
            return "Unsorted"
        }
        return Locale.current.localizedString(forLanguageCode: folder.languageCode)
            ?? folder.languageCode
    }
}

#Preview {
    NavigationStack {
        GLILanguageFoldersView(
            store: Store(
                initialState: GLILanguageFoldersFeature.State(
                    folders: [
                        GLILanguageFolder(languageCode: "es"),
                        GLILanguageFolder(languageCode: "fr"),
                        GLILanguageFolder(languageCode: GLILanguageFolder.unsortedCode),
                    ]
                )
            ) {
                GLILanguageFoldersFeature()
            }
        )
    }
}
