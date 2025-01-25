import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/funtions.dart';
import '../../../widgets/detail_image_widget.dart';
import '../cart/cart_provider.dart';
import '../cart/cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ProductDetailScreenState createState() => ProductDetailScreenState();
}

class ProductDetailScreenState extends State<ProductDetailScreen> {
  final _productsCollection =
      FirebaseFirestore.instance.collection('productos');
  final _usuariosCollection = FirebaseFirestore.instance.collection('usuarios');

  Future<Map<String, dynamic>> _fetchCompanyName(String userId) async {
    final userDoc = await _usuariosCollection.doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    }
    return {'nombreEmpresa': 'Desconocido'};
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalles del Producto',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (cart.itemCount > 0)
                  Positioned(
                    right: 0,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red,
                      child: Text(
                        cart.itemCount.toString(),
                        style:
                            const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF643CB0),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _productsCollection.doc(widget.productId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
                child: Text('Error al cargar los detalles del producto'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Producto no encontrado'));
          }

          final productData = snapshot.data!.data() as Map<String, dynamic>;
          List<String> images =
              List<String>.from(productData['iamgeUrl'] ?? []);
          final userId = productData[
              'empresaId']; // Asegúrate de tener este campo en tus datos

          return FutureBuilder<Map<String, dynamic>>(
            future: _fetchCompanyName(userId),
            builder: (context, companySnapshot) {
              if (companySnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final companyData =
                  companySnapshot.data ?? {'nombreEmpresa': 'Desconocido'};
              final companyName = companyData['nombre_empresa'];

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 250,
                        child: PageView.builder(
                          itemCount: images.isEmpty ? 1 : images.length,
                          itemBuilder: (context, index) {
                            if (productData['imageUrl'] == null) {
                              return Image.asset(
                                'images/assets/LogoTrocadero.png',
                                fit: BoxFit.cover,
                                width: double.infinity,
                              );
                            }
                            return DetailImageWidget(
                              imagePath: productData['imageUrl'],
                            );
                            // Image.network(
                            //   images[index],
                            //   fit: BoxFit.cover,
                            //   width: double.infinity,
                            // );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        productData['nombre'] ?? 'Sin nombre',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        productData['descripcion'] ??
                            'Descripción no disponible',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Vendido por: $companyName',
                        style: const TextStyle(
                            fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        productData['precio'] != null
                            ? Functions().formatMoney(
                                valueMoney: productData['precio'].toString())
                            : 'Precio no disponible',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (productData['nombre'] == null ||
                              productData['precio'] == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Error: Datos del producto no válidos'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          cart.addItem(
                            widget.productId,
                            productData['nombre'],
                            productData['precio'],
                            companyName, // Añadimos el nombre de la empresa al carrito
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${productData['nombre']} añadido al carrito'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF643CB9)),
                        child: const Text(
                          'Agregar al Carrito',
                          style: TextStyle(
                              color: Colors.white,
                              backgroundColor: Color(0xFF643CB9),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
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
