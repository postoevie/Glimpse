import Foundation
import GlimpseCore
import IssueReporting
import Testing

@Suite("GLILastOpenedFolder")
struct GLILastOpenedFolderTests {
    @Test("persistedString uses language and custom prefixes")
    func persistedStringPrefixes() {
        let languageID = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!
        let customID = UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!

        #expect(GLILastOpenedFolder.language(languageID).persistedString == "language:\(languageID.uuidString)")
        #expect(GLILastOpenedFolder.custom(customID).persistedString == "custom:\(customID.uuidString)")
    }

    @Test("persistedString round-trips through init")
    func persistedStringRoundTrip() {
        let languageID = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!
        let customID = UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!
        let language = GLILastOpenedFolder.language(languageID)
        let custom = GLILastOpenedFolder.custom(customID)

        #expect(GLILastOpenedFolder(persistedString: language.persistedString) == language)
        #expect(GLILastOpenedFolder(persistedString: custom.persistedString) == custom)
    }

    @Test("Codable single-value string round-trip")
    func codableRoundTrip() throws {
        let folderID = UUID(uuidString: "00000000-0000-0000-0000-0000000000D1")!
        let original = GLILastOpenedFolder.custom(folderID)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GLILastOpenedFolder.self, from: data)

        #expect(decoded == original)
        #expect(String(data: data, encoding: .utf8) == "\"custom:\(folderID.uuidString)\"")
    }

    @Test("malformed persisted string is nil")
    func malformedPersistedStringIsNil() {
        let bareUUID = UUID(uuidString: "00000000-0000-0000-0000-0000000000C1")!.uuidString
        #expect(GLILastOpenedFolder(persistedString: "not-a-uuid") == nil)
        #expect(GLILastOpenedFolder(persistedString: "language:not-a-uuid") == nil)
        #expect(GLILastOpenedFolder(persistedString: "custom:") == nil)
        #expect(GLILastOpenedFolder(persistedString: bareUUID) == nil)
    }
}

@Suite("GLILastOpenedFolderClient")
struct GLILastOpenedFolderClientTests {
    @Test("missing value loads as root")
    func missingValueIsRoot() {
        let client = GLILastOpenedFolderClient.inMemory()
        #expect(client.load() == nil)
    }

    @Test("save and load round-trip a language folder")
    func saveLoadRoundTripLanguage() {
        let folderID = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!
        let client = GLILastOpenedFolderClient.inMemory()

        client.save(.language(folderID))

        #expect(client.load() == .language(folderID))
    }

    @Test("save and load round-trip a custom folder")
    func saveLoadRoundTripCustom() {
        let folderID = UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!
        let client = GLILastOpenedFolderClient.inMemory()

        client.save(.custom(folderID))

        #expect(client.load() == .custom(folderID))
    }

    @Test("clear returns root on the next load")
    func clearReturnsRoot() {
        let folderID = UUID(uuidString: "00000000-0000-0000-0000-0000000000A2")!
        let client = GLILastOpenedFolderClient.inMemory(initial: .language(folderID))

        client.clearToRoot()

        #expect(client.load() == nil)
    }

    @Test("malformed stored value is discarded and loads as root")
    func malformedValueIsDiscarded() {
        let suiteName = "test.lastOpenedFolder.\(UUID())"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.set("not-a-uuid", forKey: GLILastOpenedFolderClient.storageKey)
        let client = GLILastOpenedFolderClient.live(suiteName: suiteName)

        withExpectedIssue("Malformed last-opened folder; clearing to root") {
            #expect(client.load() == nil)
        }
        #expect(defaults.object(forKey: GLILastOpenedFolderClient.storageKey) == nil)
    }

    @Test("bare UUID stored value is discarded and loads as root")
    func bareUUIDValueIsDiscarded() {
        let folderID = UUID(uuidString: "00000000-0000-0000-0000-0000000000C1")!
        let suiteName = "test.lastOpenedFolder.\(UUID())"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.set(folderID.uuidString, forKey: GLILastOpenedFolderClient.storageKey)
        let client = GLILastOpenedFolderClient.live(suiteName: suiteName)

        withExpectedIssue("Malformed last-opened folder; clearing to root") {
            #expect(client.load() == nil)
        }
        #expect(defaults.object(forKey: GLILastOpenedFolderClient.storageKey) == nil)
    }

