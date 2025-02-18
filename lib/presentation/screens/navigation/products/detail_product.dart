import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/funtions.dart';
import '../../../widgets/detail_image_widget.dart';
import '../cart/cart_provider.dart';
import '../cart/cart_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: _buildAppBar(context, cart),
      body: FutureBuilder<String>(
        future: _fetchUserType(), // Obtiene el tipo de usuario
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final String userType =
              userSnapshot.data ?? 'persona'; // 'persona' por defecto
          final bool isEmpresa =
              userType == 'empresa'; // Verifica si el usuario es empresa

          return FutureProvider<DocumentSnapshot?>(
            create: (_) => _fetchProduct(productId),
            initialData: null,
            catchError: (_, __) => null,
            child: Consumer<DocumentSnapshot?>(
              builder: (context, snapshot, _) {
                if (snapshot == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.exists) {
                  return const Center(child: Text('Producto no encontrado'));
                }

                final productData =
                    snapshot.data() as Map<String, dynamic>? ?? {};
                final userId = productData['empresaId'] ?? '';

                return FutureProvider<Map<String, dynamic>>(
                  create: (_) => _fetchCompanyName(userId),
                  initialData: const {'nombre_empresa': 'Desconocido'},
                  child: Consumer<Map<String, dynamic>>(
                    builder: (context, companyData, _) {
                      final companyName =
                          companyData['nombre_empresa'] ?? 'Desconocido';

                      // ✅ Manejo de imágenes
                      List<String> images = [];
                      if (productData['imageUrl'] is String) {
                        images = [productData['imageUrl']];
                      } else if (productData['imageUrl'] is List) {
                        images = List<String>.from(productData['imageUrl']);
                      }

                      // ✅ Extraer `fields` del producto
                      Map<String, dynamic> additionalFields =
                          productData['additionalFields'] ?? {};

                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ListView(
                          children: [
                            _buildImageCarousel(images, productData),
                            const SizedBox(height: 20),
                            _buildProductInfo(productData, companyName),
                            const SizedBox(height: 20),
                            _buildAdditionalFields(additionalFields),
                            const SizedBox(height: 20),
                            _buildPrice(productData),
                            const SizedBox(height: 20),
                            if (!isEmpresa) //Ocultar botón si el usuario es empresa
                              _buildAddToCartButton(
                                  context, productData, cart, companyName),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // 🔹 Obtiene el tipo de usuario actual desde Firestore
  Future<String> _fetchUserType() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null)
      return 'persona'; // Si no hay usuario, por defecto es 'persona'

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .get();
      return userDoc.exists
          ? (userDoc.data()?['tipo_usuario'] ?? 'persona')
          : 'persona';
    } catch (e) {
      debugPrint("Error al obtener tipo de usuario: $e");
      return 'persona';
    }
  }

  // 🔹 AppBar con validación para ocultar el botón del carrito si el usuario es empresa
  AppBar _buildAppBar(BuildContext context, CartProvider cart) {
    return AppBar(
      title: const Text('Detalles del Producto',
          style: TextStyle(color: Colors.white)),
      actions: [
        FutureBuilder<String>(
          future: _fetchUserType(), // Obtiene el tipo de usuario
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(); // 🔹 No muestra nada mientras carga
            }

            final String userType =
                userSnapshot.data ?? 'persona'; // 🔹 'persona' por defecto
            final bool isEmpresa =
                userType == 'empresa'; // 🔹 Verifica si el usuario es empresa

            if (isEmpresa)
              return const SizedBox(); // Si es empresa, no muestra el botón

            return IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.shopping_cart),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 0,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.red,
                        child: Text(cart.itemCount.toString(),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white)),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CartScreen()));
              },
            );
          },
        ),
      ],
      iconTheme: const IconThemeData(color: Colors.white),
      backgroundColor: const Color(0xFF643CB0),
    );
  }

  // 🔹 Carrusel de imágenes
  Widget _buildImageCarousel(
      List<String> images, Map<String, dynamic> productData) {
    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: images.isNotEmpty ? images.length : 1,
        itemBuilder: (context, index) {
          return images.isNotEmpty
              ? DetailImageWidget(imagePath: images[index])
              : Image.asset('images/assets/LogoTrocadero.png',
                  fit: BoxFit.cover, width: double.infinity);
        },
      ),
    );
  }

  // 🔹 Información del producto
  Widget _buildProductInfo(
      Map<String, dynamic> productData, String companyName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          productData['nombre'] ?? 'Sin nombre',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        const SizedBox(height: 10),
        Text(
          productData['descripcion'] ?? 'Descripción no disponible',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 10),
        Text(
          'Vendido por: $companyName',
          style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  // 🔹 Mostrar precio
  Widget _buildPrice(Map<String, dynamic> productData) {
    return Text(
      productData['precio'] != null
          ? Functions()
              .formatMoney(valueMoney: productData['precio'].toString())
          : 'Precio no disponible',
      style: const TextStyle(
          fontWeight: FontWeight.bold, fontSize: 20, color: Colors.purple),
    );
  }

  // 🔹 Mostrar campos adicionales (`fields`)
  Widget _buildAdditionalFields(Map<String, dynamic> additionalFields) {
    if (additionalFields.isEmpty) {
      return const SizedBox(); // Si no hay campos, no mostrar nada
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: additionalFields.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            '${entry.key}: ${entry.value}',
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        );
      }).toList(),
    );
  }

  // 🔹 Botón para agregar al carrito (Restringido para empresas)
  Widget _buildAddToCartButton(BuildContext context,
      Map<String, dynamic> productData, CartProvider cart, String companyName) {
    return ElevatedButton(
      onPressed: () {
        if (productData['nombre'] == null || productData['precio'] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Error: Datos del producto no válidos'),
                duration: Duration(seconds: 2)),
          );
          return;
        }

        cart.addItem(productId, productData['nombre'], productData['precio'],
            companyName);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${productData['nombre']} añadido al carrito'),
              duration: const Duration(seconds: 2)),
        );
      },
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF643CB9)),
      child: const Text('Agregar al Carrito',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  // 🔹 Función para obtener detalles del producto
  Future<DocumentSnapshot?> _fetchProduct(String productId) async {
    try {
      return await FirebaseFirestore.instance
          .collection('productos')
          .doc(productId)
          .get();
    } catch (e) {
      debugPrint("Error al obtener el producto: $e");
      return null;
    }
  }

  // 🔹 Función para obtener la empresa del vendedor
  Future<Map<String, dynamic>> _fetchCompanyName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .get();
      return userDoc.exists
          ? userDoc.data() as Map<String, dynamic>
          : {'nombre_empresa': 'Desconocido'};
    } catch (e) {
      debugPrint("Error al obtener datos de la empresa: $e");
      return {'nombre_empresa': 'Desconocido'};
    }
  }
}
