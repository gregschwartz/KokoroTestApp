import AVFoundation
import KokoroSwift
import MLX

/// Handles chunked TTS generation and sequential playback.
/// Automatically splits long text to avoid Kokoro's token limit.
final class ChunkedTTSPlayer {
    private let engine: KokoroTTS
    private let audioEngine: AVAudioEngine
    private let playerNode: AVAudioPlayerNode
    private var queue: [AVAudioPCMBuffer] = []
    private let sampleRate = Double(KokoroTTS.Constants.samplingRate)

    init(engine: KokoroTTS, audioEngine: AVAudioEngine, playerNode: AVAudioPlayerNode) {
        self.engine = engine
        self.audioEngine = audioEngine
        self.playerNode = playerNode
    }

    /// Generates and plays text, automatically chunking if needed.
    func play(text: String, voice: MLXArray, language: Language) {
        let chunks = TextChunkingService.chunk(text)
        queue = chunks.compactMap { chunk in
            guard let (audio, _) = try? engine.generateAudio(voice: voice, language: language, text: chunk) else {
                return nil
            }
            return createBuffer(from: audio)
        }
        playNext()
    }

    private func playNext() {
        guard !queue.isEmpty else { return }
        let buffer = queue.removeFirst()

        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: buffer.format)
        try? audioEngine.start()

        playerNode.scheduleBuffer(buffer, at: nil, options: .interrupts) { [weak self] in
            DispatchQueue.main.async { self?.playNext() }
        }
        playerNode.play()
    }

    private func createBuffer(from audio: [Float]) -> AVAudioPCMBuffer? {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(audio.count)) else { return nil }
        buffer.frameLength = buffer.frameCapacity
        audio.withUnsafeBufferPointer { src in
            UnsafeMutableRawPointer(buffer.floatChannelData![0])
                .copyMemory(from: src.baseAddress!, byteCount: src.count * MemoryLayout<Float>.stride)
        }
        return buffer
    }
}
