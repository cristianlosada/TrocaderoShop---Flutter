import 'package:flutter/material.dart';
import '../../core/utils/show_image.dart';

class DetailImageWidget extends StatelessWidget {
  const DetailImageWidget({super.key, required this.imagePath, this.height = 100, this.width});
  final String imagePath;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Dialogs().showImage(context, imgPath: imagePath),
      child: SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: Image.network(imagePath, fit: BoxFit.cover),
      ),
    );
  }
}
