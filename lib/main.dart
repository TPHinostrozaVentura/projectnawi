import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:projectnawi/banknote_recogni_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/services.dart';
import 'splash_screen.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'text_reader_screen.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const MyApp({Key? key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(cameras: cameras),
    );
  }
}

class RealTimeObjectDetection extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String model;

  RealTimeObjectDetection({required this.cameras, required this.model});

  @override
  _RealTimeObjectDetectionState createState() =>
      _RealTimeObjectDetectionState();
}

class _RealTimeObjectDetectionState extends State<RealTimeObjectDetection> {
  List<String> lastUniqueObjects = [];
  final int maxObjects = 10;
  final apiKey='Put your apiKey here';

  late CameraController _controller;
  bool isModelLoaded = false;
  List<dynamic>? recognitions;
  int imageHeight = 0;
  int imageWidth = 0;
  bool isProcessing = false;
  FlutterTts flutterTts = FlutterTts();
  bool isSpeaking = false;
  bool isFlashOn = false;

  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool isListeningManually = false;
  bool isVoiceCommandActive = false; // Silencia audiodescripciones

  @override
  void initState() {
    super.initState();
    initializeCamera();
    loadModel(widget.model);
    configureTts();
    initSpeechRecognizer();
    //initSpeechRecognizer(); // Initialize speech recognition
  }

