import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PerfilView extends StatefulWidget {
  @override
  _PerfilViewState createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  String nombre = '';
  String email = '';
  String rol = '';
  String token = '';
  String estadoCuenta = '';
  String fechaCreacion = '';
  String ultimaActualizacion = '';

  Map<String, dynamic>? ultimaTransaccion;

  bool cargando = true;
  bool editandoNombre = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();

  String mensajeEstado = '';
  Color colorMensaje = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    setState(() {
      cargando = true;
      mensajeEstado = '';
      colorMensaje = Colors.transparent;
    });

    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('token');
    if (storedToken == null) {
      setState(() {
        cargando = false;
        mensajeEstado = "No se encontró token de autenticación.";
        colorMensaje = Colors.red;
      });
      return;
    }

    setState(() => token = storedToken);

    try {
      final urlUsuario = Uri.parse('https://pucara-backend-final.onrender.com/api/usuarios/$token/');
      final resUsuario = await http.get(urlUsuario);

      if (resUsuario.statusCode == 200) {
        final data = jsonDecode(resUsuario.body);

        setState(() {
          nombre = data['nombre'] ?? '';
          email = data['email'] ?? '';
          rol = data['rol'] ?? '';
          estadoCuenta = data['estado'] ?? 'Activo';
          fechaCreacion = data['fecha_creacion'] ?? '';
          ultimaActualizacion = data['ultima_actualizacion'] ?? '';
          _nombreController.text = nombre;
        });
      } else {
        setState(() {
          mensajeEstado = "Error al cargar datos del usuario (${resUsuario.statusCode})";
          colorMensaje = Colors.red;
        });
      }

      final urlTransacciones = Uri.parse('https://pucara-backend-final.onrender.com/api/transacciones/$token/');
      final resTrans = await http.get(urlTransacciones);

      if (resTrans.statusCode == 200) {
        final lista = jsonDecode(resTrans.body);
        if (lista.isNotEmpty) {
          setState(() {
            ultimaTransaccion = lista.first;
          });
        }
      }
    } catch (e) {
      setState(() {
        mensajeEstado = "Error en la conexión o datos inválidos.";
        colorMensaje = Colors.red;
      });
    }

    setState(() => cargando = false);
  }

  Future<void> _guardarNombre() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      mensajeEstado = '';
      colorMensaje = Colors.transparent;
    });

    final nuevoNombre = _nombreController.text.trim();

    try {
      final urlUpdate = Uri.parse('https://pucara-backend-final.onrender.com/api/usuarios/$token/actualizar-nombre/');
      final response = await http.put(
        urlUpdate,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nombre': nuevoNombre}),
      );

      if (response.statusCode == 200) {
        setState(() {
          nombre = nuevoNombre;
          editandoNombre = false;
          mensajeEstado = "Nombre actualizado con éxito.";
          colorMensaje = Colors.green;
        });

        // Guardar nombre actualizado en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('nombre', nuevoNombre);
      } else {
        setState(() {
          mensajeEstado = "Error actualizando nombre (${response.statusCode}).";
          colorMensaje = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        mensajeEstado = "Error en la conexión.";
        colorMensaje = Colors.red;
      });
    }
  }

  void _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  Color _getColorRiesgo(int? riesgo) {
    switch (riesgo) {
      case 1:
        return Colors.green[100]!;
      case 2:
        return Colors.yellow[200]!;
      case 3:
        return Colors.red[200]!;
      default:
        return Colors.grey[100]!;
    }
  }

  IconData _iconoRiesgo(int? riesgo) {
    switch (riesgo) {
      case 1:
        return Icons.check_circle;
      case 2:
        return Icons.error;
      case 3:
        return Icons.warning;
      default:
        return Icons.help_outline;
    }
  }

  Color _colorTextoRiesgo(int? riesgo) {
    switch (riesgo) {
      case 1:
        return Colors.green[800]!;
      case 2:
        return Colors.orange[800]!;
      case 3:
        return Colors.red[800]!;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoUsuario() {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.blue.shade900,
          child: Text(
            rol.isNotEmpty ? rol[0].toUpperCase() : '?',
            style: TextStyle(fontSize: 50, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        editandoNombre ? _buildFormularioNombre() : _buildNombreDisplay(),
        const SizedBox(height: 8),
        Text(email, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        const SizedBox(height: 6),
        Chip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.badge, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(rol.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Colors.blue.shade700,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Estado de la cuenta: ", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(estadoCuenta, style: TextStyle(color: estadoCuenta.toLowerCase() == 'activo' ? Colors.green : Colors.red)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "Creado el: ${fechaCreacion.isNotEmpty ? fechaCreacion.substring(0, 10) : 'N/D'}",
          style: TextStyle(color: Colors.grey[600]),
        ),
        Text(
          "Última actualización: ${ultimaActualizacion.isNotEmpty ? ultimaActualizacion.substring(0, 10) : 'N/D'}",
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildNombreDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(nombre, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.edit, color: Colors.blue.shade700),
          tooltip: 'Editar nombre',
          onPressed: () {
            setState(() => editandoNombre = true);
          },
        )
      ],
    );
  }

  Widget _buildFormularioNombre() {
    return Form(
      key: _formKey,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 200,
            child: TextFormField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: 'Nuevo nombre',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingrese un nombre válido';
                }
                if (value.trim().length < 3) {
                  return 'Mínimo 3 caracteres';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _guardarNombre,
            child: const Text('Guardar'),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.cancel, color: Colors.red.shade400),
            tooltip: 'Cancelar',
            onPressed: () {
              setState(() {
                editandoNombre = false;
                _nombreController.text = nombre;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUltimaTransaccion() {
    if (ultimaTransaccion == null) {
      return const Text("No hay transacciones recientes.");
    }

    final riesgo = ultimaTransaccion!['nivel_riesgo'] as int?;
    final colorCard = _getColorRiesgo(riesgo);
    final icono = _iconoRiesgo(riesgo);
    final colorTexto = _colorTextoRiesgo(riesgo);

    return Card(
      color: colorCard,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Icon(icono, color: colorTexto, size: 28),
              const SizedBox(width: 10),
              Text(
                "Nivel de Riesgo: $riesgo",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorTexto,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text("${ultimaTransaccion!['descripcion']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text("Monto: S/ ${ultimaTransaccion!['monto']}", style: const TextStyle(fontSize: 14)),
          Text("Fecha: ${ultimaTransaccion!['fecha'].toString().substring(0, 10)}", style: const TextStyle(fontSize: 14)),
          Text("Dispositivo: ${ultimaTransaccion!['dispositivoID'] ?? 'N/A'}", style: const TextStyle(fontSize: 14)),
          Text("IP: ${ultimaTransaccion!['ubicacionIP'] ?? 'N/A'}", style: const TextStyle(fontSize: 14)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Usuario'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _cargarDatosUsuario,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildInfoUsuario(),
              const SizedBox(height: 30),
              if (mensajeEstado.isNotEmpty)
                Text(mensajeEstado, style: TextStyle(color: colorMensaje, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Divider(thickness: 1.5),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Token de acceso', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              SelectableText(token, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              const SizedBox(height: 20),
              const Divider(thickness: 1.5),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Última Transacción', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(height: 10),
              _buildUltimaTransaccion(),
            ],
          ),
        ),
      ),
    );
  }
}
