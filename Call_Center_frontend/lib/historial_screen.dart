import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app_drawer.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  static const Color _azul = Color(0xFF253B6E);
  static const Color _fondo = Color(0xFFD6E8F0);
  static const String _baseUrl = 'http://127.0.0.1:5000';

  List<Map<String, dynamic>> _historial = [];
  List<Map<String, dynamic>> _filtrados = [];
  bool _cargando = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final response = await http.get(Uri.parse('$_baseUrl/historial_llamadas'));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        setState(() {
          _historial = decoded
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _aplicarFiltro();
          _cargando = false;
        });
      } else {
        setState(() {
          _error = 'Error ${response.statusCode}: ${response.body}';
          _cargando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error de conexión: $e';
        _cargando = false;
      });
    }
  }

  String _orden = 'recientes';
  DateTime? _fechaFiltro;
  String? _motivoFiltro;
  String? _estadoFiltro;

  DateTime? _parseFecha(dynamic valor) {
    if (valor == null) return null;
    final texto = valor.toString();
    final iso = DateTime.tryParse(texto);
    if (iso != null) return iso;
    const meses = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final m = RegExp(r'(\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2})')
        .firstMatch(texto);
    if (m != null && meses.containsKey(m.group(2))) {
      return DateTime(
        int.parse(m.group(3)!),
        meses[m.group(2)]!,
        int.parse(m.group(1)!),
        int.parse(m.group(4)!),
        int.parse(m.group(5)!),
        int.parse(m.group(6)!),
      );
    }
    return null;
  }

  List<String> _opcionesDe(String campo) {
    final valores = _historial
        .map((e) => (e[campo] ?? '').toString())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList();
    valores.sort();
    return valores;
  }

  bool get _hayFiltrosActivos =>
      _orden != 'recientes' ||
      _fechaFiltro != null ||
      _motivoFiltro != null ||
      _estadoFiltro != null;

  void _aplicarFiltro() {
    final q = _query.trim().toLowerCase();
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);

    final lista = _historial.where((c) {
      if (q.isNotEmpty) {
        final nombre = (c['nombre_completo'] ?? '').toString().toLowerCase();
        if (!nombre.contains(q)) return false;
      }
      if (_fechaFiltro != null) {
        final f = _parseFecha(c['fecha_llamada']);
        if (f == null ||
            f.year != _fechaFiltro!.year ||
            f.month != _fechaFiltro!.month ||
            f.day != _fechaFiltro!.day) {
          return false;
        }
      }
      if (_motivoFiltro != null &&
          (c['motivo'] ?? '').toString() != _motivoFiltro) {
        return false;
      }
      if (_estadoFiltro != null &&
          (c['estado_llamada'] ?? '').toString() != _estadoFiltro) {
        return false;
      }
      return true;
    }).toList();

    int duracion(Map<String, dynamic> e) =>
        int.tryParse((e['duracion_segundos'] ?? 0).toString()) ?? 0;

    lista.sort((a, b) {
      final fa = _parseFecha(a['fecha_llamada']) ?? epoch;
      final fb = _parseFecha(b['fecha_llamada']) ?? epoch;
      switch (_orden) {
        case 'antiguas':
          return fa.compareTo(fb);
        case 'duracion':
          return duracion(b).compareTo(duracion(a));
        default:
          return fb.compareTo(fa);
      }
    });
    _filtrados = lista;
  }

  void _mostrarFiltros() {
    String orden = _orden;
    DateTime? fecha = _fechaFiltro;
    String? motivo = _motivoFiltro;
    String? estado = _estadoFiltro;
    final motivos = _opcionesDe('motivo');
    final estados = _opcionesDe('estado_llamada');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget titulo(String t) => Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 4),
                  child: Text(t,
                      style: const TextStyle(
                          color: _azul,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                );

            Widget dropdown(String hint, String? valor, List<String> opciones,
                void Function(String?) onChanged) {
              return DropdownButtonFormField<String>(
                initialValue: opciones.contains(valor) ? valor : null,
                isExpanded: true,
                hint: Text(hint),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _azul),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _azul, width: 1.5),
                  ),
                ),
                items: [
                  DropdownMenuItem<String>(
                      value: null, child: Text('Todos')),
                  ...opciones.map(
                      (o) => DropdownMenuItem<String>(value: o, child: Text(o))),
                ],
                onChanged: (v) => setSheetState(() => onChanged(v)),
              );
            }

            Widget radio(String valor, String texto) => RadioListTile<String>(
                  value: valor,
                  groupValue: orden,
                  title: Text(texto),
                  activeColor: _azul,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setSheetState(() => orden = v!),
                );

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text('Ordenar y Filtrar',
                          style: TextStyle(
                              color: _azul,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                    ),
                    titulo('Ordenar por'),
                    radio('recientes', 'Más recientes'),
                    radio('antiguas', 'Más antiguas'),
                    radio('duracion', 'Mayor duración'),
                    titulo('Fecha'),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _azul,
                        side: const BorderSide(color: _azul),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(fecha == null
                          ? 'Seleccionar día'
                          : '${fecha!.day.toString().padLeft(2, '0')}/${fecha!.month.toString().padLeft(2, '0')}/${fecha!.year}'),
                      onPressed: () async {
                        final elegido = await showDatePicker(
                          context: sheetContext,
                          initialDate: fecha ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (elegido != null) {
                          setSheetState(() => fecha = elegido);
                        }
                      },
                    ),
                    titulo('Motivo'),
                    dropdown('Todos', motivo, motivos, (v) => motivo = v),
                    titulo('Estado'),
                    dropdown('Todos', estado, estados, (v) => estado = v),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _azul,
                              side: const BorderSide(color: _azul),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () {
                              setState(() {
                                _orden = 'recientes';
                                _fechaFiltro = null;
                                _motivoFiltro = null;
                                _estadoFiltro = null;
                                _aplicarFiltro();
                              });
                              Navigator.pop(sheetContext);
                            },
                            child: const Text('Limpiar Filtros'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _azul,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () {
                              setState(() {
                                _orden = orden;
                                _fechaFiltro = fecha;
                                _motivoFiltro = motivo;
                                _estadoFiltro = estado;
                                _aplicarFiltro();
                              });
                              Navigator.pop(sheetContext);
                            },
                            child: const Text('Aplicar Filtros'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatearDuracion(dynamic valor) {
    final total = int.tryParse((valor ?? 0).toString()) ?? 0;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    String dos(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '${dos(h)}:${dos(m)}:${dos(s)}' : '${dos(m)}:${dos(s)}';
  }

  String _formatearFecha(dynamic valor) {
    if (valor == null) return '';
    final texto = valor.toString();
    String dos(int n) => n.toString().padLeft(2, '0');
    String fmt(DateTime d) =>
        '${dos(d.day)}/${dos(d.month)}/${d.year} ${dos(d.hour)}:${dos(d.minute)}';

    final iso = DateTime.tryParse(texto);
    if (iso != null) return fmt(iso.toLocal());

    // Formato HTTP (RFC 1123) que genera jsonify: "Tue, 10 Nov 2026 19:35:00 GMT"
    const meses = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final m = RegExp(r'(\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2})')
        .firstMatch(texto);
    if (m != null && meses.containsKey(m.group(2))) {
      // La BD guarda la hora local; se muestra tal cual viene.
      return fmt(DateTime(
        int.parse(m.group(3)!),
        meses[m.group(2)]!,
        int.parse(m.group(1)!),
        int.parse(m.group(4)!),
        int.parse(m.group(5)!),
      ));
    }
    return texto;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: _fondo,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _azul, size: 36),
        title: const Text(
          'Historial',
          style: TextStyle(
            color: _azul,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(height: 4, color: Colors.white),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  height: 30,
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _query = value;
                        _aplicarFiltro();
                      });
                    },
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black87),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      hintText: 'Buscar En Historial',
                      hintStyle:
                          const TextStyle(fontSize: 13, color: Colors.black87),
                      suffixIcon: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.filter_alt,
                          color: _hayFiltrosActivos ? Colors.orange : _azul,
                          size: 26,
                        ),
                        onPressed: _mostrarFiltros,
                      ),
                      suffixIconConstraints:
                          const BoxConstraints(minWidth: 36, minHeight: 26),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _azul, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _azul, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(child: _buildLista()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLista() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: _azul));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }
    if (_filtrados.isEmpty) {
      return const Center(
        child: Text('Sin llamadas en el historial',
            style: TextStyle(color: _azul)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      itemCount: _filtrados.length,
      itemBuilder: (context, index) => _buildCard(_filtrados[index]),
    );
  }

  Widget _detalle(String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text(
        texto,
        style: const TextStyle(color: _azul, fontSize: 14),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final nombre = (item['nombre_completo'] ?? '').toString();
    final correo = (item['correo_contacto'] ?? '').toString();
    final telefono = (item['telefono'] ?? '').toString();
    final anteriores = (item['llamadas_anteriores'] ?? 0).toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _azul, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: _azul,
                child: Icon(Icons.person, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _azul,
                        fontSize: 28,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      correo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _azul, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.dialpad, color: _azul, size: 34),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  telefono,
                  style: const TextStyle(color: _azul, fontSize: 22),
                ),
                const SizedBox(height: 8),
                _detalle('Llamadas Anteriores: $anteriores'),
                _detalle('Fecha: ${_formatearFecha(item['fecha_llamada'])}'),
                _detalle(
                    'Duración: ${_formatearDuracion(item['duracion_segundos'])}'),
                _detalle('Motivo: ${item['motivo'] ?? ''}'),
                _detalle('Estado: ${item['estado_llamada'] ?? ''}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

