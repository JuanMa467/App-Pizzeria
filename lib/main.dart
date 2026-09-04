import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // El paquete de Supabase

// Hacemos que el main sea asíncrono (async) porque conectarse al servidor toma unos instantes
Future<void> main() async {
  // Esta línea es obligatoria en Flutter antes de inicializar conexiones externas
  WidgetsFlutterBinding.ensureInitialized();

  // Pegá acá los datos de tu proyecto
  await Supabase.initialize(
    url: 'https://ualdwdfloeneklfcxzvw.supabase.co',
    anonKey: 'sb_publishable_JphILmc8tUaUsFkSxDSxjg_OSwX7hDk',
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => Carrito(),
      child: const PizzeriaApp(),
    ),
  );
}


// Fase 2: Esta clase es el "cerebro" que guarda el estado de tus pedidos
class Carrito extends ChangeNotifier {
  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;
  int get cantidadTotal => _items.length;

  void vaciarCarrito() {
    _items.clear();
    notifyListeners();
  }

  void agregarPizza(Map<String, dynamic> pizza) {
    _items.add(pizza);
    notifyListeners(); // Este comando avisa a la interfaz que redibuje los datos
  }
}

class PizzeriaApp extends StatelessWidget {
  const PizzeriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestor Pizzería',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const MenuPrincipal(),
    );
  }
}

class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    // Le pedimos a Supabase la lista de productos ordenada por ID
    final futurePizzas = Supabase.instance.client
        .from('productos')
        .select()
        .order('id', ascending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú de Pizzas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.kitchen, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PantallaAdmin()));
            },
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PantallaCarrito()));
            },
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Consumer<Carrito>(
                  builder: (context, carrito, child) {
                    return Text(
                      '🛒 ${carrito.cantidadTotal}',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: futurePizzas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Cargando menú...'));
          }

          final pizzas = snapshot.data!;

          return ListView.builder(
            itemCount: pizzas.length,
            itemBuilder: (context, index) {
              final pizza = pizzas[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: const Icon(Icons.local_pizza, color: Colors.deepOrange, size: 40),
                  title: Text(pizza['nombre'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('${pizza['descripcion']}\n\$${pizza['precio']}', style: const TextStyle(fontSize: 14)),
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.add_shopping_cart, size: 28),
                    color: Colors.green,
                    onPressed: () {
                      context.read<Carrito>().agregarPizza(pizza);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${pizza['nombre']} agregada al carrito'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
class PantallaCarrito extends StatelessWidget {
  const PantallaCarrito({super.key});

  @override
  Widget build(BuildContext context) {
    // context.watch se queda escuchando los cambios en el carrito
    final carrito = context.watch<Carrito>();
    // Sumamos todos los precios usando fold
    final total = carrito.items.fold(0, (suma, item) => suma + (item['precio'] as int));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu Pedido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepOrange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: carrito.items.isEmpty
          ? const Center(child: Text('El carrito está vacío 🍕', style: TextStyle(fontSize: 18)))
          : ListView.builder(
        itemCount: carrito.items.length,
        itemBuilder: (context, index) {
          final pizza = carrito.items[index];
          return ListTile(
            leading: const Icon(Icons.fastfood, color: Colors.orange),
            title: Text(pizza['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text('\$${pizza['precio']}', style: const TextStyle(fontSize: 16)),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.orange.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total: \$$total', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                // Le agregamos 'async' porque la conexión a internet toma tiempo
                onPressed: carrito.items.isEmpty ? null : () async {
                  try {
                    // 1. Armamos el paquete de datos tal cual lo pide PostgreSQL
                    final nuevaComanda = {
                      'total': total,
                      'detalle_pizzas': carrito.items, // Flutter lo convierte a JSON automáticamente
                      // Los campos 'estado' y 'fecha_creacion' los completa Supabase por defecto
                    };

                    // 2. Ejecutamos la inserción en la tabla 'comandas'
                    await Supabase.instance.client
                        .from('comandas')
                        .insert(nuevaComanda);

                    // 3. Si sale bien: mostramos aviso, vaciamos carrito y volvemos al menú
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('¡Comanda recibida en la cocina! 🚀'),
                            backgroundColor: Colors.green
                        ),
                      );
                      context.read<Carrito>().vaciarCarrito();
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    // 4. Si se corta el internet o hay un error, lo atajamos acá
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Fallo de conexión: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: const Text('Confirmar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
class PantallaAdmin extends StatelessWidget {
  const PantallaAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    // stream() mantiene la conexión en vivo.
    final streamComandas = Supabase.instance.client
        .from('comandas')
        .stream(primaryKey: ['id'])
        .order('fecha_creacion', ascending: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Cocina', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: streamComandas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay pedidos activos 👨‍🍳', style: TextStyle(fontSize: 18)));
          }

          final comandas = snapshot.data!;

          return ListView.builder(
            itemCount: comandas.length,
            itemBuilder: (context, index) {
              final pedido = comandas[index];
              // Cambiamos el color de la tarjeta para identificar rápido lo que falta hacer
              final colorEstado = pedido['estado'] == 'pendiente' ? Colors.orange.shade100 : Colors.green.shade100;

              return Card(
                color: colorEstado,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Pedido #${pedido['id']} - Total: \$${pedido['total']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Estado: ${pedido['estado'].toString().toUpperCase()}'),
                  trailing: pedido['estado'] == 'pendiente'
                      ? ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () async {
                      try {
                        // Actualizamos el estado directamente en la nube
                        await Supabase.instance.client
                            .from('comandas')
                            .update({'estado': 'listo'})
                            .eq('id', pedido['id']);

                        // Aviso de éxito
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('¡Pedido marcado como listo! ✅')),
                          );
                        }
                      } catch (e) {
                        // Si falla por algún motivo, te avisa en pantalla
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al actualizar: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    child: const Text('Completar', style: TextStyle(color: Colors.white)),
                  ) : const Icon(Icons.check_circle, color: Colors.green, size: 32),
                ),
              );
            },
          );
        },
      ),
    );
  }
}