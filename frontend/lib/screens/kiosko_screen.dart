import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';

class KioskoScreen extends StatefulWidget {
  const KioskoScreen({super.key});

  @override
  State<KioskoScreen> createState() => _KioskoScreenState();
}

class _KioskoScreenState extends State<KioskoScreen> {
  List<dynamic> _categorias = [];
  List<dynamic> _productos = [];
  List<dynamic> _productosFiltrados = [];
  final List<Map<String, dynamic>> _carrito = [];

  int? _categoriaSeleccionadaId;
  bool _isLoading = true;
  bool _isSendingOrder = false;
  String? _errorMessage;

  final TextEditingController _clienteController = TextEditingController();

  // Design System Oficial
  static const Color primaryColor = Color(0xFFF48FB1);
  static const Color accentColor = Color(0xFF81D4FA);
  static const Color backgroundColor = Color(0xFFF9F9F9);
  static const Color textColor = Color(0xFF424242);

  @override
  void initState() {
    super.initState();
    _cargarMenu();
  }

  @override
  void dispose() {
    _clienteController.dispose();
    super.dispose();
  }

  // GET a obtener_menu.php
  Future<void> _cargarMenu() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/obtener_menu.php');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final List<dynamic> productos = data['datos'] ?? [];

        // Generar categorías a partir de los productos
        final categoriasNombres = productos
            .map((p) => p['categoria']?.toString())
            .where((nombre) => nombre != null && nombre.isNotEmpty)
            .toSet()
            .toList();

        final categorias = categoriasNombres.asMap().entries.map((entry) {
          return {
            'id': entry.key + 1,
            'nombre': entry.value,
          };
        }).toList();

        // Adaptar los nombres del backend a los que espera el frontend
        final productosAdaptados = productos.map((p) {
          final categoriaNombre = p['categoria']?.toString() ?? '';

          final categoria = categorias.firstWhere(
            (cat) => cat['nombre'] == categoriaNombre,
            orElse: () => {'id': 0, 'nombre': categoriaNombre},
          );

          return {
            'id': p['id_producto'],
            'nombre': p['nombre'],
            'precio': p['precio_base'],
            'id_categoria': categoria['id'],
            'disponible': true,
          };
        }).toList();

