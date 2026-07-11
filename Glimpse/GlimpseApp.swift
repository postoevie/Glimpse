import SwiftUI
import GlimpseFeatures
import ComposableArchitecture

@main
struct GlimpseApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(
                store: Store(initialState: AppFeature.State()) {
                    AppFeature()
                }
            )
        }
    }
}
