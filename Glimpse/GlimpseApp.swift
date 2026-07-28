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
        $0.wordPairs = GLIWordPairsClient(
            fetchWordPairs: { try await actor.fetchWordPairs() },
            fetchWordPairsInFolder: { folderID in
                try await actor.fetchWordPairs(inFolderID: folderID)
            },
            save: { pair in try await actor.saveWordPair(pair) },
            changes: {
                AsyncStream { continuation in
                    nonisolated(unsafe) let observer = NotificationCenter.default.addObserver(
                        forName: ModelContext.didSave,
                        object: nil,
                        queue: nil
                    ) { _ in
                        continuation.yield(())
                    }
                    continuation.onTermination = { _ in
                        NotificationCenter.default.removeObserver(observer)
                    }
                }
            }
        )
        $0.languageFolders = .live(container: modelContainer)
        $0.languageDetector = .live
        $0.wordExamples = .live(actor: actor)
        $0.cardMutations = .live(actor: actor)
    }

    var body: some Scene {
        WindowGroup {
            GLIAppView(store: Self.store)
        }
    }
}
