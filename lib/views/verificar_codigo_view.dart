import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/theme.dart';

class VerificarCodigoView extends StatefulWidget {
  final String email;
  VerificarCodigoView({required this.email});

  @override
  _VerificarCodigoViewState createState() => _VerificarCodigoViewState();
}

class _VerificarCodigoViewState extends State<VerificarCodigoView> {
  final codigoController = TextEditingController();
  final nuevaPassController = TextEditingController();
  bool isLoading = false;

  void confirmarRecuperacion() async {
    final codigo = codigoController.text.trim();
    final nueva = nuevaPassController.text.trim();

    if (codigo.isEmpty || nueva.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse('https://pucara-backend-final.onrender.com/api/api/confirmar-recuperacion/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': widget.email,
        'codigo': codigo,
        'nueva_contrasena': nueva,
      }),
    );

    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Contraseña actualizada. Inicia sesión.")),
      );
      Navigator.popUntil(context, ModalRoute.withName('/'));
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Error desconocido';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ $error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verificar código"), backgroundColor: AppColors.azulOscuro),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text("Ingresa el código que te enviamos al correo:"),
            SizedBox(height: 16),
            TextField(
              controller: codigoController,
              decoration: InputDecoration(
                labelText: 'Código de 6 dígitos',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: nuevaPassController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nueva contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: confirmarRecuperacion,
              child: Text("Confirmar y cambiar"),
            ),
          ],
        ),
      ),
    );
  }
}