        setState(() {
          _categorias = categorias;
          _productos = productosAdaptados;
          _productosFiltrados = productosAdaptados;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Error en el servidor (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  void _filtrarPorCategoria(int? categoriaId) {
    setState(() {
      _categoriaSeleccionadaId = categoriaId;
      if (categoriaId == null) {
        _productosFiltrados = _productos;
      } else {
        _productosFiltrados = _productos
            .where((p) => p['id_categoria'].toString() == categoriaId.toString())
            .toList();
      }
    });
  }

  void _agregarAlCarrito(Map<String, dynamic> producto) {
    setState(() {
      final index = _carrito.indexWhere((item) => item['id'] == producto['id']);
      double precio = double.tryParse(producto['precio'].toString()) ?? 0.0;

      if (index != -1) {
        _carrito[index]['cantidad'] += 1;
      } else {
        _carrito.add({
          'id': producto['id'],
          'nombre': producto['nombre'],
          'precio': precio,
          'cantidad': 1,
        });
      }
    });
  }

  void _modificarCantidad(int index, int cambio) {
    setState(() {
      _carrito[index]['cantidad'] += cambio;
      if (_carrito[index]['cantidad'] <= 0) {
        _carrito.removeAt(index);
      }
    });
  }

  double get _totalCarrito {
    return _carrito.fold(
      0.0,
      (sum, item) => sum + (item['precio'] * item['cantidad']),
    );
  }

  // POST a crear_pedido.php
  Future<void> _confirmarPedido() async {
    final cliente = _clienteController.text.trim();
    if (cliente.isEmpty) {
      _mostrarSnackBar('Ingresa el identificador del cliente.', Colors.orange);
      return;
    }

    if (_carrito.isEmpty) {
      _mostrarSnackBar('El carrito está vacío.', Colors.orange);
      return;
    }

    setState(() => _isSendingOrder = true);

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/crear_pedido.php');

      // 1. Recetario completo basado en NOMBRES (Infalible para la sustentación)
      final Map<String, List<Map<String, dynamic>>> recetario = {
        'Frappé de Caramelo': [
          {"id_insumo": 2, "cantidad_usada": 1}, // Vaso
          {"id_insumo": 10, "cantidad_usada": 2}, // Salsa Caramelo (Doble porción)
          {"id_insumo": 17, "cantidad_usada": 1}, // Crema Chantilly
        ],
        'Malteada Clásica': [
          {"id_insumo": 2, "cantidad_usada": 1}, // Vaso
          {"id_insumo": 5, "cantidad_usada": 2}, // Helado de Chocolate
          {"id_insumo": 17, "cantidad_usada": 1}, // Crema Chantilly
        ],
        'Cono Doble': [
          {"id_insumo": 1, "cantidad_usada": 1}, // Cono de Galleta
          {"id_insumo": 4, "cantidad_usada": 1}, // Helado de Vainilla
          {"id_insumo": 5, "cantidad_usada": 1}, // Helado de Chocolate
        ],
        'Cono Simple': [
          {"id_insumo": 1, "cantidad_usada": 1}, // Cono de Galleta
          {"id_insumo": 4, "cantidad_usada": 1}, // Helado de Vainilla
        ],
        'Copa Sundae': [
          {"id_insumo": 2, "cantidad_usada": 1}, // Vaso
          {"id_insumo": 4, "cantidad_usada": 2}, // 2 de Vainilla
          {"id_insumo": 9, "cantidad_usada": 1}, // Salsa de Chocolate
          {"id_insumo": 16, "cantidad_usada": 1}, // Cereza
        ],
        'Banana Split': [
          {"id_insumo": 2, "cantidad_usada": 1}, // Vaso/Plato
          {"id_insumo": 4, "cantidad_usada": 1}, // Vainilla
          {"id_insumo": 5, "cantidad_usada": 1}, // Chocolate
          {"id_insumo": 6, "cantidad_usada": 1}, // Fresa
          {"id_insumo": 9, "cantidad_usada": 1}, // Salsa de Chocolate
          {"id_insumo": 16, "cantidad_usada": 1}, // Cereza
        ],
        'Brownie con Helado': [
          {"id_insumo": 3, "cantidad_usada": 1}, // Base de Brownie
          {"id_insumo": 4, "cantidad_usada": 1}, // Helado de Vainilla
          {"id_insumo": 9, "cantidad_usada": 1}, // Salsa de Chocolate
        ],
        'Helado de Chocolate': [
          {"id_insumo": 1, "cantidad_usada": 1}, // Cono
          {"id_insumo": 5, "cantidad_usada": 1}, // Chocolate
        ],
        'Helado de Fresa': [
          {"id_insumo": 1, "cantidad_usada": 1}, // Cono
          {"id_insumo": 6, "cantidad_usada": 1}, // Fresa
        ],
        'Helado de Vainilla': [
          {"id_insumo": 1, "cantidad_usada": 1}, // Cono
          {"id_insumo": 4, "cantidad_usada": 1}, // Vainilla
        ],
      };

      // 2. Armamos el JSON leyendo el nombre del carrito
      final bodyData = json.encode({
        'identificador_cliente': cliente,
        'productos': _carrito.map((item) {
          int idProd = int.parse(item['id'].toString());
          String nombreProd = item['nombre'].toString(); // Sacamos el nombre
          
          return {
            'id_producto': idProd,
            'cantidad': item['cantidad'],
            // Buscamos la receta por nombre, si no está, mandamos vacío
            'insumos': recetario.containsKey(nombreProd) ? recetario[nombreProd] : [],
          };
        }).toList(),
      });

      // 3. Enviamos la petición al backend
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: bodyData,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _mostrarSnackBar('¡Pedido registrado!', Colors.green);
        setState(() {
          _carrito.clear();
          _clienteController.clear();
        });
      } else {
        _mostrarSnackBar(data['mensaje'] ?? 'Error al crear pedido.', Colors.red);
      }
    } catch (e) {
      _mostrarSnackBar('Error de conexión: $e', Colors.red);
    } finally {
      setState(() => _isSendingOrder = false);
    }
  }

  void _mostrarSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: textColor, fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarMenu,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                        child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCategoriasFilter(),
                            const SizedBox(height: 16),
                            Expanded(child: _buildGridProductos()),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(-2, 0),
                            ),
                          ],
                        ),
                        child: _buildPanelCarrito(),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCategoriasFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: const Text('Todos'),
              selected: _categoriaSeleccionadaId == null,
              selectedColor: primaryColor.withOpacity(0.3),
              labelStyle: const TextStyle(color: textColor, fontWeight: FontWeight.bold),
              onSelected: (_) => _filtrarPorCategoria(null),
            ),
          ),
          ..._categorias.map((cat) {
            final int? idCat = int.tryParse(cat['id'].toString());
            final isSelected = _categoriaSeleccionadaId == idCat;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(cat['nombre'] ?? ''),
                selected: isSelected,
                selectedColor: primaryColor.withOpacity(0.3),
                labelStyle: TextStyle(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) => _filtrarPorCategoria(idCat),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGridProductos() {
    if (_productosFiltrados.isEmpty) {
      return const Center(
        child: Text('No hay productos disponibles.', style: TextStyle(color: textColor)),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _productosFiltrados.length,
      itemBuilder: (context, index) {
        final prod = _productosFiltrados[index];
        final bool disponible = prod['disponible'] == 1 || prod['disponible'] == true || prod['disponible'] == '1';
        final double precio = double.tryParse(prod['precio'].toString()) ?? 0.0;

        return Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.icecream, size: 48, color: primaryColor),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  prod['nombre'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
                ),
                Text(
                  '\$${precio.toStringAsFixed(2)}',
                  style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: disponible ? () => _agregarAlCarrito(prod) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      disponible ? 'Agregar' : 'Agotado',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPanelCarrito() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del Pedido',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _clienteController,
            decoration: InputDecoration(
              labelText: 'Identificador / Nombre del Cliente',
              labelStyle: const TextStyle(color: textColor),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _carrito.isEmpty
                ? const Center(child: Text('El carrito está vacío', style: TextStyle(color: textColor)))
                : ListView.separated(
                    itemCount: _carrito.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = _carrito[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item['nombre'], style: const TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                        subtitle: Text('\$${(item['precio'] * item['cantidad']).toStringAsFixed(2)}', style: const TextStyle(color: primaryColor)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: textColor),
                              onPressed: () => _modificarCantidad(index, -1),
                            ),
                            Text('${item['cantidad']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: primaryColor),
                              onPressed: () => _modificarCantidad(index, 1),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(thickness: 1.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              Text('\$${_totalCarrito.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSendingOrder ? null : _confirmarPedido,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSendingOrder
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Confirmar Pedido',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}