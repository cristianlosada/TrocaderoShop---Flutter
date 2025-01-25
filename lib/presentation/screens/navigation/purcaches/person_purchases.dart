import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/utils/funtions.dart';
import 'purchases_detail.dart';

class UserPurchasesScreen extends StatelessWidget {
  const UserPurchasesScreen({super.key});

  Future<List<Map<String, dynamic>>> _fetchUserPurchases() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Consultar Firestore para obtener las compras del usuario actual
    final purchasesSnapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();

    // Convertir los documentos en una lista de mapas
    return purchasesSnapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Compras', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF643CB0),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUserPurchases(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al cargar tus compras'),
            );
          }

          final purchases = snapshot.data ?? [];

          if (purchases.isEmpty) {
            return const Center(
              child: Text(
                'Aún no has realizado compras.',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            );
          }

          return ListView.builder(
            itemCount: purchases.length,
            itemBuilder: (context, index) {
              final purchase = purchases[index];
              final items = List<Map<String, dynamic>>.from(purchase['items']);
              final formattedDate =
                  (purchase['timestamp'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  title: Text(
                    'Compra - ${purchase['orderId'] ?? 'Sin ID'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(
                        'Fecha: ${formattedDate.toLocal()}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Total: ${Functions().formatMoney(valueMoney: purchase['totalAmount'].toString())}',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.purple),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Productos:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...items.map(
                        (item) => Text(
                          '- ${item['name']} x${item['quantity']} (${Functions().formatMoney(valueMoney: item['price'].toString())})',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TransactionDetailScreen(
                          transactionId:
                              purchase['id'], // Pasamos el ID de la transacción
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
