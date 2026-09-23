import GlimpseCore
import Testing

@Suite("GLICaptureFieldLimits")
struct GLICaptureFieldLimitsTests {
    @Test("word, meaning, and example constants")
    func fieldConstants() {
        #expect(GLICaptureFieldLimits.maxWordLength == 300)
        #expect(GLICaptureFieldLimits.maxMeaningLength == 300)
        #expect(GLICaptureFieldLimits.maxExampleLength == 500)
    }

    @Test("capped returns the same string at and under the limit")
    func cappedAtAndUnderLimit() {
        let under = String(repeating: "a", count: 10)
        let atWord = String(repeating: "b", count: GLICaptureFieldLimits.maxWordLength)
        let atExample = String(repeating: "c", count: GLICaptureFieldLimits.maxExampleLength)

        #expect(GLICaptureFieldLimits.capped(under, to: GLICaptureFieldLimits.maxWordLength) == under)
        #expect(GLICaptureFieldLimits.capped(atWord, to: GLICaptureFieldLimits.maxWordLength) == atWord)
        #expect(
            GLICaptureFieldLimits.capped(atExample, to: GLICaptureFieldLimits.maxExampleLength)
                == atExample
        )
    }

    @Test("capped keeps the first N characters when over the limit")
    func cappedOverLimit() {
        let overWord = String(repeating: "d", count: 301)
        let overMeaning = String(repeating: "e", count: 400)
        let overExample = String(repeating: "f", count: 501)

        #expect(
            GLICaptureFieldLimits.capped(overWord, to: GLICaptureFieldLimits.maxWordLength)
                == String(repeating: "d", count: 300)
        )
        #expect(
            GLICaptureFieldLimits.capped(overMeaning, to: GLICaptureFieldLimits.maxMeaningLength)
                == String(repeating: "e", count: 300)
        )
        #expect(
            GLICaptureFieldLimits.capped(overExample, to: GLICaptureFieldLimits.maxExampleLength)
                == String(repeating: "f", count: 500)
        )
    }
}
