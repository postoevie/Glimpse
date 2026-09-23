// Task: capture 1-4 copy
import Foundation

/// Encodes / decodes example lines for the existing single-string sidecar.
public enum GLIExampleListCodec {
    /// Joins non-empty trimmed lines with newlines. Empty list → `""`.
    public static func encode(_ lines: [String]) -> String {
        normalize(lines).joined(separator: "\n")
    }

    /// Splits on newlines, trims, drops empties. Empty / blank text → `[]`.
    public static func decode(_ text: String) -> [String] {
        normalize(text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init))
    }

    /// Trims each line and drops empties (order preserved).
    private static func normalize(_ lines: [String]) -> [String] {
        var result: [String] = []
        result.reserveCapacity(lines.count)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            result.append(trimmed)
        }

        return result
    }
}
