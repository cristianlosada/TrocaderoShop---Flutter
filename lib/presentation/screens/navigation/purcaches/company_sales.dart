import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/funtions.dart';

class CompanySalesScreen extends StatelessWidget {
  const CompanySalesScreen({super.key});

  Future<Map<String, dynamic>> _fetchCompanySalesData() async {
    final companyId = FirebaseAuth.instance.currentUser!.uid;

    // Obtener todos los productos de la empresa
    final productsSnapshot = await FirebaseFirestore.instance
        .collection('productos')
        .where('empresaId', isEqualTo: companyId)
        .get();

    final productIds = productsSnapshot.docs.map((doc) => doc.id).toSet();
    print(productsSnapshot.docs);

    // Obtener transacciones que contengan productos de esta empresa
    final transactionsSnapshot =
        await FirebaseFirestore.instance.collection('transactions').get();

    final Map<String, Map<String, dynamic>> productSales = {};
    double totalRevenue = 0;
    int totalItemsSold = 0;

    for (var doc in transactionsSnapshot.docs) {
      final transaction = doc.data();
      final items = List<Map<String, dynamic>>.from(transaction['items'] ?? []);

      for (var item in items) {
        final productId = item['id'];

        // Verificar si el producto pertenece a esta empresa
        if (productIds.contains(productId)) {
          int quantity = item['quantity'] ?? 0;
          final price = item['price'] ?? 0;

          if (!productSales.containsKey(productId)) {
            productSales[productId] = {
              'name': item['name'],
              'quantitySold': 0,
              'totalRevenue': 0,
            };
          }

          productSales[productId]!['quantitySold'] += quantity;
          productSales[productId]!['totalRevenue'] += quantity * price;

          totalItemsSold += quantity;
          totalRevenue += quantity * price;
        }
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'totalItemsSold': totalItemsSold,
      'productSales': productSales.values.toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Análisis de Ventas',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF643CB0),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchCompanySalesData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al cargar el análisis de ventas'),
            );
          }

          final salesData = snapshot.data!;
          final totalRevenue = salesData['totalRevenue'];
          final totalItemsSold = salesData['totalItemsSold'];
          final productSales =
              List<Map<String, dynamic>>.from(salesData['productSales'] ?? []);

          if (productSales.isEmpty) {
            return const Center(
              child: Text(
                'No se encontraron ventas para esta empresa.',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(10),
            children: [
              Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total ingresos: ${Functions().formatMoney(valueMoney: totalRevenue.toString())}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Total productos vendidos: $totalItemsSold',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const Text(
                'Ventas por producto:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ...productSales.map((product) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      title: Text(
                        product['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Cantidad vendida: ${product['quantitySold']} unidades'),
                          Text(
                              'Ingresos generados: ${Functions().formatMoney(valueMoney: product['totalRevenue'].toString())}'),
                        ],
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
