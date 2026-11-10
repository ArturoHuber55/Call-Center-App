import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_drawer.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key, required this.llamada});

  final Map<String, dynamic> llamada;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  static const Color _bg = Color(0xFFD6E8F2);
  static const Color _darkBlue = Color(0xFF1C3A8C);
  static const Color _btnBlue = Color(0xFF3A6291);

  final TextEditingController _notasController = TextEditingController();
  String? _motivoSeleccionado;
  String? _estadoSeleccionado;
  late DateTime _horaInicio;
  Timer? _timer;
  int _segundos = 0;

  String get _tiempoFormateado {
    final m = (_segundos ~/ 60).toString().padLeft(2, '0');
    final s = (_segundos % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static const List<String> _motivos = [
    'Soporte Técnico',
    'Información',
    'Queja',
    'Ventas',
  ];
  static const List<String> _estados = [
    'Resuelto',
    'En seguimiento',
    'Escalado',
  ];

  @override
  void initState() {
    super.initState();
    _horaInicio = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _segundos++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _finalizarLlamada() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    int duracion = _segundos;

    try {
      final response = await http.put(
        Uri.parse(
            'http://127.0.0.1:5000/finalizar_llamada/${widget.llamada['id_llamada']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'duracion_segundos': duracion,
          'estado_llamada': _estadoSeleccionado,
          'notas': _notasController.text,
          'motivo': _motivoSeleccionado ?? widget.llamada['motivo'],
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Llamada guardada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        navigator.pop();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error al guardar la llamada (${response.statusCode})'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _dropdown({
    required String label,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _btnBlue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E9BE0)),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        dropdownColor: _btnBlue,
        iconEnabledColor: Colors.white,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: label,
          hintStyle: const TextStyle(color: Colors.white),
        ),
        items: items
            .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text(
          'Call Center',
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Llamada Activa',
                  style: TextStyle(
                    color: _darkBlue,
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_filled,
                      color: _darkBlue,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _tiempoFormateado,
                      style: TextStyle(color: _darkBlue, fontSize: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _finalizarLlamada,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _btnBlue,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Finalizar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _darkBlue, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.account_circle,
                            color: _darkBlue,
                            size: 44,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.llamada['nombre_completo'] ?? ''}',
                                  style: const TextStyle(
                                    color: _darkBlue,
                                    fontSize: 24,
                                  ),
                                ),
                                Text(
                                  '${widget.llamada['motivo'] ?? ''}',
                                  style: const TextStyle(
                                    color: _darkBlue,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.dialpad, color: _darkBlue),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Tel:', style: TextStyle(fontSize: 18)),
                      Text('${widget.llamada['telefono'] ?? ''}',
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 16),
                      const Text('Correo:', style: TextStyle(fontSize: 18)),
                      Text(
                        '${widget.llamada['correo_contacto'] ?? 'Sin correo'}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Notas de la llamada',
                  style: TextStyle(fontSize: 17, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 150,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _darkBlue, width: 1),
                  ),
                  child: TextField(
                    controller: _notasController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: 'Escribe notas aquí...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _dropdown(
                  label: 'Motivo',
                  items: _motivos,
                  value: _motivoSeleccionado,
                  onChanged: (v) => setState(() => _motivoSeleccionado = v),
                ),
                const SizedBox(height: 12),
                _dropdown(
                  label: 'Estado',
                  items: _estados,
                  value: _estadoSeleccionado,
                  onChanged: (v) => setState(() => _estadoSeleccionado = v),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
