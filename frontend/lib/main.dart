import 'package:flutter/material.dart';
// Aquí importarán sus pantallas reales después
 import 'screens/kiosko_screen.dart';
// import 'screens/cocina_screen.dart';
import 'screens/inventario_screen.dart';

void main() {
  runApp(const HeladeriaApp());
}

class HeladeriaApp extends StatelessWidget {
  const HeladeriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema Heladería',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Usamos el Rosa Pastel del Design System que definiste
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF48FB1), 
          surface: const Color(0xFFF9F9F9),
        ),
      ),
      home: const NavegacionPrincipal(),
    );
  }
}

class NavegacionPrincipal extends StatefulWidget {
  const NavegacionPrincipal({super.key});

  @override
  State<NavegacionPrincipal> createState() => _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends State<NavegacionPrincipal> {
  int _indiceActual = 0;

  // Estas son las "pantallas" temporales.
  // Cuando Génesis y Camili terminen, reemplazarán estos Textos por sus Widgets.
  final List<Widget> _pantallas = [
    const KioskoScreen(),
    const Center(child: Text("🛠️ Aquí irá la Cocina de Camili")),
    const InventarioScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heladería', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        elevation: 0,
      ),
      body: _pantallas[_indiceActual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceActual,
        onTap: (index) {
          setState(() {
            _indiceActual = index;
          });
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Kiosko'),
          BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Cocina'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Inventario'),
        ],
      ),
    );
  }
}