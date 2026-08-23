import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';

class CocinaScreen extends StatefulWidget {
  const CocinaScreen({super.key});

  @override
  State<CocinaScreen> createState() => _CocinaScreenState();
}

class _CocinaScreenState extends State<CocinaScreen> {
  static const Color _primaryColor = Color(0xFFF48FB1);
  static const Color _secondaryColor = Color(0xFF81D4FA);
  static const Color _backgroundColor = Color(0xFFF9F9F9);
  List<_Pedido> _pedidos = [];
  bool _isLoading = true;
  String? _error;
  int? _pedidoActualizando;

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  Future<void> _cargarPedidos() async {
    if (!_isLoading) {
      setState(() {
        _error = null;
      });
    }

    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/obtener_cola_pedidos.php'))
          .timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = _decodeResponse(response.body);

      if (response.statusCode != 200) {
        throw Exception(
          body['mensaje']?.toString() ??
              'El servidor respondió con el código ${response.statusCode}.',
        );
      }

      if (body['estado'] != 'exito') {
        throw Exception(
          body['mensaje']?.toString() ?? 'No se pudo obtener la cola de pedidos.',
        );
      }

      final datos = body['datos'];
      if (datos is! List) {
        throw Exception('La respuesta del servidor no tiene un formato válido.');
      }

      if (!mounted) return;

      setState(() {
        _pedidos = datos
            .whereType<Map<String, dynamic>>()
            .map(_Pedido.fromJson)
            .toList();
        _error = null;
        _isLoading = false;
      });
    } on FormatException {
      if (!mounted) return;
      setState(() {
        _error = 'El servidor devolvió una respuesta inválida.';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : 'No se pudo conectar con el servidor.';
        _isLoading = false;
      });
    }
  }

  Future<void> _despacharPedido(_Pedido pedido) async {
    setState(() {
      _pedidoActualizando = pedido.idPedido;
    });

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/actualizar_estado_pedido.php'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id_pedido': pedido.idPedido,
              'nuevo_estado': 'Completado',
            }),
          )
          .timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = _decodeResponse(response.body);

      if (response.statusCode != 200) {
        throw Exception(
          body['mensaje']?.toString() ??
              'El servidor respondió con el código ${response.statusCode}.',
        );
      }

      if (body['estado'] != 'exito') {
        throw Exception(
          body['mensaje']?.toString() ?? 'No se pudo actualizar el pedido.',
        );
      }

      if (!mounted) return;

      setState(() {
        _pedidos.removeWhere((item) => item.idPedido == pedido.idPedido);
        _pedidoActualizando = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido #${pedido.idPedido} despachado correctamente.'),
          backgroundColor: _secondaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FormatException {
      if (!mounted) return;
      setState(() {
        _pedidoActualizando = null;
      });
      _mostrarError('El servidor devolvió una respuesta inválida.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pedidoActualizando = null;
      });
      _mostrarError(
        e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : 'No se pudo actualizar el pedido.',
      );
    }
  }

  Map<String, dynamic> _decodeResponse(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Formato de respuesta no válido.');
    }
    return decoded;
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Reintentar',
          textColor: Colors.white,
          onPressed: _cargarPedidos,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ColoredBox(
        color: _backgroundColor,
        child: Center(
          child: CircularProgressIndicator(color: _primaryColor),
        ),
      );
    }

    if (_error != null && _pedidos.isEmpty) {
      return ColoredBox(
        color: _backgroundColor,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _ErrorState(
              message: _error!,
              onRetry: _cargarPedidos,
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: _backgroundColor,
      child: RefreshIndicator(
        color: _primaryColor,
        onRefresh: _cargarPedidos,
        child: _pedidos.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  _EmptyState(),
                ],
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 430,
                  mainAxisExtent: 420,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _pedidos.length,
                itemBuilder: (context, index) {
                  final pedido = _pedidos[index];
                  return _PedidoCard(
                    pedido: pedido,
                    isUpdating: _pedidoActualizando == pedido.idPedido,
                    onDispatch: () => _despacharPedido(pedido),
                  );
                },
              ),
      ),
    );
  }
}

class _PedidoCard extends StatelessWidget {
  const _PedidoCard({
    required this.pedido,
    required this.isUpdating,
    required this.onDispatch,
  });

  static const Color _primaryColor = Color(0xFFF48FB1);
  static const Color _secondaryColor = Color(0xFF81D4FA);
  static const Color _textColor = Color(0xFF424242);

  final _Pedido pedido;
  final bool isUpdating;
  final VoidCallback onDispatch;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _secondaryColor.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Pedido #${pedido.idPedido}',
                    style: const TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.schedule, size: 18, color: _textColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    pedido.fechaHora,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Cliente',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              pedido.identificadorCliente.isEmpty
                  ? 'Sin identificador'
                  : pedido.identificadorCliente,
              style: const TextStyle(
                color: _textColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              'Detalle del pedido',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: pedido.productos.isEmpty
                  ? const Center(
                      child: Text(
                        'Sin detalle de productos',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: pedido.productos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final item = pedido.productos[index];
                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _secondaryColor.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${item.cantidad}x',
                                style: const TextStyle(
                                  color: _textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.nombre,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _textColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estado',
                  style: TextStyle(color: Colors.grey),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Pendiente',
                    style: TextStyle(
                      color: Colors.pink.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${pedido.totalPagar.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isUpdating ? null : onDispatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _primaryColor.withValues(alpha: 0.45),
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: isUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  isUpdating ? 'Despachando...' : 'Despachar',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  static const Color _primaryColor = Color(0xFFF48FB1);
  static const Color _textColor = Color(0xFF424242);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.icecream_outlined,
              size: 72,
              color: _primaryColor.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay pedidos pendientes',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'La cola de cocina está al día.\nDesliza hacia abajo para actualizar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  static const Color _primaryColor = Color(0xFFF48FB1);
  static const Color _textColor = Color(0xFF424242);

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_off, size: 64, color: _primaryColor),
        const SizedBox(height: 16),
        const Text(
          'No pudimos cargar la cocina',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Reintentar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _Pedido {
  const _Pedido({
    required this.idPedido,
    required this.identificadorCliente,
    required this.fechaHora,
    required this.estado,
    required this.totalPagar,
    required this.productos,
  });

  final int idPedido;
  final String identificadorCliente;
  final String fechaHora;
  final String estado;
  final double totalPagar;
  final List<_ItemPedido> productos;

  factory _Pedido.fromJson(Map<String, dynamic> json) {
    final productosJson = json['productos'];

    return _Pedido(
      idPedido: int.tryParse(json['id_pedido'].toString()) ?? 0,
      identificadorCliente: json['identificador_cliente']?.toString() ?? '',
      fechaHora: json['fecha_hora']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'En cola',
      totalPagar: double.tryParse(json['total_pagar'].toString()) ?? 0,
      productos: productosJson is List
          ? productosJson
              .whereType<Map<String, dynamic>>()
              .map(_ItemPedido.fromJson)
              .toList()
          : const [],
    );
  }
}

class _ItemPedido {
  const _ItemPedido({
    required this.nombre,
    required this.cantidad,
  });

  final String nombre;
  final int cantidad;

  factory _ItemPedido.fromJson(Map<String, dynamic> json) {
    return _ItemPedido(
      nombre: json['nombre']?.toString() ?? 'Producto',
      cantidad: int.tryParse(json['cantidad'].toString()) ?? 1,
    );
  }
}