  void sendObjectList() async {

    setState(() {
      isSpeaking = true; // Detiene describeObject
    });

    String objectList = lastUniqueObjects.join(", ");
    String message = "Estos son los objetos detectados: $objectList. ahora infiere en que entonrno se encuentra la persona, empieza con una frase como: 'probablemente te encuentras en....' dame una respuesta corta sin detallar cada elemento.";

    final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'user',
              'content': message
            }
          ]
        })
    );

    if(response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      String analysisResponse = jsonResponse['choices'][0]['message']['content'];

      print("Lista de objetos enviada: $objectList");
      print("Análisis de GPT: $analysisResponse");

      flutterTts.speak(analysisResponse);

      flutterTts.setCompletionHandler(() {
        setState(() {
          isSpeaking = false; // Permite que describeObject continúe
        });
      });

    } else {
      print("Error en la solicitud: ${response.statusCode}");
      print("Detalles del error: ${response.body}");

      setState(() {
        isSpeaking = true; // Detiene describeObject
      });
    }
  }



  String getObjectsString() {
    return lastUniqueObjects.join(', ');
  }

  void configureTts() async {
    await flutterTts.setLanguage("es-ES");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> loadModel(String modelName) async {
    String? modelPath;
    String? labelPath;

    if (modelName == 'SSDMobileNet') {
      modelPath = 'assets/detect.tflite';
      labelPath = 'assets/labelmap.txt';
    } else if (modelName == 'BilletesModel') {
      modelPath = 'assets/model.tflite';
      labelPath = 'assets/labels.txt';
    }

    try {
      String? res = await Tflite.loadModel(
        model: modelPath!,
        labels: labelPath!,
      );
      setState(() {
        isModelLoaded = res != null;
      });
    } catch (e) {
      print("Error al cargar el modelo: $e");
      setState(() {
        isModelLoaded = false;
      });
    }
  }

  void initializeCamera() async {
    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller.initialize();

    if (!mounted) return;

    _controller.startImageStream((CameraImage image) {
      if (isModelLoaded && !isProcessing) {
        runModel(image);
      }
    });

    setState(() {});
  }

  void runModel(CameraImage image) async {
    if (image.planes.isEmpty || isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    var recognitions = await Tflite.detectObjectOnFrame(
      bytesList: image.planes.map((plane) => plane.bytes).toList(),
      model:
      widget.model == 'SSDMobileNet' ? 'SSDMobileNet' : 'model.tflite',
      imageHeight: image.height,
      imageWidth: image.width,
      imageMean: 127.5,
      imageStd: 127.5,
      numResultsPerClass: 2,
      threshold: 0.5,
    );

    setState(() {
      this.recognitions = recognitions;
      isProcessing = false;
    });

    if (recognitions != null &&
        recognitions.isNotEmpty &&
        !isSpeaking &&
        !isVoiceCommandActive) {
      String detectedClass = recognitions[0]["detectedClass"];
      double confidence = recognitions[0]["confidenceInClass"];

      if (!lastUniqueObjects.contains(detectedClass)) {
        if (lastUniqueObjects.length >= maxObjects) {
          lastUniqueObjects.remove(0);
        }
        lastUniqueObjects.add(detectedClass);
      }

      print('Últimos objetos detectados: ${lastUniqueObjects.join(", ")}');

      describeObject(detectedClass, confidence);
    }
  }

  void describeObject(String detectedClass, double confidence) async {
    if (isVoiceCommandActive) return;

    setState(() {
      isSpeaking = true;
    });

    String description =
        'Detectado: $detectedClass con ${(confidence * 100).toStringAsFixed(0)}% de confianza';
    await flutterTts.speak(description);

    flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
      });
    });
  }

  void toggleFlash() async {
    if (_controller.value.isInitialized) {
      try {
        await _controller.setFlashMode(
          isFlashOn ? FlashMode.off : FlashMode.torch,
        );
        setState(() {
          isFlashOn = !isFlashOn;
        });
      } catch (e) {
        print("Error al cambiar el modo de flash: $e");
      }
    }
  }

  // Initialize speech recognizer
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
    isVoiceCommandActive = true;
    setState(() {
      isListeningManually = true;
      _isListening = true;
    });

    HapticFeedback.mediumImpact();
    await flutterTts.speak("Estoy escuchando");

    _speech.listen(onResult: (val) {
      String command = val.recognizedWords.toLowerCase();
      if (command.contains("modo lectura")) {
        _navigateToTextReading();
      } else if (command.contains("modo normal")) {
        _navigateToObjectDetection();
      }else if (command.contains("modo billetes")) {
        _navigateToBanknoteDetection();
      }
    });
  }

  void stopManualListening() async {
    isVoiceCommandActive = false;
    await flutterTts.speak("Comando recibido");
    HapticFeedback.selectionClick();
    await _speech.stop();
    setState(() {
      _isListening = false;
      isListeningManually = false;
    });
  }

  void _navigateToTextReading() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TextReaderScreen(cameras: widget.cameras),
      ),
    );
  }

  void _navigateToObjectDetection() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RealTimeObjectDetection(
          cameras: widget.cameras,
          model: widget.model,
        ),
      ),
    );
  }
  void _navigateToBanknoteDetection() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CameraInferenceScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    WakelockPlus.enable();


    if (!_controller.value.isInitialized) {
      return Container();
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller)),

          if (recognitions != null)
            BoundingBoxes(
              recognitions: recognitions!,
              previewH: imageHeight.toDouble(),
              previewW: imageWidth.toDouble(),
              screenH: MediaQuery.of(context).size.height,
              screenW: MediaQuery.of(context).size.width,
            ),

          Positioned(
              top: 30,
              right: 20,
              child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: toggleFlash,
                    ),

                    IconButton(icon:Icon(Icons.send,color: Colors.white,size: 30,),
                      onPressed: sendObjectList,
                    )
                  ]
              )
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    _isListening
                        ? "Escuchando..."
                        : "Mantén presionado para hablar",
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
}

class BoundingBoxes extends StatelessWidget {
  final List<dynamic> recognitions;
  final double previewH;
  final double previewW;
  final double screenH;
  final double screenW;

  BoundingBoxes({
    required this.recognitions,
    required this.previewH,
    required this.previewW,
    required this.screenH,
    required this.screenW,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: recognitions.map((rec) {
        var x = rec["rect"]["x"] * screenW;
        var y = rec["rect"]["y"] * screenH;
        double w = rec["rect"]["w"] * screenW;
        double h = rec["rect"]["h"] * screenH;

        return Positioned(
          left: x,
          top: y,
          width: w,
          height: h,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 3),
            ),
            child: Text(
              "${rec["detectedClass"]} ${(rec["confidenceInClass"] * 100).toStringAsFixed(0)}%",
              style: TextStyle(
                color: Colors.red,
                fontSize: 15,
                background: Paint()..color = Colors.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
