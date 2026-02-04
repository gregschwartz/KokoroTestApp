import AVFoundation
import MLX
import SwiftUI
import KokoroSwift
import Combine
import MLXUtilsLibrary

/// The view model that manages text-to-speech functionality using the Kokoro TTS engine.
/// - Loading and managing the Kokoro TTS model
/// - Managing available voice options
/// - Audio playback using AVAudioEngine
/// - Converting text to speech audio
final class TestAppModel: ObservableObject {
  /// The Kokoro text-to-speech engine instance
  let kokoroTTSEngine: KokoroTTS!

  /// The audio engine used for playback
  let audioEngine: AVAudioEngine!

  /// The audio player node attached to the audio engine
  let playerNode: AVAudioPlayerNode!

  /// Dictionary of available voices, mapped by voice name to MLX array data
  let voices: [String: MLXArray]

  /// Array of voice names available for selection in the UI
  @Published var voiceNames: [String] = []

  /// The currently selected voice name
  @Published var selectedVoice: String = ""

  @Published var stringToFollowTheAudio: String = ""

  var timer: Timer?

  /// Handles chunked TTS playback for long text
  private var chunkedPlayer: ChunkedTTSPlayer!

  /// Initializes the test app model with TTS engine, audio components, and voice data.
  init() {
    // Load the Kokoro TTS model from the app bundle
    let modelPath = Bundle.main.url(forResource: "kokoro-v1_0", withExtension: "safetensors")!
    kokoroTTSEngine = KokoroTTS(modelPath: modelPath)

    // Initialize audio engine and player node
    audioEngine = AVAudioEngine()
    playerNode = AVAudioPlayerNode()
    audioEngine.attach(playerNode)

    // Load voice data from NPZ file
    let voiceFilePath = Bundle.main.url(forResource: "voices", withExtension: "npz")!
    voices = NpyzReader.read(fileFromPath: voiceFilePath) ?? [:]

    // Extract voice names and sort them alphabetically
    voiceNames = voices.keys.map { String($0.split(separator: ".")[0]) }.sorted(by: <)
    selectedVoice = voiceNames[0]

    // Initialize chunked player for handling long text
    chunkedPlayer = ChunkedTTSPlayer(engine: kokoroTTSEngine, audioEngine: audioEngine, playerNode: playerNode)

    // Configure audio session for iOS
    #if os(iOS)
      do {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, mode: .default)
        try audioSession.setActive(true)
      } catch {
        logPrint("Failed to set up AVAudioSession: \(error.localizedDescription)")
      }
    #endif
  }

  /// Converts the provided text to speech and plays it through the audio engine.
  /// Automatically chunks long text to avoid Kokoro's token limit.
  /// - Parameter text: The text to be converted to speech
  func say(_ text: String) {
    chunkedPlayer.play(
      text: text,
      voice: voices[selectedVoice + ".npy"]!,
      language: selectedVoice.first! == "a" ? .enUS : .enGB
    )
  }
}
