import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/funtions.dart';

class CompanyProductListScreen extends StatefulWidget {
  const CompanyProductListScreen({Key? key}) : super(key: key);

  @override
  _CompanyProductListScreenState createState() =>
      _CompanyProductListScreenState();
}

class _CompanyProductListScreenState extends State<CompanyProductListScreen> {
  final _usuariosCollection = FirebaseFirestore.instance.collection('usuarios');
  final _productosCollection =
      FirebaseFirestore.instance.collection('productos');

  Future<List<Map<String, dynamic>>> _fetchCompaniesAndProducts() async {
    final companiesSnapshot = await _usuariosCollection
        .where('tipo_usuario', isEqualTo: 'empresa')
        .get();

    List<Map<String, dynamic>> companyProductData = [];

    for (var companyDoc in companiesSnapshot.docs) {
      final companyData = companyDoc.data();
      final companyId = companyDoc.id;

      final productsSnapshot = await _productosCollection
          .where('empresaId', isEqualTo: companyId)
          .get();

      List<Map<String, dynamic>> products =
          productsSnapshot.docs.map((productDoc) {
        final productData = productDoc.data();
        return {
          'nombre': productData['nombre'] ?? 'Sin nombre',
          'precio': productData['precio'] ?? 'Sin precio',
        };
      }).toList();

      companyProductData.add({
        'nombre_empresa': companyData['nombre_empresa'] ?? 'Sin nombre',
        'productos': products,
      });
    }

    return companyProductData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Empresas y Productos',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF643CB9),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchCompaniesAndProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al cargar los datos'),
            );
          }

          final companiesData = snapshot.data ?? [];

          if (companiesData.isEmpty) {
            return const Center(
              child: Text('No se encontraron empresas con productos'),
            );
          }

          return ListView.builder(
            itemCount: companiesData.length,
            itemBuilder: (context, index) {
              final company = companiesData[index];
              final products =
                  company['productos'] as List<Map<String, dynamic>>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ExpansionTile(
                  title: Text(
                    company['nombre_empresa'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  children: products.map((product) {
                    return ListTile(
                      title: Text(product['nombre']),
                      subtitle: Text(
                        product['precio'] != 'Sin precio'
                            ? Functions().formatMoney(
                                valueMoney: product['precio'].toString())
                            : 'Precio no disponible',
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
