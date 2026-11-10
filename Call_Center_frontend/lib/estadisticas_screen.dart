import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app_drawer.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  bool isLoading = true;
  String? error;
  Map<String, dynamic>? data;

  int _barTouched = -1;
  int _pieTouched = -1;

  static const Color _bg = Color(0xFFEAF1F8);
  static const List<Color> _palette = [
    Color(0xFF3F51B5),
    Color(0xFF26A69A),
    Color(0xFFFFA726),
    Color(0xFFAB47BC),
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFF8D6E63),
  ];

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  Future<void> _cargarEstadisticas() async {
    try {
      final response =
          await http.get(Uri.parse('http://127.0.0.1:5000/estadisticas'));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (!mounted) return;
        setState(() {
          data = decoded as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          error = 'Error ${response.statusCode}: ${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Error de conexión: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text(
          'Estadísticas',
          style: TextStyle(color: Color(0xFF0D47A1)),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0D47A1)),
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0D47A1)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final total = data?['total_llamadas'] ?? 0;
    final promedio =
        ((data?['duracion_promedio_segundos'] ?? 0) as num).toDouble();
    final porMotivo = (data?['por_motivo'] as List?) ?? [];
    final porEstado = (data?['por_estado'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // IntrinsicHeight da una altura finita al Row dentro del scroll
              // (stretch en altura no acotada causaba "infinite height").
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _kpiCard(
                        icon: Icons.phone_in_talk,
                        color: const Color(0xFF3F51B5),
                        label: 'Total de llamadas',
                        value: '$total',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _kpiCard(
                        icon: Icons.timer_outlined,
                        color: const Color(0xFF26A69A),
                        label: 'Duración promedio',
                        value: '${promedio.toStringAsFixed(1)} s',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _chartCard(
                titulo: 'Llamadas por motivo',
                child: _buildBarChart(porMotivo),
              ),
              const SizedBox(height: 16),
              _chartCard(
                titulo: 'Llamadas por estado',
                child: _buildDonut(porEstado),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            FittedBox(
              child: Text(
                value,
                style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.bold, color: color),
              ),
            ),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _chartCard({required String titulo, required Widget child}) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  num _total(dynamic item) => (item['total'] as num?) ?? 0;

  String _label(dynamic item, String key) =>
      item[key]?.toString() ?? 'Sin definir';

  Widget _buildBarChart(List items) {
    if (items.isEmpty) {
      return const SizedBox(
          height: 120, child: Center(child: Text('Sin datos')));
    }
    final maxY = items.map(_total).reduce((a, b) => a > b ? a : b).toDouble();

    return SizedBox(
      height: 280,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2 + 1,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${_label(items[groupIndex], 'motivo')}\n',
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: '${rod.toY.toInt()} llamadas',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.normal),
                    ),
                  ],
                );
              },
            ),
            touchCallback: (event, response) {
              final idx = response?.spot?.touchedBarGroupIndex ?? -1;
              if (idx != _barTouched) setState(() => _barTouched = idx);
            },
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: maxY <= 5 ? 1 : null,
                getTitlesWidget: (value, meta) {
                  if (value != value.roundToDouble()) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(value.toInt().toString(),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black54)),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= items.length) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: SizedBox(
                      width: 70,
                      child: Text(
                        _label(items[i], 'motivo'),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black54),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(items.length, (i) {
            final touched = i == _barTouched;
            final color = _palette[i % _palette.length];
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: _total(items[i]).toDouble(),
                  color: touched ? color : color.withOpacity(0.8),
                  width: touched ? 26 : 22,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDonut(List items) {
    if (items.isEmpty) {
      return const SizedBox(
          height: 120, child: Center(child: Text('Sin datos')));
    }
    final suma = items.fold<num>(0, (a, b) => a + _total(b));

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 60,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      final idx =
                          response?.touchedSection?.touchedSectionIndex ?? -1;
                      if (idx != _pieTouched) {
                        setState(() => _pieTouched = idx);
                      }
                    },
                  ),
                  sections: List.generate(items.length, (i) {
                    final touched = i == _pieTouched;
                    final valor = _total(items[i]).toDouble();
                    final pct = suma == 0 ? 0 : valor / suma * 100;
                    return PieChartSectionData(
                      value: valor,
                      color: _palette[i % _palette.length],
                      radius: touched ? 60 : 50,
                      title: '${pct.toStringAsFixed(0)}%',
                      titleStyle: TextStyle(
                        fontSize: touched ? 16 : 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$suma',
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold)),
                  const Text('llamadas',
                      style: TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(items.length, (i) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _palette[i % _palette.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_label(items[i], 'estado_llamada')} (${_total(items[i])})',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
