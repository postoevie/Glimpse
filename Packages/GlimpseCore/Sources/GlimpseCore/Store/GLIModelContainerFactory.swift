import Foundation
import SwiftData

public enum GLIModelContainerFactory {
    public static var schema: Schema {
        Schema([GLIWordPairEntity.self])
    }

    /// Persistent store in the App Group (shared with widget / Share later).
    public static func makeLive(groupIdentifier: String) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(groupIdentifier)
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// Ephemeral store for tests and previews.
    public static func makeInMemory() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
