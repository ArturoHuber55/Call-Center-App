import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'panel_screen.dart';

/// Menú lateral compartido por las pantallas de la app.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static const Color _drawerBg = Color(0xFF385A7A);
  static const List<String> _items = [
    'Panel',
    'Llamadas',
    'Clientes',
    'Historial',
    'Estadísticas',
    'Salir',
  ];

  void _onItemTap(BuildContext context, String item) {
    switch (item) {
      case 'Panel':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PanelScreen()),
        );
        break;
      case 'Salir':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        break;
      default:
        // Se obtiene el messenger antes de cerrar el Drawer.
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Módulo en desarrollo...')),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      children.add(
        ListTile(
          title: Text(
            item,
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
          onTap: () => _onItemTap(context, item),
        ),
      );
      if (i < _items.length - 1) {
        children.add(
          const Divider(color: Colors.white, thickness: 1, height: 0),
        );
      }
    }

    return Drawer(
      backgroundColor: _drawerBg,
      child: ListView(
        padding: EdgeInsets.zero,
        children: children,
      ),
    );
  }
}
