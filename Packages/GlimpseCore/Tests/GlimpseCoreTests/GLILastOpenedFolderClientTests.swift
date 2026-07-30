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
}
