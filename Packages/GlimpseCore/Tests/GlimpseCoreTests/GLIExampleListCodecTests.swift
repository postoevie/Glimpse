import GlimpseCore
import Testing

@Suite("GLIExampleListCodec")
struct GLIExampleListCodecTests {
    @Test("encode joins trimmed non-empty lines with newlines")
    func encodeJoinsTrimmedLines() {
        #expect(GLIExampleListCodec.encode(["  one  ", "", " two ", "   "]) == "one\ntwo")
        #expect(GLIExampleListCodec.encode([]) == "")
        #expect(GLIExampleListCodec.encode(["   ", "\n"]) == "")
    }

    @Test("decode splits, trims, and drops empty lines")
    func decodeSplitsAndDropsEmpties() {
        #expect(GLIExampleListCodec.decode("  one  \n\n  two  \n") == ["one", "two"])
        #expect(GLIExampleListCodec.decode("") == [])
        #expect(GLIExampleListCodec.decode("   \n\n") == [])
    }

    @Test("encode and decode round-trip non-empty lines")
    func encodeDecodeRoundTrip() {
        let lines = ["Hola amigo.", "Hello friend."]
        let encoded = GLIExampleListCodec.encode(lines)

        #expect(encoded == "Hola amigo.\nHello friend.")
        #expect(GLIExampleListCodec.decode(encoded) == lines)
        #expect(GLIExampleListCodec.encode(GLIExampleListCodec.decode(encoded)) == encoded)
    }
}
