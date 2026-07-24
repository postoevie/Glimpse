import SwiftUI
import GlimpseCore
import GlimpseFeatures
import ComposableArchitecture
import SwiftData

@main
struct GlimpseApp: App {
    private static let modelContainer: ModelContainer = {
        do {
            return try GLIModelContainerFactory.makeLive(groupIdentifier: GLIAppGroup.identifier)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    static let store = Store(initialState: GLIAppFeature.State()) {
        #if DEBUG
        GLIAppFeature()._printChanges()
        #else
        GLIAppFeature()
        #endif
    } withDependencies: {
        $0.wordPairs = .live(container: modelContainer)
        $0.languageFolders = .live(container: modelContainer)
        $0.languageDetector = .live
    }

    var body: some Scene {
        WindowGroup {
            GLIAppView(store: Self.store)
        }
    }
}
