import SwiftUI

/// Sample texts to prefill the input field (easily replaceable)
private let sampleTexts = [
  "I'm reading a book about anti-gravity. It's impossible to put down!",
  "Why don't scientists trust atoms? Because they make up everything!",
  "I used to hate facial hair, but then it grew on me.",
  "What do you call a fake noodle? An impasta!",
  "I'm on a seafood diet. I see food and I eat it."
]

/// This view provides a simple interface for text-to-speech generation.
struct ContentView: View {
  /// The view model that manages the TTS engine and audio playback
  @ObservedObject var viewModel: TestAppModel

  /// The text input from the user that will be converted to speech
  @State private var inputText: String = sampleTexts.randomElement()!

  /// Tracks if the current text is a sample (clears on tap)
  @State private var isSampleText: Bool = true

  var body: some View {
    VStack {
      Spacer()
      
      // Text input field for entering speech content
      TextField("Type something to say...", text: Binding(
        get: { inputText },
        set: { newValue in
          isSampleText = false
          inputText = newValue
        }
      ))
        .padding()
        .background(Color(.systemGray))
        .cornerRadius(8)
        .padding(.horizontal)
        .onTapGesture {
          if isSampleText {
            inputText = ""
            isSampleText = false
          }
        }

      // Voice selection picker
      Picker("Selected Voice: ", selection: $viewModel.selectedVoice) {
        ForEach(viewModel.voiceNames, id: \.self) { voice in
          Text(voice)
            .foregroundStyle(Color.black)
            .tag(voice)
        }
      }
      .accentColor(.black)
      .foregroundColor(.black)
      .pickerStyle(.menu)
      .padding(.horizontal)
      .tint(.accentColor)
      .background(.gray)
      
      // Button to trigger text-to-speech synthesis
      Button {
        if !inputText.isEmpty {
          viewModel.say(inputText)
        } else {
          viewModel.say("Please type something first")
        }
      } label: {
        HStack(alignment: .center) {
          Spacer()
          Text("Say something")
            .foregroundColor(.white)
            .frame(height: 50)
          Spacer()
        }
        .background(.black)
        .padding(.horizontal)
      }

      Text("Spoken string: " + viewModel.stringToFollowTheAudio)
        .padding()
        .foregroundStyle(.black)
        .background(.white)
      
      Spacer()
    }
    .background(.white)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

#Preview {
  ContentView(viewModel: TestAppModel())
}
