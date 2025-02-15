import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:trocadero_shop/presentation/widgets/common/custom_drawer.dart';
import 'package:trocadero_shop/core/constants/app_routes.dart';
import '../../../core/utils/funtions.dart';
import '../../../core/utils/show_image.dart';
import '../../widgets/detail_image_widget.dart';
import 'products/detail_product.dart';
import 'products/products.dart';
import 'companies/other_companies.dart';
import 'companies/other_companies_products.dart';
import 'products/edit_product.dart';
import 'purcaches/company_sales.dart';
import 'profile.dart';

class Empresas extends StatelessWidget {
  const Empresas({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrocaderoShop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF643CB9)),
        useMaterial3: true,
      ),
      home: const EmpresasPage(title: 'Panel de Control Empresas'),
      routes: {
        AppRoutes.addProduct: (context) => const ProductsScreen(),
        AppRoutes.otherCompanies: (context) => const OtherCompaniesScreen(),
        AppRoutes.otherCompaniesProducts: (context) =>
            const CompanyProductListScreen(),
        AppRoutes.profile: (context) => const ProfileScreen(),
        AppRoutes.companySales: (context) => const CompanySalesScreen(),
      },
    );
  }
}

class EmpresasPage extends StatefulWidget {
  const EmpresasPage({super.key, required this.title});
  final String title;

  @override
  State<EmpresasPage> createState() => _EmpresasPageState();
}

class _EmpresasPageState extends State<EmpresasPage> {
  String? _selectedCategoryId; // ID de la categoría seleccionada
  final String userType = 'empresa';
  final CollectionReference _categoriesCollection =
      FirebaseFirestore.instance.collection('categorias');
  final CollectionReference _productsCollection =
      FirebaseFirestore.instance.collection('productos');

  @override
  void initState() {
    super.initState();
    _loadFirstCategory();
  }

  // Cargar la primera categoría de forma predeterminada
  Future<void> _loadFirstCategory() async {
    final snapshot = await _categoriesCollection.limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _selectedCategoryId = snapshot.docs.first.id;
      });
    }
  }

  // Cargar la primera categoría de forma predeterminada
  Future<void> _deleteProduct(productId) async {
    try {
      await _productsCollection.doc(productId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto eliminado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar el producto: $e')),
        );
      }
    }
  }

  Future<String> getFile(String routeImage) async {
    // Cargar archivo desde Firebase Storage
    String routeImageFirebase = '';
    try {
      final ref = FirebaseStorage.instance.refFromURL(routeImage);
      routeImageFirebase = await ref.getDownloadURL();
      return routeImageFirebase;
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF643CB9),
        title: Text(widget.title,
            style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu,
                color: Color.fromARGB(255, 255, 255, 255)),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add,
                color: Color.fromARGB(255, 255, 255, 255)),
            onPressed: () {
              Navigator.pushNamed(context, '/add_product');
            },
          ),
        ],
      ),
      drawer: const CustomDrawer(tipoUsuario: 'empresa'),
      body: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // IconButton(
              //   icon: const Icon(Icons.arrow_back),
              //   onPressed: () {},
              // ),
              Text(
                '',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'Categorías',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 3,
                    color: Color(0xFF643CB9)),
              ),
              Text(
                '',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              )
              // IconButton(
              //   icon: const Icon(Icons.arrow_forward),
              //   onPressed: () {},
              // ),
            ],
          ),
          const SizedBox(height: 5),
          // Lista horizontal de categorías
          StreamBuilder<QuerySnapshot>(
            stream: _categoriesCollection.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final categories = snapshot.data!.docs;
              return SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final categoryId = category.id;
                    final categoryName = category['nombre'];
                    final categoryIconUrl =
                        category['path_logo']; // URL del icono

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = categoryId;
                        });
                      },
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: [
                            Functions().svgAvatar(
                                routeIcon: 'images/assets/$categoryIconUrl'),
                            const SizedBox(height: 5),
                            Text(
                              categoryName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _selectedCategoryId == categoryId
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _selectedCategoryId == categoryId
                                    ? Colors.purple
                                    : Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          // Lista de productos según la categoría seleccionada
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _productsCollection
                  .where('categoriaId', isEqualTo: _selectedCategoryId)
                  .where('empresaId',
                      isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Error al cargar los datos'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No hay productos disponibles'));
                }

                final products = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final productData = product.data() as Map<String, dynamic>;
                    final productId = product.id;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          side: BorderSide(
                            color: Colors.purple.shade100,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (productData['imageUrl'] != null)
                                DetailImageWidget(
                                  imagePath: productData['imageUrl'],
                                )
                              else
                                Container(
                                  height: 100,
                                  color: Colors.purple.shade50,
                                  child: Center(
                                    child: Icon(
                                      Icons.image,
                                      color: Colors.purple.shade200,
                                      size: 50,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8.0),
                              Text(
                                productData['nombre'] ?? 'Sin nombre',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                productData['descripcion'] ??
                                    'Descripción no disponible',
                                style: const TextStyle(fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                productData['precio'] != null
                                    ? Functions().formatMoney(
                                        valueMoney:
                                            productData['precio'].toString())
                                    : 'Precio no disponible',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.purple,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Botón de ver detalles
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailScreen(
                                          productId: productId),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF643CB9),
                                ),
                                child: const Text(
                                  'Ver Detalle',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              // Botón de editar
                              ElevatedButton(
                                onPressed: () {
                                  // Aquí puedes navegar a una pantalla de edición o realizar alguna otra acción
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditProductScreen(
                                          productData: productData,
                                          productId: productId),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  iconColor:
                                      Colors.purple.shade300, // Color del botón
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Ícono de Editar
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit, // Ícono de editar
                                        color: Colors.purple.shade300,
                                        size: 30,
                                      ),
                                      onPressed: () {
                                        // Acción de editar producto
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EditProductScreen(
                                                    productData: productData,
                                                    productId: productId),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(
                                        width: 16), // Espacio entre los íconos
                                    // Ícono de Eliminar
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete, // Ícono de eliminar
                                        color: Colors.red.shade400,
                                        size: 30,
                                      ),
                                      onPressed: () {
                                        // Acción de eliminar producto
                                        _deleteProduct(productId);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
