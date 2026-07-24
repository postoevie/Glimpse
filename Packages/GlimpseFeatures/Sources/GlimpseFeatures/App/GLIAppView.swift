import ComposableArchitecture
import SwiftUI

public struct GLIAppView: View {
    @Bindable public var store: StoreOf<GLIAppFeature>

    public init(store: StoreOf<GLIAppFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            GLILanguageFoldersView(
                store: store.scope(state: \.languageFolders, action: \.languageFolders)
            )
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
