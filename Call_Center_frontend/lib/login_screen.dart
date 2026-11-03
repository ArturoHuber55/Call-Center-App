import 'package:flutter/material.dart';
import 'api_service.dart';
import 'panel_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _darkBlue = Color(0xFF1E3A8A);
  static const Color _buttonBlue = Color(0xFF3A648B);
  static const Color _fieldBg = Color(0xFFD8E9F0);

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _remember = false;
  bool isLogin = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black87, fontSize: 15),
      filled: true,
      fillColor: _fieldBg,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> _onSubmit() async {
    final nombre = _nombreController.text.trim();
    final telefono = _telefonoController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty ||
        password.isEmpty ||
        (!isLogin && (nombre.isEmpty || telefono.isEmpty))) {
      _showSnack('Por favor, rellene todos los datos', Colors.red);
      return;
    }

    final result = isLogin
        ? await ApiService.login(email, password)
        : await ApiService.registro(nombre, email, password,
            telefono: telefono);
    if (!mounted) return;
    if (result['status'] == 'success') {
      _showSnack(
          isLogin ? 'Inicio de sesión correcto' : 'Cuenta creada', Colors.green);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PanelScreen()),
      );
    } else {
      _showSnack(
          (result['message'] ??
                  (isLogin ? 'Credenciales inválidas' : 'No se pudo crear la cuenta'))
              .toString(),
          Colors.red);
    }
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontSize: 22, color: Colors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.phone_in_talk, size: 110, color: _darkBlue),
                  const SizedBox(height: 40),
                  Text(
                    isLogin ? 'Iniciar Sesión' : 'Registrarse',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 32, color: _darkBlue),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Ingresa tus datos',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.black),
                  ),
                  const SizedBox(height: 32),
                  if (!isLogin) ...[
                    _label('Nombre completo'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nombreController,
                      keyboardType: TextInputType.name,
                      decoration: _decoration('Nombre completo'),
                    ),
                    const SizedBox(height: 28),
                    _label('Número de teléfono'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: _decoration('Número de teléfono'),
                    ),
                    const SizedBox(height: 28),
                  ],
                  _label('Correo electrónico'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _decoration('ejemplo@gmail.com'),
                  ),
                  const SizedBox(height: 28),
                  _label('Contraseña'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: _decoration('*********'),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _remember,
                          onChanged: (v) =>
                              setState(() => _remember = v ?? false),
                          fillColor:
                              WidgetStateProperty.all(_fieldBg),
                          checkColor: Colors.black,
                          side: const BorderSide(color: Colors.black),
                          shape: const RoundedRectangleBorder(),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Recordar cuenta',
                          style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => isLogin = !isLogin),
                      child: Text(
                        isLogin
                            ? '¿No tienes cuenta? Regístrate aquí'
                            : '¿Ya tienes cuenta? Inicia sesión',
                        style:
                            const TextStyle(color: Colors.blue, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 72,
                    child: ElevatedButton(
                      onPressed: _onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _buttonBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        isLogin ? 'Iniciar Sesión' : 'Registrarse',
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
