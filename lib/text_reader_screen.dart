import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_tts/flutter_tts.dart';

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

  @override
  void initState() {
    super.initState();
    initializeCamera();
    configureTts();
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

    for (TextBlock block in recognizedText.blocks) {
      await flutterTts.speak(block.text);
      break; // Reads only the first detected block
    }

    setState(() => isProcessing = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    textRecognizer.close();
    flutterTts.stop();
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
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_controller),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: captureAndReadText,
                child: Text('Capturar y Leer Texto'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
