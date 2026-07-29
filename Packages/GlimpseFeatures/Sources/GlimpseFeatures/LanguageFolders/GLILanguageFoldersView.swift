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
            if !store.hasCompletedInitialLoad {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.folders.isEmpty && store.customFolders.isEmpty {
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
                    if !store.folders.isEmpty {
                        Section {
                            ForEach(store.folders) { folder in
                                languageFolderRow(folder)
                            }
                        }
                    }

                    if !store.customFolders.isEmpty {
                        Section("Custom") {
                            ForEach(store.customFolders) { folder in
                                customFolderRow(folder)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Folders")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    store.send(.newFolderButtonTapped)
                } label: {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("New Folder")
            }
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
        .sheet(item: $store.scope(\.folderForm, action: \.folderForm)) { store in
            FolderFormSheet(store: store)
        }
        .alert($store.scope(\.alert, action: \.alert))
        .task {
            await store.send(.onAppear).finish()
        }
    }

    private func languageFolderRow(_ folder: GLILanguageFolder) -> some View {
        Button {
            store.send(.folderTapped(folder.id))
        } label: {
            Text(displayName(for: folder))
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .accessibilityLabel(displayName(for: folder))
    }

    private func customFolderRow(_ folder: GLICustomFolder) -> some View {
        Button {
            store.send(.customFolderTapped(folder.id))
        } label: {
            Text(folder.name)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .accessibilityLabel(folder.name)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                store.send(.deleteCustomFolderTapped(folder.id))
            } label: {
                Label("Delete", systemImage: "trash")
            }
            Button {
                store.send(.renameCustomFolderTapped(folder.id))
            } label: {
                Label("Rename", systemImage: "pencil")
            }
        }
        .contextMenu {
            Button("Rename", systemImage: "pencil") {
                store.send(.renameCustomFolderTapped(folder.id))
            }
            Button("Delete", systemImage: "trash", role: .destructive) {
                store.send(.deleteCustomFolderTapped(folder.id))
            }
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

private struct FolderFormSheet: View {
    @Bindable var store: StoreOf<GLIFolderFormFeature>

    var body: some View {
        NavigationStack {
            Form {
                TextField(
                    "Name",
                    text: $store.name.sending(\.nameChanged)
                )
                .textInputAutocapitalization(.sentences)
                .accessibilityLabel("Folder name")
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
                    ],
                    customFolders: [
                        GLICustomFolder(name: "Travel"),
                    ],
                    hasCompletedInitialLoad: true
                )
            ) {
                GLILanguageFoldersFeature()
            }
        )
    }
}
