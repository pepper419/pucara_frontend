import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme.dart';
import '../presentation/widgets/app_drawer.dart';

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String nombreUsuario = '';
  String searchQuery = '';
  bool mostrarMasOpciones = false;
  List<FlSpot> puntosGastos = [];
  bool graficoCargado = false;
  List<dynamic> notificaciones = [];
  bool tieneNotificacionesNoLeidas = false;
  Set<String> transaccionesAlertaMostradas = {};
  Timer? _timer;

  final List<_HomeCardItem> opciones = [
    _HomeCardItem(icon: Icons.history, title: "Historial", route: '/historial', color: Colors.lightBlue),
    _HomeCardItem(icon: Icons.school, title: "Educación", route: '/educacion', color: Colors.blueAccent),
    _HomeCardItem(icon: Icons.quiz, title: "Cuestionario", route: '/cuestionario', color: Colors.cyan),
    _HomeCardItem(icon: Icons.more_horiz, title: "Más", route: '/mas', color: Colors.indigo),
    _HomeCardItem(icon: Icons.person, title: "Perfil", route: '/perfil', color: Colors.deepPurple),
  ];

  @override
  void initState() {
    super.initState();
    cargarNombreUsuario();
    cargarDatosGrafico();
    actualizarDatosPeriodicamente();
  }

  void actualizarDatosPeriodicamente() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 3), (_) async {
      await cargarDatosGrafico();
      await cargarNotificaciones();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> cargarNombreUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString('nombre') ?? 'Usuario';
    setState(() {
      nombreUsuario = nombre;
    });
  }

  Future<void> cargarDatosGrafico() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final url = Uri.parse('https://pucara-backend-final.onrender.com/api/transacciones/$token/');
    final resp = await http.get(url);

    if (resp.statusCode == 200) {
      final datos = jsonDecode(resp.body);
      final Map<String, double> gastoPorDia = {};

      for (var tx in datos) {
        final fecha = tx['fecha'].substring(0, 10);
        final monto = double.tryParse(tx['monto'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
        gastoPorDia.update(fecha, (valor) => valor + monto, ifAbsent: () => monto);
      }

      final fechas = gastoPorDia.keys.toList()..sort();
      puntosGastos = List.generate(fechas.length, (i) => FlSpot(i.toDouble(), gastoPorDia[fechas[i]] ?? 0));

      setState(() {
        graficoCargado = true;
      });
    }
  }

  Future<void> cargarNotificaciones() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final transaccionesUrl = Uri.parse('https://pucara-backend-final.onrender.com/api/api/transacciones/$token/');
    final transResp = await http.get(transaccionesUrl);

    if (transResp.statusCode == 200) {
      final datos = jsonDecode(transResp.body);

      final evaluarUrl = Uri.parse('https://pucara-backend-final.onrender.com/api/evaluar-fraude/');
      final evaluarResp = await http.post(
        evaluarUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'transacciones': datos}),
      );

      if (evaluarResp.statusCode == 200) {
        final evaluacion = jsonDecode(evaluarResp.body);
        final resultados = evaluacion['resultado']['resultado'];

        final notis = resultados.where((tx) {
          final nivel = int.tryParse(tx['nivel_riesgo'].toString()) ?? 0;
          return nivel == 2 || nivel == 3;
        }).toList();

        final yaLeido = prefs.getBool('notificaciones_leidas') ?? false;

        setState(() {
          notificaciones = notis;
          tieneNotificacionesNoLeidas = notis.isNotEmpty && !yaLeido;
        });

        for (var tx in resultados) {
          final nivel = int.tryParse(tx['nivel_riesgo'].toString()) ?? 0;
          final uid = tx['fecha'].toString() + tx['descripcion'].toString() + tx['monto'].toString();
          if (nivel == 3 && !transaccionesAlertaMostradas.contains(uid)) {
            transaccionesAlertaMostradas.add(uid);
            Future.delayed(Duration.zero, () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('⚠️ ALERTA MÁXIMA'),
                  content: Text('Se ha detectado una transacción de riesgo ALTO (nivel 3). Podría tratarse de un intento de CARDING. Por favor, revisa tu historial de inmediato.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cerrar'),
                    ),
                  ],
                ),
              );
            });
          }
        }
      } else {
        print("❌ Error evaluando fraude: ${evaluarResp.statusCode} - ${evaluarResp.body}");
      }
    } else {
      print("❌ Error cargando transacciones: ${transResp.statusCode} - ${transResp.body}");
    }
  }

  void marcarNotificacionesComoLeidas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificaciones_leidas', true);
    setState(() => tieneNotificacionesNoLeidas = false);
  }

  void mostrarNotificaciones() {
    marcarNotificacionesComoLeidas();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        maxChildSize: 0.8,
        initialChildSize: 0.6,
        minChildSize: 0.3,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("🔔 Notificaciones de Riesgo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                if (notificaciones.isEmpty)
                  Text("No hay transacciones sospechosas recientes."),
                for (var tx in notificaciones)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("• ${tx['descripcion'] ?? 'Sin descripción'}", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("  Monto: S/ ${tx['monto']}"),
                        Text("  IP: ${tx['ubicacionIP'] ?? 'N/A'}"),
                        Text("  Riesgo: Nivel ${tx['nivel_riesgo']}"),
                        Divider(),
                      ],
                    ),
                  ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    child: Text("Cerrar"),
                    onPressed: () => Navigator.pop(context),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_HomeCardItem> getOpcionesFiltradas() {
    if (searchQuery.isEmpty) return opciones;
    return opciones.where((item) => item.title.toLowerCase().contains(searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final opcionesFiltradas = getOpcionesFiltradas();

    return Scaffold(
      drawer: AppDrawer(nombreUsuario: nombreUsuario),
      backgroundColor: Color(0xFFE8F0FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("PUCARA", style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: Colors.blue[900]),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none_outlined),
                onPressed: mostrarNotificaciones,
              ),
              if (tieneNotificacionesNoLeidas)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ListView(
          children: [
            Text("Hola, $nombreUsuario 👋", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.blue[900])),
            SizedBox(height: 8),
            Text("Encuentra herramientas para prevenir fraudes", style: TextStyle(color: Colors.blueGrey)),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: InputDecoration(
                  hintText: "Buscar funcionalidades...",
                  border: InputBorder.none,
                  icon: Icon(Icons.search),
                ),
              ),
            ),
            SizedBox(height: 20),
            if (!mostrarMasOpciones) ...[
              Text("Opciones", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue[900])),
              SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: opcionesFiltradas.length,
                  itemBuilder: (context, index) {
                    final item = opcionesFiltradas[index];
                    return GestureDetector(
                      onTap: () {
                        if (item.title == "Más") {
                          setState(() => mostrarMasOpciones = true);
                        } else {
                          Navigator.pushNamed(context, item.route);
                        }
                      },
                      child: Container(
                        width: 100,
                        margin: EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              backgroundColor: item.color,
                              child: Icon(item.icon, color: Colors.white),
                            ),
                            SizedBox(height: 10),
                            Text(item.title, style: TextStyle(fontWeight: FontWeight.w500))
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              Center(
                child: Column(
                  children: [
                    for (var item in opciones.where((item) => item.title != "Más"))
                      _buildMainOption(item),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => mostrarMasOpciones = false),
                      icon: Icon(Icons.arrow_back),
                      label: Text("Volver"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    )
                  ],
                ),
              )
            ],
            SizedBox(height: 30),
            Text("Evolución de tus gastos 💸", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue[900])),
            SizedBox(
              height: 200,
              child: graficoCargado
                  ? Padding(
                padding: const EdgeInsets.only(top: 12),
                child: LineChart(LineChartData(
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: puntosGastos,
                      isCurved: true,
                      color: Colors.blue,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                  ],
                )),
              )
                  : Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainOption(_HomeCardItem item) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, item.route),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 10),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: item.color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: item.color, child: Icon(item.icon, color: Colors.white)),
            SizedBox(width: 20),
            Text(item.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900]))
          ],
        ),
      ),
    );
  }
}

class _HomeCardItem {
  final IconData icon;
  final String title;
  final String route;
  final Color color;

  _HomeCardItem({required this.icon, required this.title, required this.route, required this.color});
}





