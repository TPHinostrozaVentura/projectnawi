import 'package:flutter/material.dart';

class UserGuide extends StatelessWidget {
  const UserGuide({Key? key}) : super(key: key);
  //const UserGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          // Imagen de fondo con desplazamiento a la izquierda
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/blindimg2.jpeg', // Asegúrate de tener la imagen en la carpeta assets
                fit: BoxFit.cover,
                //alignment: Alignment.topRight,
              ),
            ),
          ),
          // Contenido de la pantalla
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // Botones centrales
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center, // Centra verticalmente
                    children: <Widget>[
                      SizedBox(
                        width: 300, // Ancho del contenedor
                        height: 400, // Alto del contenedor
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7), // Color de fondo con opacidad
                            borderRadius: BorderRadius.all(Radius.circular(30)), // Bordes redondeados
                          ),
                          padding: const EdgeInsets.all(26), // Espacio interior
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start, // Alinea a la izquierda el contenido
                            children: [
                              Center( // Centra el título horizontalmente
                                child: Text(
                                  'GUIA DE USO',
                                  style: TextStyle(
                                    fontSize: 34, // Tamaño más grande para el título
                                    color: Colors.white, // Color del texto
                                    fontWeight: FontWeight.bold, // Negrita para el título
                                  ),
                                  textAlign: TextAlign.center, // Alineación centrada del título
                                ),
                              ),
                              SizedBox(height: 16), // Espacio entre el título y el texto
                              Text(
                                '1. Apunta la cámara hacia los objetos para identificarlos.\n'
                                    '2. Si hay poca luz, presiona el botón para encender la linterna.\n'
                                    '3. Los objetos detectados serán narrados automáticamente por voz.\n'
                                    '4. Usa el botón de navegación para acceder al menú principal.\n',
                                style: TextStyle(
                                  fontSize: 16, // Tamaño más pequeño para el cuerpo del texto
                                  color: Colors.white, // Color del texto
                                ),
                                textAlign: TextAlign.left, // Alineación izquierda para el contenido
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Botones inferiores
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    IconButton(
                      onPressed: () {
                        // Acción para Home
                      },
                      icon: const Icon(Icons.home),
                      iconSize: 40,
                    ),
                    IconButton(
                      onPressed: () {
                        // Acción para Ir Atrás
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back),
                      iconSize: 40,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
