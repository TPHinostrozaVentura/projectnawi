import 'package:flutter/material.dart';

class GuideScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guía de uso'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Cómo usar Ñawi Sense',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              '1. Presiona "Iniciar" para comenzar la detección de objetos en tiempo real.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            const Text(
              '2. La cámara detectará objetos y te los describirá por medio de audio.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            const Text(
              '3. Puedes cambiar entre el modelo de objetos y el modelo de billetes usando el botón de alternancia en la parte superior derecha.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            const Text(
              '4. Si necesitas usar la linterna, presiona el ícono en la parte superior derecha de la pantalla de detección.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Vuelve a la pantalla anterior
              },
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
