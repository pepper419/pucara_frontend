import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/theme.dart';
import 'verificar_codigo_view.dart';

class RecuperarView extends StatefulWidget {
  @override
  _RecuperarViewState createState() => _RecuperarViewState();
}

class _RecuperarViewState extends State<RecuperarView> {
  final emailController = TextEditingController();
  bool isLoading = false;

  Future<void> enviarCorreoRecuperacion() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ingresa tu correo.')));
      return;
    }

    setState(() => isLoading = true);
    final response = await http.post(
      Uri.parse('https://pucara-backend-final.onrender.com/api/api/recuperar-password/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('📧 Código enviado al correo si existe.')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificarCodigoView(email: email),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: ${jsonDecode(response.body)['error'] ?? 'Error'}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Recuperar contraseña"), backgroundColor: AppColors.azulOscuro),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text("Ingresa tu correo electrónico para restablecer tu contraseña."),
            SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Correo",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: enviarCorreoRecuperacion,
              child: Text("Enviar correo de recuperación"),
            )
          ],
        ),
      ),
    );
  }
}