import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'main.dart'; // para volver al modo normal
import 'package:speech_to_text/speech_to_text.dart' as stt;

class TextReaderScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  TextReaderScreen({required this.cameras});

  @override
  _TextReaderScreenState createState() => _TextReaderScreenState();
}

class _TextReaderScreenState extends State<TextReaderScreen> {
  late CameraController _controller;
  final TextRecognizer textRecognizer = TextRecognizer();
  FlutterTts flutterTts = FlutterTts();
  bool isProcessing = false;

  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool isListeningManually = false;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    configureTts();
    initSpeechRecognizer();
  }

  void configureTts() async {
    await flutterTts.setLanguage("es-ES");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
  }

  void initializeCamera() async {
    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.max,
      enableAudio: false,
    );

    await _controller.initialize();
    if (!mounted) return;
    setState(() {});
  }

  void captureAndReadText() async {
    if (isProcessing) return;
    setState(() => isProcessing = true);

    final image = await _controller.takePicture();
    final inputImage = InputImage.fromFilePath(image.path);
    final recognizedText = await textRecognizer.processImage(inputImage);

    // ✅ Concatenar todo el texto detectado
    String fullText = recognizedText.text.trim();

    if (fullText.isNotEmpty) {
      await flutterTts.speak(fullText);
    } else {
      await flutterTts.speak("No se detectó texto");
    }

    setState(() => isProcessing = false);
  }

  void initSpeechRecognizer() async {
    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == 'done' && isListeningManually) {
          setState(() => _isListening = false);
        }
      },
      onError: (val) => print('Error en voz: $val'),
    );
    if (!available) {
      print("Reconocimiento de voz no disponible");
    }
  }

  void startManualListening() async {
    setState(() {
      isListeningManually = true;
      _isListening = true;
    });

    HapticFeedback.mediumImpact();
    await flutterTts.speak("Estoy escuchando");

    _speech.listen(onResult: (val) {
      String command = val.recognizedWords.toLowerCase();
      if (command.contains("modo normal") || command.contains("detección de objetos")) {
        _navigateToObjectDetection();
      }
    });
  }

  void stopManualListening() async {
    await flutterTts.speak("Comando recibido");
    HapticFeedback.selectionClick();
    await _speech.stop();
    setState(() {
      _isListening = false;
      isListeningManually = false;
    });
  }

  void _navigateToObjectDetection() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RealTimeObjectDetection(
          cameras: widget.cameras,
          model: 'SSDMobileNet',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    textRecognizer.close();
    flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Lectura de Texto'),
        backgroundColor: Colors.black87,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller)),

          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: captureAndReadText,
                child: Text('Capturar y Leer Texto'),
              ),
            ),
          ),

          // Botón Push to Talk
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTapDown: (_) => startManualListening(),
                onTapUp: (_) => stopManualListening(),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    _isListening ? "Escuchando..." : "Mantén presionado para hablar",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
