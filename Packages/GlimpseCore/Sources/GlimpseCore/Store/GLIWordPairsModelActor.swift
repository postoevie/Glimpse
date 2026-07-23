import Foundation
import SwiftData

@ModelActor
public actor GLIWordPairsModelActor {
    public func fetchAll() throws -> [GLIWordPair] {
        let descriptor = FetchDescriptor<GLIWordPairEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { entity in
            GLIWordPair(
                id: entity.id,
                word: entity.word,
                translation: entity.translation
            )
        }
    }

    public func save(_ pair: GLIWordPair) throws {
        let entity = GLIWordPairEntity(
            id: pair.id,
            word: pair.word,
            translation: pair.translation
        )
        modelContext.insert(entity)
        try modelContext.save()
    }
}
