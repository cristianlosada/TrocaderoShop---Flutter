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
}
