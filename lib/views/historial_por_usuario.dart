import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';

class HistorialPorUsuarioView extends StatefulWidget {
  final String usuarioId;
  final String nombre;

  const HistorialPorUsuarioView({required this.usuarioId, required this.nombre});

  @override
  _HistorialPorUsuarioViewState createState() => _HistorialPorUsuarioViewState();
}

class _HistorialPorUsuarioViewState extends State<HistorialPorUsuarioView> {
  List<dynamic> transacciones = [];
  List<dynamic> transaccionesFiltradas = [];
  bool isLoading = true;

  int bajo = 0;
  int medio = 0;
  int alto = 0;
  String filtroSeleccionado = 'Todos';

  @override
  void initState() {
    super.initState();
    cargarYAnalizarTransacciones();
  }

  Future<void> cargarYAnalizarTransacciones() async {
    final url = Uri.parse('https://pucara-backend-final.onrender.com/api/transacciones/${widget.usuarioId}/');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final txs = jsonDecode(response.body);

      if (txs == null || txs.isEmpty) {
        setState(() {
          transacciones = [];
          transaccionesFiltradas = [];
          isLoading = false;
        });
        return;
      }

      // Enviar solo los IDs para mantener consistencia
      final ids = txs.where((tx) => tx['id'] != null).map((tx) => tx['id']).toList();

      final evalUrl = Uri.parse('https://pucara-backend-final.onrender.com/api/evaluar-fraude/');
      final evalResponse = await http.post(
        evalUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'ids': ids}),
      );

      if (evalResponse.statusCode == 200) {
        final resultado = jsonDecode(evalResponse.body);
        final analisis = resultado['resultado']['resultado'];

        final Map<String, dynamic> mapaResultados = {
          for (var tx in analisis) tx['id'].toString(): tx
        };

        final txsEvaluadas = <dynamic>[];
        bajo = medio = alto = 0;

        for (var tx in txs) {
          final idStr = tx['id'].toString();
          final analisisTx = mapaResultados[idStr];

          if (analisisTx != null) {
            final riesgo = analisisTx['nivel_riesgo'];
            if (riesgo is int && riesgo >= 1 && riesgo <= 3) {
              tx['nivel_riesgo'] = riesgo;
              txsEvaluadas.add(tx);

              if (riesgo == 1) bajo++;
              if (riesgo == 2) medio++;
              if (riesgo == 3) alto++;
            }
          }
        }

        setState(() {
          transacciones = txsEvaluadas;
          aplicarFiltro(filtroSeleccionado);
          isLoading = false;
        });
      } else {
        print('❌ Error al analizar riesgos');
        setState(() => isLoading = false);
      }
    } else {
      print('❌ Error al obtener transacciones del usuario');
      setState(() => isLoading = false);
    }
  }

  void aplicarFiltro(String filtro) {
    setState(() {
      filtroSeleccionado = filtro;

      if (filtro == 'Todos') {
        transaccionesFiltradas = transacciones;
      } else {
        int nivel = filtro == 'Bajo' ? 1 : filtro == 'Medio' ? 2 : 3;
        transaccionesFiltradas =
            transacciones.where((tx) => tx['nivel_riesgo'] == nivel).toList();
      }
    });
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
        return Colors.grey[200]!;
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

  Widget buildFiltroChips() {
    final opciones = ['Todos', 'Bajo', 'Medio', 'Alto'];
    return Wrap(
      spacing: 10,
      children: opciones.map((opcion) {
        final bool activo = filtroSeleccionado == opcion;
        return ChoiceChip(
          label: Text(opcion),
          selected: activo,
          onSelected: (_) => aplicarFiltro(opcion),
          selectedColor: AppColors.azulIntermedio,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Transacciones de ${widget.nombre}"),
        backgroundColor: AppColors.azulOscuro,
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
          if (bajo + medio + alto > 0)
            SizedBox(height: 160, child: buildPieChart()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: buildFiltroChips(),
          ),
          Expanded(
            child: transaccionesFiltradas.isEmpty
                ? Center(child: Text("No hay transacciones para este filtro."))
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: transaccionesFiltradas.length,
              itemBuilder: (context, index) {
                final tx = transaccionesFiltradas[index];
                final fechaFormateada = DateFormat('dd MMM yyyy').format(DateTime.parse(tx['fecha']));
                final monto = double.tryParse(tx['monto'].toString()) ?? 0;
                final riesgo = tx['nivel_riesgo'];

                return Card(
                  elevation: 5,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  color: getColorRiesgo(riesgo),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.attach_money, color: AppColors.azulIntermedio, size: 28),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tx['descripcion'] ?? 'Sin descripción',
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
                                color: monto > 1000 ? Colors.redAccent : AppColors.azulIntermedio,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("📅 $fechaFormateada", style: TextStyle(color: Colors.grey[700])),
                            Text("📍 TIPO: ${tx['ubicacionIP'] ?? 'N/A'}", style: TextStyle(color: Colors.grey[700])),
                            Text("🖥️ ${tx['dispositivoID'] ?? 'N/A'}", style: TextStyle(color: Colors.grey[700])),
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





