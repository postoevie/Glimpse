import Foundation
import GlimpseCore

/// On-demand generation surface. Live adapters land in Increment I7.
public protocol GenerationService: Sendable {
    func translate(text: String, sourceLanguage: String, targetLanguage: String) async throws -> [String]
    func example(text: String, sourceLanguage: String) async throws -> String
    func discoverSimilar(text: String, sourceLanguage: String) async throws -> [String]
}

/// Stub used until HybridGenerationService ships (I7).
public struct UnimplementedGenerationService: GenerationService {
    public init() {}

    public func translate(text: String, sourceLanguage: String, targetLanguage: String) async throws -> [String] {
        throw GenerationError.unimplemented
    }

    public func example(text: String, sourceLanguage: String) async throws -> String {
        throw GenerationError.unimplemented
    }

    public func discoverSimilar(text: String, sourceLanguage: String) async throws -> [String] {
        throw GenerationError.unimplemented
    }
}

public enum GenerationError: Error, Sendable {
    case unimplemented
}
