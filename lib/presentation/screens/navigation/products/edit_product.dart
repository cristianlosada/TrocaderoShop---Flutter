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
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  File? _imageFile;

  // Mapa de controladores para los campos dinámicos
  Map<String, TextEditingController> _dynamicFieldControllers = {};
  Map<String, dynamic> _additionalFields = {};

  @override
  void initState() {
    super.initState();

    // Cargar datos en los controladores
    _nombreController.text = widget.productData['nombre'] ?? '';
    _descripcionController.text = widget.productData['descripcion'] ?? '';
    _precioController.text = widget.productData['precio']?.toString() ?? '';

    // Cargar `additionalFields` si existen
    _additionalFields = widget.productData['additionalFields'] ?? {};
    _initializeDynamicFieldControllers();
  }

  // Inicializa los controladores para los campos dinámicos
  void _initializeDynamicFieldControllers() {
    _additionalFields.forEach((key, value) {
      _dynamicFieldControllers[key] =
          TextEditingController(text: value.toString());
    });
  }

  // Selecciona una imagen
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  // Sube la imagen a Firebase Storage y obtiene la URL
  Future<String?> _uploadImage(File image) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('product_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error al subir la imagen: $e");
      return null;
    }
  }

  // Actualiza los datos del producto en Firestore
  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await _uploadImage(_imageFile!);
    }

    // Recoger los valores actualizados de los campos dinámicos
    Map<String, dynamic> updatedFields = {};
    _dynamicFieldControllers.forEach((key, controller) {
      updatedFields[key] = controller.text;
    });

    try {
      await FirebaseFirestore.instance
          .collection('productos')
          .doc(widget.productId)
          .update({
        'nombre': _nombreController.text,
        'descripcion': _descripcionController.text,
        'precio': double.tryParse(_precioController.text) ?? 0,
        'imageUrl': imageUrl ?? widget.productData['imageUrl'],
        'additionalFields': updatedFields, // ✅ Actualiza los campos dinámicos
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Producto actualizado con éxito')));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error al actualizar producto: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar producto: $e')));
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildImagePicker(),
              const SizedBox(height: 10),
              _buildTextField(
                  controller: _nombreController, label: 'Nombre del Producto'),
              const SizedBox(height: 10),
              _buildTextField(
                  controller: _descripcionController,
                  label: 'Descripción',
                  maxLines: 3),
              const SizedBox(height: 10),
              _buildTextField(
                  controller: _precioController,
                  label: 'Precio',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _buildDynamicFields(), // ✅ Campos adicionales dinámicos
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 AppBar
  AppBar _buildAppBar() {
    return AppBar(
      title:
          const Text('Editar Producto', style: TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF643CB9),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  // 🔹 Widget para seleccionar imagen
  Widget _buildImagePicker() {
    return GestureDetector(
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
            : widget.productData['imageUrl'] != null
                ? Image.network(widget.productData['imageUrl'],
                    fit: BoxFit.cover)
                : const Center(child: Text('Seleccionar Imagen')),
      ),
    );
  }

  // 🔹 Campos de texto reutilizables
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
    );
  }

  // 🔹 Genera los campos adicionales dinámicamente
  Widget _buildDynamicFields() {
    if (_dynamicFieldControllers.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _dynamicFieldControllers.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextFormField(
            controller: entry.value,
            decoration: InputDecoration(
              labelText: entry.key,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 🔹 Botón para guardar cambios
  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitProduct,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF643CB9)),
      child: const Text('Guardar Cambios',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}
