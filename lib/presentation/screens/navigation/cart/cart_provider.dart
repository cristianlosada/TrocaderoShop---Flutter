import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String company;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.company,
    this.quantity = 1,
  });
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  double get totalAmount {
    return _items.values.fold(
      0.0,
      (sum, item) => sum + item.price * item.quantity,
    );
  }

  int get itemCount => _items.length;

  void addItem(String productId, String name, double price, String company) {
    if (_items.containsKey(productId)) {
      // Incrementar la cantidad
      _items[productId]!.quantity++;
    } else {
      // Agregar nuevo producto
      _items[productId] = CartItem(
        id: productId,
        name: name,
        price: price,
        company: company
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  void updateItemQuantity(String productId, int newQuantity) {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existingItem) => CartItem(
          id: existingItem.id,
          name: existingItem.name,
          price: existingItem.price,
          company: existingItem.company,
          quantity: newQuantity,
        ),
      );
      notifyListeners();
    }
  }

  void increaseQuantity(String productId) {
    if (_items.containsKey(productId)) {
      _items[productId]!.quantity++;
      notifyListeners();
    }
  }

  void decreaseQuantity(String productId) {
    if (_items.containsKey(productId)) {
      if (_items[productId]!.quantity > 1) {
        _items[productId]!.quantity--;
      } else {
        _items.remove(productId); // Elimina si la cantidad llega a 0
      }
      notifyListeners();
    }
  }
}
