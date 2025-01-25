import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Functions {
  String formatMoney({required String valueMoney}) {
    try {
      final double moneyValue = double.parse(valueMoney);
      return NumberFormat.currency(
              locale: 'es_CO',
              symbol: '\$',
              customPattern: '\u00A4#,##0.00' // Coloca el símbolo primero
              )
          .format(moneyValue);
    } catch (e) {
      print('Error al formatear el valor: $e');
      return valueMoney;
    }
  }

  Future<void> showImage(BuildContext context,
      {required String imgPath}) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Image.network(imgPath, fit: BoxFit.cover),
      ),
    );
  }

  Future<void> showErrorSnackBar(BuildContext context,
      {required String message}) async {
    await ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> showSuccessSnackBar(BuildContext context,
      {required String message}) async {
    await ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
