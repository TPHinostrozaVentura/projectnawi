import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class VoiceCommandManager {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final Function onCommandReceived;

  VoiceCommandManager({required this.onCommandReceived});

  Future<void> initialize() async {
    await _speech.initialize();
  }

  void startListening() {
    _speech.listen(onResult: (result) {
      String command = result.recognizedWords.toLowerCase();
      _processCommand(command);
    });
  }

  void stopListening() {
    _speech.stop();
  }

  void _processCommand(String command) async {
    if (command.contains("modo lectura")) {
      await _flutterTts.speak("Cambiando a modo de lectura de texto");
      onCommandReceived("text_reader");
    } else if (command.contains("modo normal")) {
      await _flutterTts.speak("Cambiando a modo normal");
      onCommandReceived("normal_mode");
    } else {
      await _flutterTts.speak("Comando no reconocido");
    }
  }

  void dispose() {
    _speech.cancel();
    _flutterTts.stop();
  }
}
