import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/yolo_view.dart';
import 'package:ultralytics_yolo/yolo.dart';

class CameraInferenceScreen extends StatefulWidget {
  const CameraInferenceScreen({super.key});

  @override
  State<CameraInferenceScreen> createState() => _CameraInferenceScreenState();
}

class _CameraInferenceScreenState extends State<CameraInferenceScreen> {
  int _detectionCount = 0;
  double _confidenceThreshold = 0.8;
  double _iouThreshold = 0.50;
  String _lastDetection = "";

  // Method 1: Create a controller to interact with the YoloView
  final _yoloController = YoloViewController();


  // Method 2: Create a GlobalKey to access the YoloView directly
  final _yoloViewKey = GlobalKey<YoloViewState>();

  // Flag to toggle between using controller and direct key access
  // This is just for demonstration - normally you'd pick one approach
  bool _useController = true;

  void _onDetectionResults(List<YOLOResult> results) {
    if (!mounted) return;

    debugPrint('_onDetectionResults called with ${results.length} results');

    // Print details of the first few detections for debugging
    for (var i = 0; i < results.length && i < 3; i++) {
      final r = results[i];
      debugPrint('  Detection $i: ${r.className} (${(r.confidence * 100).toStringAsFixed(1)}%) at ${r.boundingBox}');
    }

    // Make sure to actually update the state
    setState(() {
      _detectionCount = results.length;
      if (results.isNotEmpty) {
        // Get detection with highest confidence
        final topDetection = results.reduce((a, b) =>
        a.confidence > b.confidence ? a : b);
        _lastDetection = "${topDetection.className} (${(topDetection.confidence * 100).toStringAsFixed(1)}%)";

        debugPrint('Updated state: count=$_detectionCount, top=$_lastDetection');
      } else {
        _lastDetection = "None";
        debugPrint('Updated state: No detections');
      }
      _yoloController.setConfidenceThreshold(0.8);
    });
  }

  @override
  void initState() {
    super.initState();
    _checkModelExists();

    // Set initial thresholds via controller
    // We do this in a post-frame callback to ensure the view is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_useController) {
        //_yoloController.setConfidenceThreshold(0.8);
        _yoloController.setThresholds(
          confidenceThreshold: 0.8,//_confidenceThreshold,
          iouThreshold: 0.5,//_iouThreshold,
        );
      } else {
        _yoloViewKey.currentState?.setThresholds(
          confidenceThreshold: 0.8,//_confidenceThreshold,
          iouThreshold: 0.5,//_iouThreshold,
        );
      }
    });
  }

  // Verificar si el modelo existe antes de cargarlo
  Future<void> _checkModelExists() async {
    try {
      // Obtener el Map del resultado
      final result = await YOLO.checkModelExists('bestv8nint8');
//bestv8nint8  yolov8n_int8
      // Aquí accedemos al valor de la clave 'exists' para verificar si el modelo está disponible
      bool modelExists = result['exists'] ?? false;

      if (!modelExists) {
        print('El modelo no se encuentra en la ubicación: ${result['location']}');
        // Aquí puedes manejar el caso en el que el modelo no está disponible
      } else {
        print('El modelo está disponible en la ubicación: ${result['location']}');
        // Cargar el modelo y continuar con la lógica de la aplicación
      }
    } catch (e) {
      print('Error al verificar el modelo: $e');
      // Manejo de errores si la función falla
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deteccion de Billetes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // Panel to display detection count and last detection class
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.black.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Detection count: $_detectionCount'),
                Text('Top detection: $_lastDetection'),
              ],
            ),
          ),
          // Camera view
          Expanded(
            child: Container(
              color: Colors.black12,
              child: YoloView(
                // Use GlobalKey or controller based on flag
                key: null,//_useController ? null : _yoloViewKey,
                controller: _yoloController,//_useController ? _yoloController : null,
                modelPath: 'bestv8nint8',
                // bestv8nint8  yolov8n_int8
                task: YOLOTask.detect,
                onResult: _onDetectionResults,
              ),
            ),
          ),
        ],
      ),
    );
  }
}










