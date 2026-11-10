import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_drawer.dart';
import 'call_screen.dart';

class PanelScreen extends StatefulWidget {
  const PanelScreen({super.key});

  @override
  State<PanelScreen> createState() => _PanelScreenState();
}

class _PanelScreenState extends State<PanelScreen> {
  static const Color _bg = Color(0xFFD6E8F2);
  static const Color _darkBlue = Color(0xFF1C3A8C);
  static const Color _btnBlue = Color(0xFF3A6291);

  List<Map<String, dynamic>> _outgoing = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPendientes();
  }

  Future<void> _cargarPendientes() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final response =
          await http.get(Uri.parse('http://127.0.0.1:5000/llamadas_pendientes'));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        setState(() {
          _outgoing = decoded
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _cargando = false;
        });
      } else {
        setState(() {
          _error = 'Error ${response.statusCode} al cargar llamadas';
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

  void _goToCall(Map<String, dynamic> llamadaPendiente) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => CallScreen(llamada: llamadaPendiente)),
    );
  }

  Future<void> _confirmarEliminar(Map<String, dynamic> llamada) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar Llamada?'),
        content: const Text(
            '¿Estás seguro de que deseas eliminar esta llamada pendiente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    try {
      final response = await http.delete(Uri.parse(
          'http://127.0.0.1:5000/eliminar_llamada/${llamada['id_llamada']}'));
      if (!mounted) return;
      if (response.statusCode == 200) {
        await _cargarPendientes();
      } else {
        messenger.showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error ${response.statusCode}: ${response.body}'),
        ));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text('Error de conexión: $e'),
      ));
    }
  }

  Widget _title(String text) => Text(text,
      style: const TextStyle(
          color: _darkBlue, fontSize: 26, fontWeight: FontWeight.w500));

  Widget _button(String text, Map<String, dynamic> llamadaPendiente) {
    return ElevatedButton(
      onPressed: () => _goToCall(llamadaPendiente),
      style: ElevatedButton.styleFrom(
        backgroundColor: _btnBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(text),
    );
  }

  Widget _incomingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFA9F98C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _darkBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.account_circle, color: _darkBlue, size: 44),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Juan Peréz',
                        style: TextStyle(color: _darkBlue, fontSize: 24)),
                    Text('Soporte Tecnico',
                        style: TextStyle(color: _darkBlue, fontSize: 16)),
                  ],
                ),
              ),
              Icon(Icons.dialpad, color: _darkBlue),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Tel:', style: TextStyle(fontSize: 17)),
          const Text('52-1234-5678', style: TextStyle(fontSize: 17)),
          const SizedBox(height: 14),
          const Text('Correo:', style: TextStyle(fontSize: 17)),
          const Text('juan-perez@hotmail.com', style: TextStyle(fontSize: 11)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time_filled, color: _darkBlue, size: 18),
              const SizedBox(width: 6),
              const Text('2:38 A.M',
                  style: TextStyle(color: _darkBlue, fontSize: 16)),
              const Spacer(),
              _button('Responder', const {
                'nombre_completo': 'Juan Peréz',
                'telefono': '52-1234-5678',
                'motivo': 'Soporte Tecnico',
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _outgoingCard(Map<String, dynamic> c) {
    const style = TextStyle(color: _darkBlue, fontSize: 18);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF8686),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _darkBlue),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${c['nombre_completo'] ?? ''}', style: style),
                    const SizedBox(height: 6),
                    Text('Tel:${c['telefono'] ?? ''}', style: style),
                    const SizedBox(height: 6),
                    Text('Motivo: ${c['motivo'] ?? ''}', style: style),
                  ],
                ),
              ),
              const Icon(Icons.dialpad, color: _darkBlue),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            alignment: Alignment.center,
            children: [
              _button('Llamar', c),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Eliminar llamada',
                  icon: const Icon(Icons.delete, color: Color(0xFF1E367E), size: 28),
                  onPressed: () => _confirmarEliminar(c),
                ),
              ),
            ],
          ),
        ],
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
          'Panel Control',
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
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title('Llamada Entrante'),
                const SizedBox(height: 10),
                _incomingCard(),
                const SizedBox(height: 16),
                _title('Llamada Saliente'),
                const SizedBox(height: 10),
                if (_cargando)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red))
                else if (_outgoing.isEmpty)
                  const Text('No hay llamadas pendientes',
                      style: TextStyle(color: _darkBlue, fontSize: 16))
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _outgoing.length,
                    itemBuilder: (context, i) => _outgoingCard(_outgoing[i]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
