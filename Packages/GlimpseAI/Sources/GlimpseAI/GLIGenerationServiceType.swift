import Foundation
import GlimpseCore

/// On-demand generation surface. Live adapters land in Increment I7.
public protocol GLIGenerationServiceType: Sendable {
    func translate(text: String, sourceLanguage: String, targetLanguage: String) async throws -> [String]
    func example(text: String, sourceLanguage: String) async throws -> String
    func discoverSimilar(text: String, sourceLanguage: String) async throws -> [String]
}

/// Stub used until HybridGenerationService ships (I7).
public struct GLIUnimplementedGenerationService: GLIGenerationServiceType {
    public init() {}

    public func translate(text: String, sourceLanguage: String, targetLanguage: String) async throws -> [String] {
        throw GLIGenerationError.unimplemented
    }

    public func example(text: String, sourceLanguage: String) async throws -> String {
        throw GLIGenerationError.unimplemented
    }

    public func discoverSimilar(text: String, sourceLanguage: String) async throws -> [String] {
        throw GLIGenerationError.unimplemented
    }
}

public enum GLIGenerationError: Error, Sendable {
    case unimplemented
}
