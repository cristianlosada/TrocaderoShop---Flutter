import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trocadero_shop/core/utils/funtions.dart';
import 'package:trocadero_shop/presentation/widgets/common/custom_drawer.dart';
import 'package:trocadero_shop/core/constants/app_routes.dart';
import '../../widgets/detail_image_widget.dart';
import 'companies/other_companies.dart';
import 'companies/other_companies_products.dart';
import 'profile.dart';
import 'cart/cart_screen.dart';
import 'cart/cart_provider.dart';
import 'products/detail_product.dart';
import 'purcaches/person_purchases.dart';

class Personas extends StatelessWidget {
  const Personas({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrocaderoShop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF643CB9)),
        useMaterial3: true,
      ),
      home: const PersonasPage(title: 'TrocaderoShop'),
      routes: {
        AppRoutes.profile: (context) => const ProfileScreen(),
        AppRoutes.otherCompanies: (context) => const OtherCompaniesScreen(),
        AppRoutes.otherCompaniesProducts: (context) =>
            const CompanyProductListScreen(),
        AppRoutes.userPurchases: (context) => const UserPurchasesScreen(),
        AppRoutes.cart: (context) => const CartScreen(),
      },
    );
  }
}

class PersonasPage extends StatefulWidget {
  const PersonasPage({super.key, required this.title});

  final String title;

  @override
  State<PersonasPage> createState() => _PersonasPageState();
}

class _PersonasPageState extends State<PersonasPage> {
  final CollectionReference _categoriesCollection =
      FirebaseFirestore.instance.collection('categorias');
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('usuarios');
  final CollectionReference _productsCollection =
      FirebaseFirestore.instance.collection('productos');
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryId;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Scaffold(
      appBar: _buildAppBar(cart),
      drawer: const CustomDrawer(tipoUsuario: 'persona'),
      body: Column(
        children: [
          _buildCategoryHeader(),
          _buildCategoryList(),
          _buildSearchField(),
          _buildProductList(),
        ],
      ),
    );
  }

  AppBar _buildAppBar(CartProvider cart) {
    return AppBar(
      backgroundColor: const Color(0xFF643CB9),
      title: Text(
        widget.title,
        style: const TextStyle(color: Colors.white),
      ),
      actions: [
        _buildCartButton(cart),
      ],
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
    );
  }

  IconButton _buildCartButton(CartProvider cart) {
    return IconButton(
      icon: Stack(
        children: [
          const Icon(Icons.shopping_cart, color: Colors.white),
          if (cart.itemCount > 0)
            Positioned(
              right: 0,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: Colors.red,
                child: Text(
                  cart.itemCount.toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.white),
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
    );
  }

  Padding _buildCategoryHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Text(
        'Categorías',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF643CB9),
        ),
      ),
    );
  }

  StreamBuilder<QuerySnapshot> _buildCategoryList() {
    return StreamBuilder<QuerySnapshot>(
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
              final categoryIconUrl = category['path_logo'];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategoryId = categoryId;
                    _searchQuery =
                        ''; // Reinicia la búsqueda al cambiar categoría
                    _searchController.clear();
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
    );
  }

  Padding _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          labelText: 'Buscar productos',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }

  Expanded _buildProductList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: _selectedCategoryId != null
            ? _productsCollection
                .where('categoriaId', isEqualTo: _selectedCategoryId)
                .snapshots()
            : _productsCollection.snapshots(),
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
            return const Center(child: Text('No hay productos disponibles'));
          }

          final products = snapshot.data!.docs.where((product) {
            final data = product.data() as Map<String, dynamic>;
            final productName = data['nombre']?.toLowerCase() ?? '';
            return productName.contains(_searchQuery);
          }).toList();

          if (products.isEmpty) {
            return const Center(child: Text('No se encontraron productos.'));
          }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 0.7,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final productData = product.data() as Map<String, dynamic>;
              final productId = product.id;
              final empresaId = productData['empresaId'];

              return FutureBuilder<DocumentSnapshot>(
                future: usersCollection.doc(empresaId).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (userSnapshot.hasError) {
                    return const Center(
                        child: Text('Error al cargar el usuario'));
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const Center(child: Text('Usuario no encontrado'));
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  final userName =
                      userData['nombre_empresa'] ?? 'Usuario desconocido';

                  return _buildProductCard(productData, productId, userName);
                },
              );
            },
          );
        },
      ),
    );
  }

  Card _buildProductCard(
      Map<String, dynamic> productData, String productId, String userName) {
    print(productData);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(
          color: Colors.purple.shade100,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize
              .min, // Evita que la columna se expanda más allá de su contenido
          children: [
            // Imagen del producto
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: productData['imageUrls'] != null &&
                      productData['imageUrls'].isNotEmpty
                  ? buildImageCarousel(productData['imageUrls'])
                  : productData['imageUrl'] != null &&
                          productData['imageUrl'].isNotEmpty
                      ? buildImageSimple(productData['imageUrl'])
                      : buildNoImageWidget(), // Si no tiene imágenes, mostramos el icono
            ),
            const SizedBox(height: 8.0),
            // Nombre del producto
            Text(
              productData['nombre'] ?? 'Sin nombre',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4.0),
            // Descripción del producto
            Text(
              productData['descripcion'] != null
                  ? (productData['descripcion'].length > 50
                      ? '${productData['descripcion'].substring(0, 50)}...'
                      : productData['descripcion'])
                  : 'Descripción no disponible',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4.0),
            // Esto empuja el botón hacia abajo
            const Spacer(),
            // Precio del producto
            Text(
              productData['precio'] != null
                  ? Functions()
                      .formatMoney(valueMoney: productData['precio'].toString())
                  : 'Precio no disponible',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.purple),
            ),
            const SizedBox(height: 4.0),
            // Nombre del vendedor
            Text(
              'Vendido por: $userName',
              style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.purple),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            // Botón de ver detalles
            SizedBox(
              width: double.infinity, // Hace que el botón use todo el ancho
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailScreen(productId: productId)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF643CB9),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10), // Mejor padding
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Ver Detalle',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para mostrar las imágenes en una lista horizontal
  Widget buildImageCarousel(List<dynamic> images) {
    // Convertimos la lista dinámica a List<String>
    List<String> imageUrls = List<String>.from(images);

    return SizedBox(
      height: 80, // Altura del carrusel de imágenes
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: GestureDetector(
          child: DetailImageWidget(
            imagePath: imageUrls[0], // Pasamos la URL de la imagen
          ),
        ),
      ),
    );
    // SizedBox(
    //   height: 80, // Altura del carrusel de imágenes
    //   child: ListView.builder(
    //     scrollDirection: Axis.horizontal,
    //     itemCount: 1,
    //     itemBuilder: (context, index) {
    //       return Padding(
    //         padding: const EdgeInsets.only(right: 8.0),
    //         child: GestureDetector(
    //           onTap: () {
    //             _openImageViewer(context, index, imageUrls);
    //           },
    //           child: ClipRRect(
    //             borderRadius: BorderRadius.circular(10),
    //             child: Image.network(
    //               imageUrls[0], // Se pasa como List<String> ya
    //               fit: BoxFit.cover,
    //               height: 30, // Altura constante para todas las imágenes
    //             ),
    //           ),
    //         ),
    //       );
    //     },
    //   ),
    // );
  }

