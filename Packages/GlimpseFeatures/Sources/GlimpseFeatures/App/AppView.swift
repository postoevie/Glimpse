import ComposableArchitecture
import SwiftUI

public struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            List {
                ContentUnavailableView(
                    "Folders",
                    systemImage: "folder",
                    description: Text("Language and custom folders appear here in I1.")
                )
            }
            .navigationTitle("Glimpse")
            .searchable(
                text: Binding(
                    get: { store.searchText },
                    set: { store.send(.searchTextChanged($0)) }
                ),
                prompt: "Search vocabulary"
            )
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.addButtonTapped)
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}
