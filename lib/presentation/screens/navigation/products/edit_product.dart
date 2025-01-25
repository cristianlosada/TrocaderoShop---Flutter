import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String productId;

  const EditProductScreen(
      {super.key, required this.productData, required this.productId});

  @override
  EditProductScreenState createState() => EditProductScreenState();
}

class EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final ImagePicker _picker = ImagePicker(); // accede a la imagen
  bool _isLoading = false;
  File? _imageFile;

  @override
  void initState() {
    super.initState();

    // Inicializa los controladores con los valores actuales
    _nombreController.text = widget.productData['nombre'] ?? '';
    _descripcionController.text = widget.productData['descripcion'] ?? '';
    _precioController.text = widget.productData['precio']?.toString() ?? '';
  }

  // Selecciona una imagen
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Sube la imagen a Firebase Storage y obtiene la URL
  Future<String?> _uploadImage(File image) async {
    try {
      // Referencia única para cada archivo subido
      final ref = FirebaseStorage.instance
          .ref()
          .child('product_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Sube el archivo
      await ref.putFile(image);

      // Obtén la URL del archivo subido
      return await ref.getDownloadURL();
    } catch (e) {
      print("Error al subir la imagen: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir la imagen: ${e.toString()}')),
        );
      }
      return null;
    }
  }

  Future<void> listFiles() async {
    try {
      print('inicio');
      final ref = FirebaseStorage.instance.ref().child('product_images');
      print(ref);
      final listResult = await ref.listAll();
      for (var item in listResult.items) {
        print('Archivo encontrado: ${item.name}');
      }
    } catch (e) {
      print('Error al listar archivos: $e');
    }
  }

  // Envia los datos del producto a Firestore
  Future<void> _submitProduct() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      String? imageUrl;

      // Subir imagen si existe una seleccionada
      if (_imageFile != null) {
        imageUrl = null;
        imageUrl = await _uploadImage(_imageFile!);
      }

      // await listFiles();
      // Verificar si la URL de la imagen es válida
      if (imageUrl != null || _imageFile == null) {
        try {
          // Actualizar los datos en Firestore
          await FirebaseFirestore.instance
              .collection('productos')
              .doc(widget.productId)
              .update({
            'nombre': _nombreController.text,
            'descripcion': _descripcionController.text,
            'precio': double.tryParse(_precioController.text) ?? 0,
            'imageUrl': imageUrl ?? widget.productData['imageUrl'],
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Producto actualizado con éxito')),
            );

            Navigator.pop(context); // Regresa a la vista anterior
          }
        } catch (e) {
          print("Error al actualizar producto: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al actualizar producto: $e')),
            );
          }
        }
      }

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Producto',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF643CB9),
        iconTheme: const IconThemeData(
          color: Colors.white, // Color blanco para el ícono de retroceso
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Imagen del producto
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : const Center(child: Text('Seleccionar Imagen')),
                ),
              ),
              const SizedBox(height: 10),
              // Campo de texto para el nombre
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Producto',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),

              // Campo de texto para la descripción
              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),

              // Campo de texto para el precio
              TextFormField(
                controller: _precioController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Precio',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),

              // Botón para guardar cambios
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF643CB4),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Guardar Cambios',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
