import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_config.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  List<dynamic> _insumos = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _cargarInventario();
  }

  // Petición GET
  Future<void> _cargarInventario() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/verificar_stock.php'));
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['estado'] == 'exito') {
          setState(() {
            _insumos = jsonResponse['datos'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = jsonResponse['mensaje'];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Error del servidor: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Estado de carga
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    // Estado de error
    if (_error.isNotEmpty) {
      return Center(
        child: Text(_error, style: const TextStyle(color: Colors.red, fontSize: 16)),
      );
    }

    // Lista de inventario (Con Pull to Refresh)
    return RefreshIndicator(
      onRefresh: _cargarInventario,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _insumos.length,
        itemBuilder: (context, index) {
          final item = _insumos[index];

          // Maneja el boolean dependiendo de cómo lo mande la base de datos (1 o true)
          final bool disponible = item['disponible'] == 1 || item['disponible'] == true;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: disponible ? Colors.green.shade100 : Colors.red.shade100,
                child: Icon(
                  disponible ? Icons.check_circle : Icons.cancel,
                  color: disponible ? Colors.green : Colors.red,
                ),
              ),
              title: Text(
                item['nombre'], 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
              ),
              subtitle: Text('Tipo: ${item['tipo']}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Stock', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    '${item['stock_actual']}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: disponible ? Colors.black87 : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}