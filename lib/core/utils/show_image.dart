import 'package:flutter/material.dart';

class Dialogs {
  Future<void> showImage(BuildContext context,
      {required String imgPath}) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Image.network(imgPath, fit: BoxFit.cover),
      ),
    );
  }
}
