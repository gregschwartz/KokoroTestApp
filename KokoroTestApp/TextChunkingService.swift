import Foundation
import NaturalLanguage

/// Service for chunking text into smaller pieces for TTS processing.
/// Kokoro TTS has a ~510 token limit (~350 characters safe limit).
/// Uses sentence-based chunking with fallback to smaller units.
struct TextChunkingService {

    /// Recommended max characters per chunk (conservative limit for Kokoro's 510 token max)
    static let recommendedMaxCharacters = 350

    /// Chunks text into pieces suitable for TTS.
    /// - Parameters:
    ///   - text: Text to chunk
    ///   - maxCharacters: Max chars per chunk (default: 350)
    /// - Returns: Array of text chunks
    static func chunk(_ text: String, maxCharacters: Int = recommendedMaxCharacters) -> [String] {
        guard !text.isEmpty else { return [] }

        // First try sentence-based chunking
        let chunks = chunkBySentence(text, maxCharacters: maxCharacters)

        // Validate all chunks fit
        if chunks.allSatisfy({ $0.count <= maxCharacters }) {
            return chunks
        }

        // Fallback: re-chunk any oversized pieces
        return chunks.flatMap { chunk in
            chunk.count > maxCharacters
                ? chunkByWords(chunk, maxCharacters: maxCharacters)
                : [chunk]
        }
    }

    /// Chunks by sentence boundaries using NaturalLanguage framework.
    private static func chunkBySentence(_ text: String, maxCharacters: Int) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text

        var chunks: [String] = []
        var currentChunk = ""

        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)

            if currentChunk.isEmpty {
                currentChunk = sentence
            } else if currentChunk.count + sentence.count + 1 <= maxCharacters {
                currentChunk += " " + sentence
            } else {
                chunks.append(currentChunk)
                currentChunk = sentence
            }
            return true
        }

        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }

        return chunks.filter { !$0.isEmpty }
    }

    /// Fallback: chunks by word boundaries.
    private static func chunkByWords(_ text: String, maxCharacters: Int) -> [String] {
        let words = text.split(separator: " ")
        var chunks: [String] = []
        var currentChunk = ""

        for word in words {
            let wordStr = String(word)
            if currentChunk.isEmpty {
                currentChunk = wordStr
            } else if currentChunk.count + wordStr.count + 1 <= maxCharacters {
                currentChunk += " " + wordStr
            } else {
                chunks.append(currentChunk)
                currentChunk = wordStr
            }
        }

        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }

        return chunks.filter { !$0.isEmpty }
    }
}
