import 'package:flutter/material.dart';
import '../../core/theme.dart';

class CuestionarioView extends StatefulWidget {
  @override
  _CuestionarioViewState createState() => _CuestionarioViewState();
}

class _CuestionarioViewState extends State<CuestionarioView> {
  final List<Pregunta> preguntas = [
    Pregunta(
      texto: "¿Qué es el carding?",
      opciones: ["Un tipo de comida", "Un fraude con tarjetas", "Una aplicación", "Un deporte"],
      correcta: 1,
    ),
    Pregunta(
      texto: "¿Cómo puedes prevenir el carding?",
      opciones: [
        "Compartiendo tu contraseña",
        "Ignorando notificaciones bancarias",
        "Verificando transacciones sospechosas",
        "Usando redes Wi-Fi públicas"
      ],
      correcta: 2,
    ),
    Pregunta(
      texto: "¿Qué debes hacer si ves una transacción desconocida?",
      opciones: ["Ignorarla", "Reportarla al banco", "Cerrar tu app", "Pagarla igual"],
      correcta: 1,
    ),
  ];

  int indice = 0;
  int vidas = 3;
  int puntaje = 0;
  bool bloqueado = false;

  void verificarRespuesta(int seleccion) {
    if (bloqueado) return;

    setState(() => bloqueado = true);

    final esCorrecta = seleccion == preguntas[indice].correcta;

    if (esCorrecta) {
      puntaje += 10;
    } else {
      vidas--;
    }

    mostrarDialogoResultado(esCorrecta);
  }

  void mostrarDialogoResultado(bool correcta) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.blanco,
        title: Text(
          correcta ? "✅ ¡Correcto!" : "❌ Incorrecto",
          style: TextStyle(color: AppColors.azulOscuro),
        ),
        content: Text(
          correcta
              ? "Has ganado 10 puntos."
              : "Te quedan $vidas ${vidas == 1 ? 'vida' : 'vidas'}",
          style: TextStyle(color: AppColors.azulIntermedio),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (vidas == 0) {
                mostrarGameOver();
              } else if (indice + 1 >= preguntas.length) {
                mostrarFinCuestionario();
              } else {
                setState(() {
                  indice++;
                  bloqueado = false;
                });
              }
            },
            child: Text(
              "Continuar",
              style: TextStyle(color: AppColors.azulIntermedio),
            ),
          )
        ],
      ),
    );
  }

  void mostrarFinCuestionario() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.blanco,
        title: Text("🎉 Cuestionario completado", style: TextStyle(color: AppColors.azulOscuro)),
        content: Text("Tu puntaje final es $puntaje puntos.",
            style: TextStyle(color: AppColors.azulIntermedio)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.popUntil(context, ModalRoute.withName('/home'));
            },
            child: Text("Volver al inicio", style: TextStyle(color: AppColors.azulIntermedio)),
          )
        ],
      ),
    );
  }

  void mostrarGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.blanco,
        title: Text("🛑 Has perdido", style: TextStyle(color: AppColors.azulOscuro)),
        content: Text("Te quedaste sin vidas. Intenta nuevamente.",
            style: TextStyle(color: AppColors.azulIntermedio)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.popUntil(context, ModalRoute.withName('/home'));
            },
            child: Text("Volver al inicio", style: TextStyle(color: AppColors.azulIntermedio)),
          )
        ],
      ),
    );
  }

  Widget buildVidas() {
    return Row(
      children: List.generate(3, (i) {
        return Icon(
          i < vidas ? Icons.favorite : Icons.favorite_border,
          color: Colors.red,
          size: 26,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pregunta = preguntas[indice];

    return Scaffold(
      backgroundColor: AppColors.blanco,
      appBar: AppBar(
        title: const Text("Evaluación: Prevención del Carding"),
        centerTitle: true,
        backgroundColor: AppColors.azulOscuro,
        foregroundColor: AppColors.blanco,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildVidas(),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: puntaje / (preguntas.length * 10),
              backgroundColor: AppColors.grisSuave,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.azulIntermedio),
            ),
            const SizedBox(height: 10),
            Text(
              "Puntaje: $puntaje",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.azulOscuro),
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: AppColors.celesteClaro.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  pregunta.texto,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.azulOscuro),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(pregunta.opciones.length, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => verificarRespuesta(i),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: AppColors.azulIntermedio,
                    foregroundColor: AppColors.blanco,
                  ),
                  child: Text(
                    pregunta.opciones[i],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class Pregunta {
  final String texto;
  final List<String> opciones;
  final int correcta;

  Pregunta({required this.texto, required this.opciones, required this.correcta});
}

