import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  AddProductScreenState createState() => AddProductScreenState();
}

class AddProductScreenState extends State<ProductsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String? _selectedCategoryId;
  File? _imageFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // Mapa de controladores dinámicos para los campos según la categoría
  final Map<String, TextEditingController> _dynamicFields = {};
  Map<String, dynamic> _categoryFields = {};

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _dynamicFields.forEach((_, controller) => controller.dispose());
    super.dispose();
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
      _showSnackbar('Error al subir la imagen: ${e.toString()}');
      return null;
    }
  }

  // Envia los datos del producto a Firestore
  Future<void> _submitProduct() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
      }

      Map<String, dynamic> additionalFields = {};
      _dynamicFields.forEach((key, controller) {
        additionalFields[key] = controller.text;
      });

      await FirebaseFirestore.instance.collection('productos').add({
        'nombre': _nameController.text,
        'descripcion': _descriptionController.text,
        'precio': double.parse(_priceController.text),
        'categoriaId': _selectedCategoryId,
        'imageUrl': imageUrl,
        'empresaId': FirebaseAuth.instance.currentUser?.uid,
        'fechaCreacion': Timestamp.now(),
        'additionalFields': additionalFields, // Campos dinámicos
      });

      _showSnackbar('Producto agregado con éxito');
      Navigator.pop(context);

      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // Obtiene las categorías de Firestore
  Future<List<Map<String, dynamic>>> _fetchCategories() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('categorias').get();

      if (snapshot.docs.isEmpty) {
        print("⚠ No hay categorías disponibles.");
        return [];
      }

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'nombre': data['nombre'] ?? 'Sin Nombre',
          'fields': data.containsKey('fields') &&
                  data['fields'] is Map<String, dynamic>
              ? data['fields'] as Map<String, dynamic>
              : {},
        };
      }).toList();
    } catch (e) {
      print("❌ Error al obtener categorías: $e");
      return [];
    }
  }

  // Cambia los campos dinámicos según la categoría seleccionada
  void _onCategoryChanged(String? categoryId, Map<String, dynamic> fields) {
    setState(() {
      _selectedCategoryId = categoryId;
      _categoryFields = fields;

      // ✅ Limpiar controladores anteriores antes de agregar nuevos
      _dynamicFields.forEach((_, controller) => controller.dispose());
      _dynamicFields.clear();

      // ✅ Inicializar controladores para los nuevos campos
      fields.forEach((key, _) {
        _dynamicFields[key] = TextEditingController();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF643CB9),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Agregar Producto',
            style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildImagePicker(),
              const SizedBox(height: 20),
              _buildCategoryDropdown(),
              const SizedBox(height: 10),
              _buildTextField(controller: _nameController, label: 'Nombre'),
              const SizedBox(height: 10),
              _buildTextField(
                  controller: _descriptionController,
                  label: 'Descripción',
                  maxLines: 3),
              const SizedBox(height: 10),
              _buildTextField(
                  controller: _priceController,
                  label: 'Precio',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _buildDynamicFields(),
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

  // Widget para seleccionar una imagen
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
            : const Center(child: Text('Seleccionar Imagen')),
      ),
    );
  }

  // Widget para los campos de texto reutilizables
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

  // Widget para el dropdown de categorías
  Widget _buildCategoryDropdown() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("⚠ Error al cargar categorías"));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("⚠ No hay categorías disponibles"));
        }

        final categories = snapshot.data!;

        return DropdownButtonFormField<String>(
          value: _selectedCategoryId,
          items: categories.map((category) {
            return DropdownMenuItem(
              value: category['id'] as String,
              child: Text(category['nombre']),
            );
          }).toList(),
          onChanged: (value) {
            final selectedCategory =
                categories.firstWhere((c) => c['id'] == value);
            _onCategoryChanged(value, selectedCategory['fields']);
          },
          decoration: InputDecoration(
            labelText: 'Categoría',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          validator: (value) =>
              value == null ? 'Seleccione una categoría' : null,
        );
      },
    );
  }

  // Genera los campos dinámicos según la categoría seleccionada
  Widget _buildDynamicFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _categoryFields.keys.map((key) {
        return Padding(
          padding:
              const EdgeInsets.only(bottom: 10), // ✅ Espaciado entre los campos
          child: _buildTextField(controller: _dynamicFields[key]!, label: key),
        );
      }).toList(),
    );
  }

  // Botón de enviar
  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitProduct,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF643CB4),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Text(
        'Agregar Producto',
        style:
            TextStyle(fontSize: 16, color: Colors.white), // ✅ Corrección aquí
      ),
    );
  }
}
