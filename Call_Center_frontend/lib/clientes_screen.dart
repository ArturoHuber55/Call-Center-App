import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app_drawer.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  static const Color _azul = Color(0xFF253B6E);
  static const Color _fondo = Color(0xFFD6E8F0);
  static const String _baseUrl = 'http://127.0.0.1:5000';

  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _filtrados = [];
  bool _cargando = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final response = await http.get(Uri.parse('$_baseUrl/clientes'));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        setState(() {
          _clientes = decoded
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

  Future<void> _importarExcel() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result.isEmpty) return;
    final archivo = result.first;
    Uint8List? bytes;
    try {
      bytes = await archivo.readAsBytes();
    } catch (_) {
      bytes = null;
    }
    if (bytes == null) {
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('No se pudo leer el archivo seleccionado'),
        ),
      );
      return;
    }
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/importar_clientes'),
      )..files.add(http.MultipartFile.fromBytes(
          'documento',
          bytes,
          filename: archivo.name,
        ));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      navigator.pop();

      if (response.statusCode == 200) {
        String mensaje = 'Clientes importados correctamente';
        try {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data is Map && data['message'] != null) {
            mensaje = data['message'].toString();
          }
        } catch (_) {}
        messenger.showSnackBar(
          SnackBar(backgroundColor: Colors.green, content: Text(mensaje)),
        );
        if (mounted) _cargarClientes();
      } else {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error ${response.statusCode}: ${response.body}'),
          ),
        );
      }
    } catch (e) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error de conexión: $e'),
        ),
      );
    }
  }

  void _aplicarFiltro() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) {
      _filtrados = List.of(_clientes);
    } else {
      _filtrados = _clientes.where((c) {
        final nombre = (c['nombre_completo'] ?? '').toString().toLowerCase();
        final tel = (c['telefono'] ?? '').toString().toLowerCase();
        return nombre.contains(q) || tel.contains(q);
      }).toList();
    }
  }

  void _mostrarFormulario([Map<String, dynamic>? cliente]) {
    final esEdicion = cliente != null;
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(
        text: (cliente?['nombre_completo'] ?? '').toString());
    final telefonoCtrl =
        TextEditingController(text: (cliente?['telefono'] ?? '').toString());
    final correoCtrl = TextEditingController(
        text: (cliente?['correo_contacto'] ?? '').toString());
    final messenger = ScaffoldMessenger.of(context);
    bool guardando = false;

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
            Future<void> guardar() async {
              if (!formKey.currentState!.validate()) return;
              setSheetState(() => guardando = true);
              try {
                final body = jsonEncode({
                  'nombre_completo': nombreCtrl.text.trim(),
                  'telefono': telefonoCtrl.text.trim(),
                  'correo_contacto': correoCtrl.text.trim(),
                });
                const headers = {'Content-Type': 'application/json'};
                final response = esEdicion
                    ? await http.put(
                        Uri.parse(
                            '$_baseUrl/editar_cliente/${cliente['id_cliente']}'),
                        headers: headers,
                        body: body,
                      )
                    : await http.post(
                        Uri.parse('$_baseUrl/crear_cliente'),
                        headers: headers,
                        body: body,
                      );
                if (response.statusCode == (esEdicion ? 200 : 201)) {
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.green,
                      content: Text(esEdicion
                          ? 'Cliente actualizado correctamente'
                          : 'Cliente guardado correctamente'),
                    ),
                  );
                  if (mounted) _cargarClientes();
                } else {
                  if (sheetContext.mounted) {
                    setSheetState(() => guardando = false);
                  }
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red,
                      content: Text('Error ${response.statusCode}: ${response.body}'),
                    ),
                  );
                }
              } catch (e) {
                if (sheetContext.mounted) {
                  setSheetState(() => guardando = false);
                }
                messenger.showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('Error de conexión: $e'),
                  ),
                );
              }
            }

            Future<void> eliminar(BuildContext dialogContext) async {
              try {
                final response = await http.delete(Uri.parse(
                    '$_baseUrl/eliminar_cliente/${cliente!['id_cliente']}'));
                if (response.statusCode == 200) {
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                  messenger.showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.red,
                      content: Text('Cliente eliminado correctamente'),
                    ),
                  );
                  if (mounted) _cargarClientes();
                } else {
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red,
                      content: Text(
                          'Error ${response.statusCode}: ${response.body}'),
                    ),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                messenger.showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('Error de conexión: $e'),
                  ),
                );
              }
            }

            Future<void> confirmarEliminar() async {
              await showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Eliminar cliente'),
                  content: Text(
                      '¿Realmente deseas eliminar a ${cliente!['nombre_completo']}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => eliminar(dialogContext),
                      child: const Text('Confirmar',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              esEdicion ? 'Editar Cliente' : 'Nuevo Cliente',
                              style: const TextStyle(
                                color: _azul,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: nombreCtrl,
                              textCapitalization: TextCapitalization.words,
                              decoration: _inputDecoration('Nombre'),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Ingresa el nombre'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: telefonoCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration('Teléfono'),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Ingresa el teléfono'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: correoCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _inputDecoration('Correo'),
                              validator: (v) {
                                final s = v?.trim() ?? '';
                                if (s.isEmpty) return 'Ingresa el correo';
                                if (!s.contains('@')) return 'Correo inválido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: guardando ? null : guardar,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _azul,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: guardando
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        esEdicion
                                            ? 'Actualizar Cliente'
                                            : 'Guardar Cliente',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                              ),
                            ),
                            if (esEdicion) ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: guardando ? null : confirmarEliminar,
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                label: const Text(
                                  'Eliminar',
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 16),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      // Se liberan después de la animación de cierre del modal.
      Future.delayed(const Duration(milliseconds: 500), () {
        nombreCtrl.dispose();
        telefonoCtrl.dispose();
        correoCtrl.dispose();
      });
    });
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _azul),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _azul),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _azul),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _azul, width: 2),
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
        centerTitle: true,
        iconTheme: const IconThemeData(color: _azul, size: 36),
        title: const Text(
          'Clientes',
          style: TextStyle(
            color: _azul,
            fontSize: 26,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _importarExcel,
              icon: const Icon(Icons.upload_file),
              label: const Text('Importar Excel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E367E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Editar, Crear Clientes',
                  style: TextStyle(
                    color: _azul,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  height: 32,
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
                      hintText: 'Buscar Cliente Por Numero O Nombre',
                      hintStyle:
                          const TextStyle(fontSize: 13, color: Colors.black87),
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
              const SizedBox(height: 8),
              Expanded(child: _buildLista()),
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        width: 74,
        height: 74,
        child: FloatingActionButton(
          onPressed: _mostrarFormulario,
          backgroundColor: _azul,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: const Icon(Icons.person_add_alt_1, size: 44),
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
        child: Text('Sin clientes', style: TextStyle(color: _azul)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
      itemCount: _filtrados.length,
      itemBuilder: (context, index) =>
          _buildCard(_filtrados[index], index == 0),
    );
  }

  Widget _buildCard(Map<String, dynamic> c, bool destacado) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _azul, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: _azul,
                  child: Icon(Icons.person, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (c['nombre_completo'] ?? '').toString(),
                        style: TextStyle(
                          color: _azul,
                          fontSize: destacado ? 26 : 20,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        (c['correo_contacto'] ?? '').toString(),
                        style: const TextStyle(color: _azul, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.dialpad, color: _azul, size: 30),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              (c['telefono'] ?? '').toString(),
              style: const TextStyle(color: _azul, fontSize: 22),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    'Llamadas Anteriores: ${c['llamadas_anteriores'] ?? 0}',
                    style: const TextStyle(color: _azul, fontSize: 13),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _mostrarFormulario(c),
                  icon: const Icon(Icons.manage_accounts_outlined,
                      color: _azul, size: 36),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
