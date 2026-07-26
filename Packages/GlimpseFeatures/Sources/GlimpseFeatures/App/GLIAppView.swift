import ComposableArchitecture
import SwiftUI

public struct GLIAppView: View {
    @Bindable public var store: StoreOf<GLIAppFeature>

    public init(store: StoreOf<GLIAppFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            GLILanguageFoldersView(
                store: store.scope(state: \.languageFolders, action: \.languageFolders)
            )
        } destination: { store in
            switch store.case {
            case let .folderWords(store):
                GLIFolderWordsView(store: store)
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}

#Preview {
    GLIAppView(store: Store(initialState: GLIAppFeature.State()) {
        GLIAppFeature()
    })
}
