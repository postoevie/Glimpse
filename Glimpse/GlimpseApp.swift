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

    private static let modelActor = GLIModelActor(modelContainer: modelContainer)

    static let store = Store(initialState: GLIAppFeature.State()) {
        #if DEBUG
        GLIAppFeature()._printChanges()
        #else
        GLIAppFeature()
        #endif
    } withDependencies: {
        let actor = modelActor
        $0.wordPairs = .live(actor: actor)
        $0.languageFolders = .live(container: modelContainer)
        $0.languageDetector = .live
        $0.wordExamples = .live(actor: actor)
        $0.cardMutations = .live(actor: actor)
        $0.lastOpenedFolder = .live()
        let preferences = GLIPreferencesClient.live()
        $0.preferences = preferences
        $0.customFolders = .live(actor: actor, preferences: preferences)
    }

    var body: some Scene {
        WindowGroup {
            GLIAppView(store: Self.store)
        }
    }
}
