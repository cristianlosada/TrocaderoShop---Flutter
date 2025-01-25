import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../common/location_picker_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  LatLng? _selectedLocation;
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nombreCompletoController =
      TextEditingController();
  final TextEditingController _nombreEmpresaController =
      TextEditingController();
  final TextEditingController _telefonoEmpresaController =
      TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();
  String typeUser = 'empresa';
  String _selectedAddress = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Obtiene los datos del usuario
  Future<void> _fetchUserData() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .get();

    if (userDoc.exists) {
      var data = userDoc.data() as Map<String, dynamic>;

      setState(() {
        typeUser = data['tipo_usuario'] ?? '';
        _correoController.text = data['correo'] ?? '';
        _addressController.text = data['direccion'] ?? '';
        _nombreCompletoController.text = data['nombre_completo'] ?? '';
        _nombreEmpresaController.text = data['nombre_empresa'] ?? '';
        _telefonoEmpresaController.text = data['telefono_empresa'] ?? '';
        _ubicacionController.text = data['ubicacion'] ?? '';
      });
    }
  }

  // Actualiza los datos del usuario
  Future<void> _updateUserProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      // obtiene el usuario id del usuario que esta autenticado
      String userId = FirebaseAuth.instance.currentUser!.uid;

      try {
        if (typeUser == 'empresa') {
          //valida el tipo de usuario "empresa"
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userId)
              .update({
            'nombre_completo': _nombreCompletoController.text,
            'nombre_empresa': _nombreEmpresaController.text,
            'telefono_empresa': _telefonoEmpresaController.text,
            'ubicacion': _selectedLocation != null
                ? {
                    'latitude': _selectedLocation!.latitude,
                    'longitude': _selectedLocation!.longitude,
                  }
                : null,
            'direccion': _selectedAddress,
          });
        } else if (typeUser == 'persona') {
          // valida el usuario de tipo "persona"
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userId)
              .update({
            'nombre_completo': _nombreCompletoController.text,
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado con éxito')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Error al actualizar el perfil: ${e.toString()}')),
          );
        }
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LocationPickerScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result['location'];
        _selectedAddress = result['address'];
      });
      _addressController.text = _selectedAddress;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          typeUser == 'persona' ? 'Perfil de Persona' : 'Perfil de Empresa',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // Color blanco para el ícono de retroceso
        ),
        backgroundColor: const Color(0xFF643CB0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Correo
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Requerido' : null,
                enabled: false, // Esto hace que el campo sea solo lectura
              ),
              const SizedBox(height: 10),
              // Nombre completo
              TextFormField(
                controller: _nombreCompletoController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Requerido' : null,
              ),
              if (typeUser == 'empresa')
                const SizedBox(height: 10),
              if (typeUser == 'empresa')
                // Nombre de la empresa
                TextFormField(
                  controller: _nombreEmpresaController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la Empresa',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Requerido' : null,
                ),
              if (typeUser == 'empresa')
                const SizedBox(height: 10),
                // Teléfono de la empresa
              if (typeUser == 'empresa')
                TextFormField(
                  controller: _telefonoEmpresaController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono de la Empresa',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Requerido' : null,
                ),
              if (typeUser == 'empresa')
                const SizedBox(height: 10),
                // Dirección
              if (typeUser == 'empresa')
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Requerido' : null,
                ),
              if (typeUser == 'empresa')
                const SizedBox(height: 10),
                // TextFormField(
                //   controller: _addressController,
                //   decoration: const InputDecoration(
                //     labelText: 'Dirección Física',
                //     labelStyle: TextStyle(color: Color(0xFF643CB0)),
                //     border: OutlineInputBorder(),
                //   ),
                //   validator: (value) {
                //     if (value == null || value.isEmpty) {
                //       return 'La dirección es obligatoria';
                //     }
                //     return null;
                //   },
                // ),
                // const SizedBox(height: 10),
              if (typeUser == 'empresa')
                ElevatedButton(
                  onPressed: _selectLocation,
                  child: const Text('Seleccionar Ubicación en el Mapa'),
                ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _updateUserProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF643CB4),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Actualizar Perfil',
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
