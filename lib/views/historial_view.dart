import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';

class HistorialView extends StatefulWidget {
  @override
  _HistorialViewState createState() => _HistorialViewState();
}

class _HistorialViewState extends State<HistorialView> {
  List<dynamic> transacciones = [];
  bool isLoading = true;
  bool ordenarDescendente = true;
  bool ordenarFechaDescendente = true;

  int bajo = 0;
  int medio = 0;
  int alto = 0;

  @override
  void initState() {
    super.initState();
    cargarTransacciones();
  }

  Future<void> cargarTransacciones() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    final transaccionesUrl =
    Uri.parse('https://pucara-backend-final.onrender.com/api/transacciones/$token/');
    final response = await http.get(transaccionesUrl);

    if (response.statusCode == 200) {
      setState(() {
        transacciones = jsonDecode(response.body);
        ordenarPorMonto();
        isLoading = false;
      });
    }
  }

  void ordenarPorMonto() {
    transacciones.sort((a, b) {
      final montoA = double.tryParse(a['monto'].toString()) ?? 0;
      final montoB = double.tryParse(b['monto'].toString()) ?? 0;
      return ordenarDescendente ? montoB.compareTo(montoA) : montoA.compareTo(montoB);
    });
  }

  void ordenarPorFecha() {
    transacciones.sort((a, b) {
      final fechaA = a['fecha'] != null && a['fecha'] is String
          ? DateTime.tryParse(a['fecha'])
          : null;
      final fechaB = b['fecha'] != null && b['fecha'] is String
          ? DateTime.tryParse(b['fecha'])
          : null;

      if (fechaA == null && fechaB == null) return 0;
      if (fechaA == null) return 1;
      if (fechaB == null) return -1;

      return ordenarFechaDescendente ? fechaB.compareTo(fechaA) : fechaA.compareTo(fechaB);
    });
  }

  Future<void> analizarTransacciones() async {
    final uri = Uri.parse('https://pucara-backend-final.onrender.com/api/evaluar-fraude/');

    final transaccionesConId = transacciones.where((tx) => tx['id'] != null).toList();
    if (transaccionesConId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No hay transacciones válidas para analizar.")),
      );
      return;
    }

    final ids = transaccionesConId.map((tx) => tx['id']).toList();
    final body = jsonEncode({'ids': ids});

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final resultado = jsonDecode(response.body);
        final resultadosAnalisis = resultado['resultado']['resultado'];

        // 🔁 Convertimos a Map<String, dynamic> usando id.toString()
        final Map<String, dynamic> mapaResultados = {
          for (var tx in resultadosAnalisis) tx['id'].toString(): tx
        };

        setState(() {
          bajo = medio = alto = 0;

          for (var tx in transacciones) {
            final idStr = tx['id'].toString();
            final analisis = mapaResultados[idStr];
            if (analisis != null) {
              tx['nivel_riesgo'] = analisis['nivel_riesgo'];
              if (analisis['nivel_riesgo'] == 1) bajo++;
              if (analisis['nivel_riesgo'] == 2) medio++;
              if (analisis['nivel_riesgo'] == 3) alto++;
            }
          }
        });
      } else {
        print('⚠️ Error al analizar transacciones: ${response.statusCode}');
        print(response.body);
      }
    } catch (e) {
      print('❌ Excepción al analizar transacciones: $e');
    }
  }

  Color getColorRiesgo(int? riesgo) {
    switch (riesgo) {
      case 1:
        return Colors.green[100]!;
      case 2:
        return Colors.yellow[200]!;
      case 3:
        return Colors.red[200]!;
      default:
        return Colors.white;
    }
  }

  Widget buildPieChart() {
    final total = bajo + medio + alto;
    if (total == 0) return SizedBox();

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          if (bajo > 0)
            PieChartSectionData(
              color: Colors.green[400],
              value: bajo.toDouble(),
              title: '$bajo',
              radius: 50,
              titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          if (medio > 0)
            PieChartSectionData(
              color: Colors.yellow[600],
              value: medio.toDouble(),
              title: '$medio',
              radius: 50,
              titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          if (alto > 0)
            PieChartSectionData(
              color: Colors.red[400],
              value: alto.toDouble(),
              title: '$alto',
              radius: 50,
              titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 6),
        Text(label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final transaccionesValidas = transacciones.where((tx) {
      return tx['descripcion'] != null &&
          tx['descripcion'].toString().trim().isNotEmpty &&
          tx['monto'] != null &&
          double.tryParse(tx['monto'].toString()) != null &&
          tx['fecha'] != null;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Historial de Transacciones"),
        actions: [
          IconButton(
            icon: Icon(Icons.analytics, color: Colors.white),
            tooltip: "Analizar transacciones",
            onPressed: analizarTransacciones,
          ),
          IconButton(
            icon: Icon(
              ordenarDescendente ? Icons.arrow_downward : Icons.arrow_upward,
              color: Colors.white,
            ),
            tooltip: "Ordenar por monto",
            onPressed: () {
              setState(() {
                ordenarDescendente = !ordenarDescendente;
                ordenarPorMonto();
              });
            },
          ),
          IconButton(
            icon: Icon(
              ordenarFechaDescendente ? Icons.schedule : Icons.history,
              color: Colors.white,
            ),
            tooltip: "Ordenar por fecha",
            onPressed: () {
              setState(() {
                ordenarFechaDescendente = !ordenarFechaDescendente;
                ordenarPorFecha();
              });
            },
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildLegend("Bajo", Colors.green[300]!),
                buildLegend("Medio", Colors.yellow[700]!),
                buildLegend("Alto", Colors.red[400]!),
              ],
            ),
          ),
          SizedBox(height: 10),
          if (bajo + medio + alto > 0)
            SizedBox(
              height: 160,
              child: buildPieChart(),
            ),
          SizedBox(height: 10),
          Expanded(
            child: transaccionesValidas.isEmpty
                ? Center(child: Text("No hay transacciones válidas para mostrar."))
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: transaccionesValidas.length,
              itemBuilder: (context, index) {
                final tx = transaccionesValidas[index];
                final descripcion = tx['descripcion'].toString();
                final monto = double.tryParse(tx['monto'].toString()) ?? 0;
                final riesgo = tx['nivel_riesgo'];
                final ip = (tx['ubicacionIP'] ?? 'N/A').toString();
                final dispositivo = (tx['dispositivoID'] ?? 'N/A').toString();

                String fechaFormateada = 'Fecha inválida';
                if (tx['fecha'] != null) {
                  try {
                    fechaFormateada = DateFormat('dd MMM yyyy').format(DateTime.parse(tx['fecha']));
                  } catch (_) {}
                }

                return Card(
                  elevation: 6,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  color: getColorRiesgo(riesgo),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.attach_money,
                                color: AppColors.azulIntermedio, size: 28),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                descripcion,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.azulOscuro,
                                ),
                              ),
                            ),
                            Text(
                              'S/ ${monto.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: monto > 1000
                                    ? Colors.redAccent
                                    : AppColors.azulIntermedio,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("📅 $fechaFormateada",
                                style: TextStyle(color: Colors.grey[700])),
                            Text("📍 TIPO: $ip",
                                style: TextStyle(color: Colors.grey[700])),
                            Text("🖥️ $dispositivo",
                                style: TextStyle(color: Colors.grey[700])),
                          ],
                        ),
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








