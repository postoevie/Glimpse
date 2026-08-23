import Foundation
import SwiftData

public struct GLIWordPairMembershipClient: Sendable {
    /// Sets or clears custom-folder membership at capture time. See `GLIModelActor.assignCustomFolder`.
    public var assignCustomFolder: @Sendable (
        _ wordPairID: GLIWordPair.ID,
        _ customFolderID: UUID?,
        _ wordTargetLanguage: String?
    ) async throws -> Void

    /// Edits item `sourceLanguage`. See `GLIModelActor.updateSource`.
    public var updateSource: @Sendable (
        _ wordPairID: GLIWordPair.ID,
        _ sourceLanguage: String?
    ) async throws -> GLIWordPair

    /// Sets or clears custom-folder membership on the card-edit path. See `GLIModelActor.updateCustomFolder`.
    public var updateCustomFolder: @Sendable (
        _ wordPairID: GLIWordPair.ID,
        _ customFolderID: UUID?
    ) async throws -> GLIWordPair

    /// Deletes empty language folders, including Unsorted. See `GLIModelActor.pruneEmptyLanguageFolders`.
    public var pruneEmptyLanguageFolders: @Sendable () async throws -> Void

    public init(
        assignCustomFolder: @escaping @Sendable (
            _ wordPairID: GLIWordPair.ID,
            _ customFolderID: UUID?,
            _ wordTargetLanguage: String?
        ) async throws -> Void,
        updateSource: @escaping @Sendable (
            _ wordPairID: GLIWordPair.ID,
            _ sourceLanguage: String?
        ) async throws -> GLIWordPair,
        updateCustomFolder: @escaping @Sendable (
            _ wordPairID: GLIWordPair.ID,
            _ customFolderID: UUID?
        ) async throws -> GLIWordPair,
        pruneEmptyLanguageFolders: @escaping @Sendable () async throws -> Void = {}
    ) {
        self.assignCustomFolder = assignCustomFolder
        self.updateSource = updateSource
        self.updateCustomFolder = updateCustomFolder
        self.pruneEmptyLanguageFolders = pruneEmptyLanguageFolders
    }
}

extension GLIWordPairMembershipClient {
    public static func live(container: ModelContainer) -> GLIWordPairMembershipClient {
        live(actor: GLIModelActor(modelContainer: container))
    }

    public static func live(actor: GLIModelActor) -> GLIWordPairMembershipClient {
        GLIWordPairMembershipClient(
            assignCustomFolder: { wordPairID, customFolderID, wordTargetLanguage in
                try await actor.assignCustomFolder(
                    wordPairID: wordPairID,
                    customFolderID: customFolderID,
                    wordTargetLanguage: wordTargetLanguage
                )
            },
            updateSource: { wordPairID, sourceLanguage in
                try await actor.updateSource(wordPairID: wordPairID, sourceLanguage: sourceLanguage)
            },
            updateCustomFolder: { wordPairID, customFolderID in
                try await actor.updateCustomFolder(
                    wordPairID: wordPairID,
                    customFolderID: customFolderID
                )
            },
            pruneEmptyLanguageFolders: {
                try await actor.pruneEmptyLanguageFolders()
            }
        )
    }

    public static func inMemory() throws -> GLIWordPairMembershipClient {
        .live(container: try GLIModelContainerFactory.makeInMemory())
    }
}
