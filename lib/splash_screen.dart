import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:projectnawi/banknote_recogni_screen.dart';
import 'package:projectnawi/useGuide.dart';
import 'main.dart';
import 'text_reader_screen.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  SplashScreen({required this.cameras});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool isListeningManually = false;

  @override
  void initState() {
    super.initState();
    _configureTts();
    _welcomeUser();
    _initSpeechRecognizer();
  }

  void _configureTts() async {
    await flutterTts.setLanguage("es-ES");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
  }

  void _welcomeUser() async {
    await flutterTts.speak(
      "Bienvenido a Ñawi Sense. Puedes presionar Iniciar para comenzar la detección de objetos. También puedes usar la detección de billetes, lectura de texto o revisar la guía de uso.",
    );
  }

  void _initSpeechRecognizer() async {
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

  void _startManualListening() async {
    setState(() {
      _isListening = true;
      isListeningManually = true;
    });

    HapticFeedback.mediumImpact();
    await flutterTts.speak("Estoy escuchando");

    _speech.listen(onResult: (val) {
      String command = val.recognizedWords.toLowerCase();

      if (command.contains("iniciar")) {
        _navigateToDetection();
      } else if (command.contains("modo lectura")) {
        _navigateToTextReader();
      } else if (command.contains("modo billetes") || command.contains("detección de billetes")) {
        _navigateToBilletes();
      } else if (command.contains("guía") || command.contains("uso")) {
        _navigateToGuide();
      }
    });
  }

  void _stopManualListening() async {
    await flutterTts.speak("Comando recibido");
    HapticFeedback.selectionClick();
    await _speech.stop();
    setState(() {
      _isListening = false;
      isListeningManually = false;
    });
  }

  void _navigateToDetection() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RealTimeObjectDetection(
          cameras: widget.cameras,
          model: 'SSDMobileNet',
        ),
      ),
    );
  }

  void _navigateToTextReader() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TextReaderScreen(cameras: widget.cameras),
      ),
    );
  }

  void _navigateToBilletes() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RealTimeObjectDetection(
          cameras: widget.cameras,
          model: 'BilletesModel',
        ),
      ),
    );
  }

  void _navigateToGuide() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserGuide()),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/blindimg2.jpeg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Ñawi Sense',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: _style(Colors.deepPurpleAccent),
                  onPressed: _navigateToDetection,
                  child: const Text('Iniciar', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: _style(Colors.green),
                  onPressed: _navigateToBilletes,
                  child: const Text('Detección de Billetes', style: TextStyle(fontSize: 18)),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CameraInferenceScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Detección de Billetes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: _style(Colors.blueAccent),
                  onPressed: _navigateToTextReader,
                  child: const Text('Lectura de Texto', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: _style(Colors.redAccent),
                  onPressed: _navigateToGuide,
                  child: const Text('Guía de Uso', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
          // Botón Push to Talk
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTapDown: (_) => _startManualListening(),
                onTapUp: (_) => _stopManualListening(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    _isListening ? "Escuchando..." : "Mantén presionado para hablar",
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _style(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );
  }
}
