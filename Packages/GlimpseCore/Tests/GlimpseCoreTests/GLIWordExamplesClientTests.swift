import Foundation
import SwiftData
import Testing
@testable import GlimpseCore

@Suite("GLIWordExamplesClient")
struct GLIWordExamplesClientTests {

    @Test("fetchExample on missing sidecar returns empty string")
    func fetchExampleMissingReturnsEmpty() async throws {
        let client = try GLIWordExamplesClient.inMemory()
        let wordID = UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!

        let example = try await client.fetchExample(wordID)
        #expect(example.isEmpty)
    }

    @Test("fetchExample returns text after insert")
    func fetchExampleAfterInsert() async throws {
        let container = try GLIModelContainerFactory.makeInMemory()
        let wordID = UUID(uuidString: "00000000-0000-0000-0000-0000000000BB")!
        let context = ModelContext(container)
        context.insert(GLIWordExampleEntity(wordID: wordID, text: "¡Hola!"))
        try context.save()

        let client = GLIWordExamplesClient.live(container: container)
        let example = try await client.fetchExample(wordID)
        #expect(example == "¡Hola!")
    }
}
