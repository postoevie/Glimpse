// Task: capture 1-4 copy
import Foundation
import IssueReporting

public enum GLICaptureFieldLimits {
    public static let maxWordLength = 300
    public static let maxMeaningLength = 300
    public static let maxExampleLength = 500
    public static let maxMeaningsPerWord = 5
    public static let maxFolderNameLength = 80

    public static func capped(_ text: String, to limit: Int) -> String {
        guard text.count > limit else { return text }
        return String(text.prefix(limit))
    }

    /// Whether a UIKit replacement may proceed, and what the field must contain.
    public enum ChangeDecision: Equatable {
        case allow
        case reject
        case apply(text: String, cursorUTF16: Int)
    }

    /// Grapheme-aware gate for `shouldChangeTextIn` / `shouldChangeCharactersIn`.
    /// `utf16Range` is UIKit’s selection range in the current string.
    public static func changeDecision(
        current: String,
        utf16Range: NSRange,
        replacement: String,
        limit: Int
    ) -> ChangeDecision {
        guard let range = Range(utf16Range, in: current) else {
            reportIssue(
                "Invalid UTF-16 range \(utf16Range) for text utf16 count \(current.utf16.count)"
            )
            return .reject
        }

        if replacement.isEmpty {
            return .allow
        }

        let proposed = current.replacingCharacters(in: range, with: replacement)
        if proposed.count <= limit {
            return .allow
        }

        let replacedCount = current[range].count
        let room = limit - (current.count - replacedCount)
        if room <= 0 {
            return .reject
        }

        let clipped = String(replacement.prefix(room))
        let applied = current.replacingCharacters(in: range, with: clipped)
        let cursorUTF16 = current[..<range.lowerBound].utf16.count + clipped.utf16.count
        return .apply(text: applied, cursorUTF16: cursorUTF16)
    }
}
