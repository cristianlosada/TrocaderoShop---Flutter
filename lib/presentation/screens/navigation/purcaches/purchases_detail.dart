import 'package:flutter/material.dart';
import '../../../../core/utils/funtions.dart';
import '../products/detail_product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionDetailScreen extends StatelessWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  Future<DocumentSnapshot> _fetchTransactionDetails() async {
    return FirebaseFirestore.instance
        .collection('transactions')
        .doc(transactionId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de la compra',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF643CB0),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _fetchTransactionDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
                child: Text('Error al cargar los detalles de la transacción'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Transacción no encontrada'));
          }

          final transactionData = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> purchasedItems = transactionData['items'] ?? [];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                // Información general de la transacción
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ID de la orden: ${transactionData['orderId']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text('Fecha: ${transactionData['operationDate']}'),
                        Text('Estado: ${transactionData['status']}'),
                        Text(
                            'Código de Autorización: ${transactionData['authorizationCode']}'),
                        Text(
                            'Últimos 4 dígitos de la tarjeta: ${transactionData['cardLast4']}'),
                        Text('Dirección: ${transactionData['address']}'),
                        const SizedBox(height: 10),
                        Text(
                          'Total: ${Functions().formatMoney(valueMoney: transactionData['totalAmount'].toString())}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Lista de artículos comprados
                const Text(
                  'Artículos Comprados:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...purchasedItems.map((item) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(item['name'] ?? 'Artículo desconocido'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Empresa: ${item['company']}'),
                                Text('Cantidad: ${item['quantity']}'),
                                Text(
                                    'V. Unitario: ${Functions().formatMoney(valueMoney: item['price'].toString())}'),
                              ],
                            ),
                            trailing: Text(
                              'Subtotal: ${Functions().formatMoney(valueMoney: ((item['quantity'] ?? 0) * (item['price'] ?? 0)).toString())}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailScreen(
                                    productId: item[
                                        'id'], // Usa el ID del producto del artículo
                                  ),
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
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
