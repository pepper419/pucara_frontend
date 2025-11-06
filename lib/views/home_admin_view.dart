import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import 'historial_por_usuario.dart';

class HomeAdminView extends StatefulWidget {
  @override
  _HomeAdminViewState createState() => _HomeAdminViewState();
}

class _HomeAdminViewState extends State<HomeAdminView> {
  List<dynamic> usuarios = [];
  List<dynamic> usuariosFiltrados = [];
  Map<String, List<int>> riesgosPorUsuario = {};
  bool isLoading = true;
  int? filtroActivo;
  String filtroTexto = '';

  @override
  void initState() {
    super.initState();
    cargarUsuariosYAnalisis();
  }

  Future<void> cargarUsuariosYAnalisis() async {
    setState(() {
      isLoading = true;
      riesgosPorUsuario.clear();
    });

    final url = Uri.parse('https://pucara-backend-final.onrender.com/api/api/usuarios/listaobtener/');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final usuariosDecodificados = jsonDecode(response.body);
      setState(() {
        usuarios = usuariosDecodificados;
        aplicarFiltroTexto(filtroTexto); // Filtrar inmediatamente
      });

      for (var usuario in usuariosDecodificados) {
        final id = usuario['id']?.toString() ?? '';
        if (id.isEmpty) continue;

        final riesgos = await obtenerYEvaluarRiesgos(id);
        setState(() => riesgosPorUsuario[id] = riesgos);
      }

      setState(() => isLoading = false);
    } else {
      print('❌ Error al cargar usuarios: ${response.body}');
      setState(() => isLoading = false);
    }
  }

  Future<List<int>> obtenerYEvaluarRiesgos(String usuarioId) async {
    final transUrl = Uri.parse('https://pucara-backend-final.onrender.com/api/transacciones/$usuarioId/');
    final transResp = await http.get(transUrl);

    if (transResp.statusCode != 200) {
      print('❌ Error cargando transacciones');
      return [];
    }

    final transacciones = jsonDecode(transResp.body);
    if (transacciones.isEmpty) return [];

    final evalUrl = Uri.parse('https://pucara-backend-final.onrender.com/api/evaluar-fraude/');
    final evalResp = await http.post(
      evalUrl,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'ids': transacciones.map((t) => t['id']).toList()}),
    );

    if (evalResp.statusCode == 200) {
      final resultado = jsonDecode(evalResp.body);
      final analisis = resultado['resultado']['resultado'];
      final riesgos = <int>[];

      for (var tx in analisis) {
        final riesgo = tx['nivel_riesgo'];
        if (riesgo is int && riesgo >= 1 && riesgo <= 3) {
          riesgos.add(riesgo);
        }
      }

      return riesgos;
    } else {
      print('❌ Error analizando riesgos: ${evalResp.body}');
      return [];
    }
  }

  void aplicarFiltroTexto(String valor) {
    setState(() {
      filtroTexto = valor.toLowerCase();
      usuariosFiltrados = usuarios.where((u) {
        final nombre = (u['nombre'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        return nombre.contains(filtroTexto) || email.contains(filtroTexto);
      }).toList();
    });
  }

  Color getColorDeRiesgo(List<int> riesgos) {
    if (riesgos.contains(3)) return Colors.red[100]!;
    if (riesgos.contains(2)) return Colors.orange[100]!;
    if (riesgos.contains(1)) return Colors.green[100]!;
    return Colors.white;
  }

  Widget construirGraficoDeBarras(List<int> riesgos) {
    final riesgosPorNivel = [0, 0, 0];
    for (var r in riesgos) {
      if (r >= 1 && r <= 3) riesgosPorNivel[r - 1]++;
    }

    final maxY = (riesgosPorNivel.reduce((a, b) => a > b ? a : b).toDouble() + 1);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                switch (value.toInt()) {
                  case 0:
                    return Text('Bajo');
                  case 1:
                    return Text('Medio');
                  case 2:
                    return Text('Alto');
                  default:
                    return Text('');
                }
              },
            ),
          ),
        ),
        barGroups: List.generate(3, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: riesgosPorNivel[index].toDouble(),
                color: index == 0
                    ? Colors.green
                    : index == 1
                    ? Colors.orangeAccent
                    : Colors.red,
                width: 18,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget construirLeyenda() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        leyendaColor(Colors.green, 'Riesgo Bajo'),
        leyendaColor(Colors.orangeAccent, 'Riesgo Medio'),
        leyendaColor(Colors.red, 'Riesgo Alto'),
      ],
    );
  }

  Widget leyendaColor(Color color, String texto) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        SizedBox(width: 6),
        Text(texto),
      ],
    );
  }

  Widget botonesDeFiltro() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        filtroBoton("Todos", null),
        filtroBoton("Bajo", 1),
        filtroBoton("Medio", 2),
        filtroBoton("Alto", 3),
      ],
    );
  }

  Widget filtroBoton(String label, int? nivel) {
    final esActivo = filtroActivo == nivel;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: esActivo ? Colors.blueAccent : Colors.grey[300],
        foregroundColor: esActivo ? Colors.white : Colors.black,
      ),
      onPressed: () {
        setState(() {
          filtroActivo = nivel;
        });
      },
      child: Text(label),
    );
  }

  Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel de Auditoría'),
        backgroundColor: AppColors.azulOscuro,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: AppColors.azulIntermedio),
              child: Text(
                'Administrador',
                style: TextStyle(fontSize: 22, color: Colors.white),
              ),
            ),
            ListTile(
              leading: Icon(Icons.refresh, color: Colors.blue),
              title: Text('Actualizar'),
              onTap: () {
                Navigator.pop(context);
                cargarUsuariosYAnalisis();
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.red),
              title: Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
              onTap: cerrarSesion,
            ),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar por nombre o email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: aplicarFiltroTexto,
            ),
          ),
          SizedBox(height: 10),
          botonesDeFiltro(),
          SizedBox(height: 10),
          Expanded(
            child: usuariosFiltrados.isEmpty
                ? Center(child: Text('No se encontraron resultados.'))
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: usuariosFiltrados.length,
              itemBuilder: (context, index) {
                final usuario = usuariosFiltrados[index];
                final nombre = (usuario['nombre'] ?? 'Usuario sin nombre').toString();
                final email = (usuario['email'] ?? 'Sin email').toString();
                final id = usuario['id']?.toString() ?? '';
                final riesgos = riesgosPorUsuario[id] ?? [];

                if (filtroActivo != null && !riesgos.contains(filtroActivo)) {
                  return SizedBox.shrink();
                }

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 6,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  color: getColorDeRiesgo(riesgos),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            nombre,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Text(email),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HistorialPorUsuarioView(
                                  usuarioId: id,
                                  nombre: nombre,
                                ),
                              ),
                            );
                          },
                        ),
                        if (riesgos.isNotEmpty) ...[
                          Divider(height: 20),
                          Text(
                            "Distribución de Niveles de Riesgo",
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          SizedBox(height: 200, child: construirGraficoDeBarras(riesgos)),
                          SizedBox(height: 12),
                          construirLeyenda(),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}












