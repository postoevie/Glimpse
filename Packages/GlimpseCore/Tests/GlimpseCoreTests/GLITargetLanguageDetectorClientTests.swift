import GlimpseCore
import Testing

@Suite("GLITargetLanguageDetectorClient")
struct GLITargetLanguageDetectorClientTests {
    @Test("live returns nil for empty, 1-character, and 2-character meaning text")
    func liveReturnsNilBelowMinimumLength() {
        let client = GLITargetLanguageDetectorClient.live

        #expect(client.detectTargetLanguage("") == nil)
        #expect(client.detectTargetLanguage("a") == nil)
        #expect(client.detectTargetLanguage("ab") == nil)
        #expect(client.detectTargetLanguage("  ab  ") == nil)
        #expect(client.detectTargetLanguage(" \n ") == nil)
    }
}
