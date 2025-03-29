import 'package:flutter/material.dart';

class DetailImageWidget extends StatelessWidget {
  const DetailImageWidget({
    super.key,
    required this.imagePath,
    this.height = 100,
    this.width,
  });
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

class Dialogs {
  Future<void> showImage(BuildContext context,
      {required String imgPath}) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.transparent, // Fondo transparente
        content: Image.network(imgPath, fit: BoxFit.cover),
      ),
    );
  }
}

class ImageCarouselWithDetailView extends StatefulWidget {
  final List<String> images;

  const ImageCarouselWithDetailView({super.key, required this.images});

  @override
  _ImageCarouselWithDetailViewState createState() =>
      _ImageCarouselWithDetailViewState();
}

class _ImageCarouselWithDetailViewState
    extends State<ImageCarouselWithDetailView> {
  int _selectedIndex = 0; // El índice de la imagen seleccionada

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200, // Ajusta el tamaño del carrusel
          child: PageView.builder(
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    _openImageViewer(
                        context, index); // Abre la imagen en la vista detallada
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.cover,
                      height: 150, // Altura constante para cada imagen
                      width: 150, // Ancho constante para cada imagen
                    ),
                  ),
                ),
              );
            },
            controller: PageController(initialPage: _selectedIndex),
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index; // Actualiza el índice seleccionado
              });
            },
          ),
        ),
        const SizedBox(height: 10),
        // Indicadores de las imágenes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.images.length,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: CircleAvatar(
                radius: 5,
                backgroundColor: _selectedIndex == index
                    ? Colors.purple.shade700 // Color para el punto seleccionado
                    : Colors.purple
                        .shade200, // Color para los puntos no seleccionados
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Método para abrir la vista detallada con la imagen seleccionada
  void _openImageViewer(BuildContext context, int selectedIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(
          images: widget.images,
          selectedIndex: selectedIndex,
        ),
      ),
    );
  }
}

class ImageViewerScreen extends StatelessWidget {
  final List<String> images;
  final int selectedIndex;

  const ImageViewerScreen({
    super.key,
    required this.images,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Fondo transparente
      body: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.pop(
                context); // Cierra la vista flotante al tocar fuera de la imagen
          },
          child: PageView.builder(
            itemCount: images.length,
            controller: PageController(initialPage: selectedIndex),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context); // Cierra la vista al tocar la imagen
                },
                child: Center(
                  child: Image.network(
                    images[index],
                    fit: BoxFit.contain, // Ajuste de la imagen
                    width: MediaQuery.of(context).size.width *
                        0.8, // 80% del ancho de la pantalla
                    height: MediaQuery.of(context).size.height *
                        0.6, // 60% de la altura de la pantalla
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