// Método para abrir la vista detallada con la imagen seleccionada
  void _openImageViewer(
      BuildContext context, int selectedIndex, List<String> images) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(
          images: images,
          selectedIndex: selectedIndex,
        ),
      ),
    );
  }

  Widget buildImageSimple(String image) {
    return SizedBox(
      height: 80, // Altura del carrusel de imágenes
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: DetailImageWidget(
          imagePath: image, // Pasamos la URL de la imagen
        ),
      ),
    );
  }

// Método para mostrar un icono en caso de que no haya imágenes
  Widget buildNoImageWidget() {
    return Container(
      height: 80,
      width: double.infinity,
      color: Colors.purple.shade50,
      child: const Center(
        child: Icon(
          Icons.image,
          color: Color.fromARGB(255, 209, 141, 221),
          size: 40,
        ),
      ),
    );
  }

// Método para mostrar la primera imagen utilizando DetailImageWidget
  Widget buildFirstImageWidget(Map<String, dynamic> productData) {
    // Obtener la primera imagen
    String imageUrl = getFirstImage(productData);

    // Retornar el widget para mostrar la imagen
    return SizedBox(
      height: 80, // Controla la altura de la imagen
      child: DetailImageWidget(
        imagePath: imageUrl, // Pasa la URL de la imagen
      ),
    );
  }

// Método para obtener la primera imagen del producto
  String getFirstImage(Map<String, dynamic> productData) {
    // Verifica si el producto tiene imágenes en 'imageUrls'
    if (productData['imageUrls'] != null && productData['imageUrls'] is List) {
      // Si tiene imágenes, devuelve la primera
      return productData['imageUrls'].isNotEmpty
          ? productData['imageUrls'][0]
          : 'ruta_imagen_predeterminada.png'; // Valor predeterminado si no hay imágenes
    }
    // Si no tiene imágenes, devuelve un valor predeterminado
    return 'ruta_imagen_predeterminada.png';
  }
}
