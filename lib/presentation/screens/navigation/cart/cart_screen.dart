import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/funtions.dart';
import 'cart_provider.dart';
import 'package:trocadero_shop/services/payu_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _isFormVisible = false;

  Future<void> _processPayment(BuildContext context, CartProvider cart) async {
    if (!_formKey.currentState!.validate()) {
      // Si el formulario no es válido, no se procesa el pago
      return;
    }

    // Mostrar indicador de carga
    // Mostrar indicador de carga
    var context1;
    showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (BuildContext context1Dialog) {
        // Guardamos el contexto del dialogo
        context1 = context1Dialog;
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // Llamar al servicio de PayU
      final result = await PayUService().createTransaction(
        referenceCode: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: cart.totalAmount,
        currency: "COP",
        buyerEmail:
            "cristianlosano314@gmail.com", // Correo del usuario autenticado
        buyerName: "Cristian Lozada", // Nombre del usuario autenticado
      );
      String userId = FirebaseAuth.instance.currentUser!.uid;

      if (result["transactionResponse"]["state"] == "APPROVED") {
        // Guardar datos de la transacción en Firebase
        await FirebaseFirestore.instance.collection('transactions').add({
          'userId': userId,
          'address': _addressController.text,
          'cardLast4': _cardNumberController.text
              .substring(_cardNumberController.text.length - 4),
          'totalAmount': cart.totalAmount,
          'transactionId': result["transactionResponse"]["transactionId"],
          'orderId': result["transactionResponse"]["orderId"],
          'authorizationCode': result["transactionResponse"]
              ["authorizationCode"],
          'status': result["transactionResponse"]["state"],
          'responseMessage': result["transactionResponse"]["responseMessage"],
          'operationDate': result["transactionResponse"]["operationDate"],
          'timestamp': FieldValue.serverTimestamp(),
          'items': cart.items.values.map((item) {
            return {
              'id': item.id,
              'name': item.name,
              'price': item.price,
              'quantity': item.quantity,
              'company': item.company,
            };
          }).toList(),
        });

        cart.clearCart(); // Limpiar carrito

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compra realizada con éxito')),
        );
      } else {
        final errorMessage = result["error"] ??
            result["transactionResponse"]?["responseCode"] ??
            "Error desconocido";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en el pago: $errorMessage')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ocurrió un error: ${e.toString()}')),
      );
    } finally {
      // Cerrar el indicador de carga
      if (context1 != null) {
        Navigator.pop(context1); // Usar el contexto del diálogo
      }
    }
  }

  void hideLoader(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    _addressController.text = "Calle Falsa 123";
    _cardNumberController.text = "0000111122223333";
    _expiryDateController.text = "2025/01";
    _cvvController.text = "456";
  }

  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final cartItems = cart.items.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Carrito de Compras',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF643CB9),
        iconTheme: const IconThemeData(
          color: Colors.white, // Color blanco para el ícono de retroceso
        ),
      ),
      body: Column(
        children: [
          if (cartItems.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'El carrito está vacío',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (ctx, i) => Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(cartItems[i].quantity.toString()),
                    ),
                    title: Text(cartItems[i].name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Precio: ${Functions().formatMoney(valueMoney: cartItems[i].price.toString())}'),
                        Text(
                          'Por: ${cartItems[i].company}',
                          style: const TextStyle(color: Colors.purple),
                        ), // Mostrar el nombre de la empresa
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (cartItems[i].quantity > 1) {
                              cart.updateItemQuantity(
                                  cartItems[i].id, cartItems[i].quantity - 1);
                            } else {
                              cart.removeItem(cartItems[i].id);
                            }
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                          color: const Color(0xFF643CB9), // Color AppBar
                        ),
                        IconButton(
                          onPressed: () {
                            cart.updateItemQuantity(
                                cartItems[i].id, cartItems[i].quantity + 1);
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          color: const Color(0xFF643CB9), // Color AppBar
                        ),
                        IconButton(
                          onPressed: () {
                            cart.removeItem(cartItems[i].id);
                          },
                          icon: const Icon(Icons.delete),
                          color: const Color(0xFF643CB9), // Color AppBar
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  ExpansionTile(
                    leading: const Icon(Icons.payment),
                    title: const Text(
                      'Agregar Detalle de Pago',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    initiallyExpanded: _isFormVisible,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _isFormVisible = expanded;
                      });
                    },
                    children: [
                      TextFormField(
                        controller: _addressController,
                        decoration:
                            const InputDecoration(labelText: 'Dirección'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu dirección';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _cardNumberController,
                        decoration: const InputDecoration(
                            labelText: 'Número de Tarjeta'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa el número de tarjeta';
                          }
                          if (!RegExp(r'^[0-9]{16}$').hasMatch(value)) {
                            return 'El número de tarjeta debe ser numérico y de 16 dígitos';
                          }
                          return null;
                        },
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _expiryDateController,
                              decoration: const InputDecoration(
                                  labelText: 'Fecha Exp. (AAAA/MM)'),
                              keyboardType: TextInputType.datetime,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa la fecha de expiración';
                                }
                                if (!RegExp(r'^\d{4}/\d{2}$').hasMatch(value)) {
                                  return 'El formato debe ser AAAA/MM';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _cvvController,
                              decoration:
                                  const InputDecoration(labelText: 'CVV'),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa el CVV';
                                }
                                if (!RegExp(r'^\d{3}$').hasMatch(value)) {
                                  return 'El CVV debe tener 3 dígitos numéricos';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Chip(
                        label: Text(
                          Functions().formatMoney(
                              valueMoney: cart.totalAmount.toString()),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: const Color(0xFF643CB9),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: cart.items.isEmpty
                        ? null // Deshabilita el botón si el carrito está vacío
                        : () => _processPayment(context, cart),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: cart.items.isEmpty
                          ? Colors
                              .purple // Cambia el color del botón si está deshabilitado
                          : const Color(0xFF643CB9),
                    ),
                    child: const Text(
                      'Comprar Ahora',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }
}
