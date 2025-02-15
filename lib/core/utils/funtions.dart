import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  Widget svgAvatar({
    required String routeIcon, // Debe ser una ruta del asset
    double size = 60,
    Color? bgColor,
  }) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bgColor ?? Colors.grey.shade200,
      child: SvgPicture.asset(
        routeIcon, // Ruta del SVG en assets
        width: size * 0.6,
        height: size * 0.6,
        colorFilter: const ColorFilter.mode(
            Color(0xFF643CB9), BlendMode.srcIn), // Cambia el color
      ),
    );
  }
}
