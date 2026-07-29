import Foundation
import GlimpseCore
import IssueReporting
import Testing

@Suite("GLILastOpenedFolderClient")
struct GLILastOpenedFolderClientTests {
    @Test("missing value loads as root")
    func missingValueIsRoot() {
        let client = GLILastOpenedFolderClient.inMemory()
        #expect(client.load() == nil)
    }

    @Test("save and load round-trip a folder ID")
    func saveLoadRoundTrip() {
        let folderID = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!
        let client = GLILastOpenedFolderClient.inMemory()

        client.saveFolder(folderID)

        #expect(client.load() == folderID)
    }

    @Test("clear returns root on the next load")
    func clearReturnsRoot() {
        let folderID = UUID(uuidString: "00000000-0000-0000-0000-0000000000A2")!
        let client = GLILastOpenedFolderClient.inMemory(initialFolderID: folderID)

        client.clearToRoot()

        #expect(client.load() == nil)
    }

    @Test("malformed stored value is discarded and loads as root")
    func malformedValueIsDiscarded() {
        let suiteName = "test.lastOpenedFolder.\(UUID())"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.set("not-a-uuid", forKey: GLILastOpenedFolderClient.storageKey)
        let client = GLILastOpenedFolderClient.live(suiteName: suiteName)

        withExpectedIssue("Malformed last-opened folder ID; clearing to root") {
            #expect(client.load() == nil)
        }
        #expect(defaults.object(forKey: GLILastOpenedFolderClient.storageKey) == nil)
    }
}
