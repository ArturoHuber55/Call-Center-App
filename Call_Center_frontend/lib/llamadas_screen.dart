import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app_drawer.dart';

class LlamadasScreen extends StatefulWidget {
  const LlamadasScreen({super.key});

  @override
  State<LlamadasScreen> createState() => _LlamadasScreenState();
}

class _LlamadasScreenState extends State<LlamadasScreen> {
  static const Color _azul = Color(0xFF253B6E);
  static const Color _fondo = Color(0xFFD6E8F0);
  static const String _baseUrl = 'http://127.0.0.1:5000';
  static const List<String> _motivos = [
    'Soporte técnico',
    'Ventas',
    'Información',
    'Queja',
  ];

  final TextEditingController _notasCtrl = TextEditingController();
  List<Map<String, dynamic>> _clientes = [];
  Map<String, dynamic>? clienteSeleccionado;
  String? _motivo;
  bool _enviando = false;
  // Se cambia al limpiar para reiniciar el campo del buscador.
  int _buscadorKey = 0;

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  @override
  void dispose() {
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarClientes() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/clientes'));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        setState(() {
          _clientes = decoded
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      } else {
        _mostrarMensaje('Error ${response.statusCode} al cargar clientes',
            Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje('Error de conexión: $e', Colors.red);
    }
  }

  void _mostrarMensaje(String texto, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: color),
    );
  }

  String _nombre(Map<String, dynamic> c) =>
      (c['nombre_completo'] ?? '').toString();

  Future<void> _programarLlamada() async {
    if (clienteSeleccionado == null) {
      _mostrarMensaje('Selecciona un cliente primero', Colors.red);
      return;
    }
    setState(() => _enviando = true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/programar_llamada'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_cliente': clienteSeleccionado!['id_cliente'],
          'motivo': _motivo,
          'notas': _notasCtrl.text.trim(),
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 201) {
        _mostrarMensaje('Llamada programada con éxito', Colors.green);
        setState(() {
          _notasCtrl.clear();
          clienteSeleccionado = null;
          _motivo = null;
          _buscadorKey++;
        });
      } else {
        _mostrarMensaje(
            'Error ${response.statusCode}: ${response.body}', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje('Error de conexión: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  InputDecoration _decoracionCampo(String hint, {Widget? prefix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buscador() {
    return Autocomplete<Map<String, dynamic>>(
      key: ValueKey(_buscadorKey),
      displayStringForOption: _nombre,
      optionsBuilder: (TextEditingValue value) {
        final q = value.text.trim().toLowerCase();
        if (q.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
        return _clientes.where((c) {
          return _nombre(c).toLowerCase().contains(q) ||
              (c['telefono'] ?? '').toString().toLowerCase().contains(q);
        });
      },
      onSelected: (c) => setState(() => clienteSeleccionado = c),
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration:
              _decoracionCampo('Buscar cliente', prefix: const Icon(Icons.search)),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 700),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final c = options.elementAt(i);
                  return ListTile(
                    title: Text(_nombre(c)),
                    subtitle: Text((c['telefono'] ?? '').toString()),
                    onTap: () => onSelected(c),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tarjetaCliente(Map<String, dynamic> c) {
    final nombre = _nombre(c);
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: _azul,
              child: Text(
                inicial,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                        color: _azul,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text((c['correo_contacto'] ?? '').toString(),
                      style: const TextStyle(color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text((c['telefono'] ?? '').toString(),
                      style: const TextStyle(color: Colors.black87)),
                  const SizedBox(height: 6),
                  const Text(
                    'Llamadas Anteriores: 0',
                    style: TextStyle(
                        color: _azul,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _azul),
        title: const Text(
          'Llamadas',
          style: TextStyle(
              color: _azul, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                const Text(
                  'Crear Llamada',
                  style: TextStyle(
                      color: _azul, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buscador(),
                const SizedBox(height: 16),
                if (clienteSeleccionado != null) ...[
                  SizedBox(
                      width: double.infinity,
                      child: _tarjetaCliente(clienteSeleccionado!)),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Notas de la llamada',
                  style: TextStyle(
                      color: _azul, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notasCtrl,
                  maxLines: 4,
                  decoration: _decoracionCampo('Escribe las notas aquí...'),
                ),
                const SizedBox(height: 16),
                Theme(
                  data: Theme.of(context).copyWith(canvasColor: _azul),
                  child: DropdownButtonFormField<String>(
                    initialValue: _motivo,
                    iconEnabledColor: Colors.white,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    dropdownColor: _azul,
                    hint: const Text('Motivo de la llamada',
                        style: TextStyle(color: Colors.white70)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _azul,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _motivos
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m,
                                  style: const TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _motivo = v),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _enviando ? null : _programarLlamada,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _azul,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _enviando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Programar Llamada',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