    @Test("prefixed custom value loads without rewriting")
    func prefixedCustomLoads() {
        let folderID = UUID(uuidString: "00000000-0000-0000-0000-0000000000D1")!
        let suiteName = "test.lastOpenedFolder.\(UUID())"
        let defaults = UserDefaults(suiteName: suiteName)!
        let stored = "custom:\(folderID.uuidString)"
        defaults.set(stored, forKey: GLILastOpenedFolderClient.storageKey)
        let client = GLILastOpenedFolderClient.live(suiteName: suiteName)

        #expect(client.load() == .custom(folderID))
        #expect(defaults.string(forKey: GLILastOpenedFolderClient.storageKey) == stored)
    }

    @Test("loadClearingIfFolderMissing returns nil when nothing is persisted")
    func loadClearingWhenNothingPersisted() async {
        let client = GLILastOpenedFolderClient.inMemory()

        let destination = await client.loadClearingIfFolderMissing(
            fetchLanguageFolder: { _ in
                Issue.record("language fetch should not run when nothing is persisted")
                return nil
            },
            fetchCustomFolder: { _ in
                Issue.record("custom fetch should not run when nothing is persisted")
                return nil
            }
        )

        #expect(destination == nil)
        #expect(client.load() == nil)
    }

    @Test("loadClearingIfFolderMissing returns language destination when folder exists")
    func loadClearingKeepsExistingLanguageFolder() async {
        let folderID = UUID(uuidString: "00000000-0000-0000-0000-0000000000E1")!
        let client = GLILastOpenedFolderClient.inMemory(initial: .language(folderID))

        let destination = await client.loadClearingIfFolderMissing(
            fetchLanguageFolder: { id in
                guard id == folderID else { return nil }
                return GLILanguageFolder(id: folderID, languageCode: "es")
            },
            fetchCustomFolder: { _ in
                Issue.record("custom fetch should not run for language destination")
                return nil
            }
        )

        #expect(destination == .language(folderID))
        #expect(client.load() == .language(folderID))
    }

    @Test("loadClearingIfFolderMissing returns custom destination when folder exists")
    func loadClearingKeepsExistingCustomFolder() async {
        let folderID = UUID(uuidString: "00000000-0000-0000-0000-0000000000E2")!
        let client = GLILastOpenedFolderClient.inMemory(initial: .custom(folderID))

        let destination = await client.loadClearingIfFolderMissing(
            fetchLanguageFolder: { _ in
                Issue.record("language fetch should not run for custom destination")
                return nil
            },
            fetchCustomFolder: { id in
                guard id == folderID else { return nil }
                return GLICustomFolder(id: folderID, name: "Travel", sourceLanguage: "es")
            }
        )

        #expect(destination == .custom(folderID))
        #expect(client.load() == .custom(folderID))
    }

    @Test("loadClearingIfFolderMissing clears when language folder is missing")
    func loadClearingClearsMissingLanguageFolder() async {
        let folderID = UUID(uuidString: "00000000-0000-0000-0000-0000000000E3")!
        let client = GLILastOpenedFolderClient.inMemory(initial: .language(folderID))

        let destination = await client.loadClearingIfFolderMissing(
            fetchLanguageFolder: { _ in nil },
            fetchCustomFolder: { _ in
                Issue.record("custom fetch should not run for language destination")
                return nil
            }
        )

        #expect(destination == nil)
        #expect(client.load() == nil)
    }

    @Test("loadClearingIfFolderMissing clears when custom folder is missing")
    func loadClearingClearsMissingCustomFolder() async {
        let folderID = UUID(uuidString: "00000000-0000-0000-0000-0000000000E4")!
        let client = GLILastOpenedFolderClient.inMemory(initial: .custom(folderID))

        let destination = await client.loadClearingIfFolderMissing(
            fetchLanguageFolder: { _ in
                Issue.record("language fetch should not run for custom destination")
                return nil
            },
            fetchCustomFolder: { _ in nil }
        )

        #expect(destination == nil)
        #expect(client.load() == nil)
    }

    @Test("loadClearingIfFolderMissing clears when fetch throws")
    func loadClearingClearsWhenFetchThrows() async {
        let folderID = UUID(uuidString: "00000000-0000-0000-0000-0000000000E5")!
        let client = GLILastOpenedFolderClient.inMemory(initial: .language(folderID))

        struct StubError: Error {}

        let destination = await client.loadClearingIfFolderMissing(
            fetchLanguageFolder: { _ in throw StubError() },
            fetchCustomFolder: { _ in nil }
        )

        #expect(destination == nil)
        #expect(client.load() == nil)
    }
}
