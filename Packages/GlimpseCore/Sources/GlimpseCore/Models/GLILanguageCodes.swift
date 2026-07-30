import Foundation

/// Shared language-code allowlist for create/validation.
/// Codes live here: `Locale.Language.systemLanguages` (same set as Add Word / Word Card pickers).
public enum GLILanguageCodes {
    /// ISO language identifiers from the system language list (e.g. `es`, `fr`).
    public static var systemCodes: Set<String> {
        Set(
            Locale.Language.systemLanguages.compactMap { language in
                language.languageCode?.identifier
            }
        )
    }

    /// Trimmed, lowercased code if it is in `systemCodes`; otherwise `nil`.
    public static func normalizedSystemCode(_ code: String) -> String? {
        let normalized = code
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !normalized.isEmpty, systemCodes.contains(normalized) else {
            return nil
        }
        return normalized
    }
}
