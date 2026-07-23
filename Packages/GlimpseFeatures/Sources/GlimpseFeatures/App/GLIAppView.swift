import ComposableArchitecture
import SwiftUI

public struct GLIAppView: View {
    @Bindable public var store: StoreOf<GLIAppFeature>

    public init(store: StoreOf<GLIAppFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            GLIWordsFolderFeatureView(
                store: store.scope(state: \.wordsFolder, action: \.wordsFolder)
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
