import 'package:flutter/material.dart';
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

  final List<Map<String, String>> _outgoing = [
    {'name': 'Juan Peréz', 'tel': '+52 443 123 4532', 'motivo': 'Soporte Tenico'},
    {'name': 'Ricardo Hernandez', 'tel': '+25 435 545 923', 'motivo': 'Informacion'},
  ];

  void _goToCall() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CallScreen()),
    );
  }

  Widget _title(String text) => Text(text,
      style: const TextStyle(
          color: _darkBlue, fontSize: 26, fontWeight: FontWeight.w500));

  Widget _button(String text) {
    return ElevatedButton(
      onPressed: _goToCall,
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
              _button('Responder'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _outgoingCard(Map<String, String> c) {
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
                    Text(c['name']!, style: style),
                    const SizedBox(height: 6),
                    Text('Tel:${c['tel']}', style: style),
                    const SizedBox(height: 6),
                    Text('Motivo: ${c['motivo']}', style: style),
                  ],
                ),
              ),
              const Icon(Icons.dialpad, color: _darkBlue),
            ],
          ),
          const SizedBox(height: 4),
          _button('Llamar'),
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title('Llamada Entrante'),
                const SizedBox(height: 10),
                _incomingCard(),
                const SizedBox(height: 16),
                _title('Llamada Saliente'),
                const SizedBox(height: 10),
                ..._outgoing.map(_outgoingCard),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
