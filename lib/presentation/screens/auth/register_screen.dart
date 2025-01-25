import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../common/location_picker_screen.dart'; // Importa la pantalla de selección de ubicación

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  LatLng? _selectedLocation;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedAddress = '';
  String _userType = 'persona';
  bool _isCompany = false;

  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userCredential.user?.uid)
            .set({
          'nombre_completo': _nameController.text,
          'correo': _emailController.text,
          'tipo_usuario': _userType,
          'ubicacion': _selectedLocation != null
              ? {
                  'latitude': _selectedLocation!.latitude,
                  'longitude': _selectedLocation!.longitude,
                }
              : null,
          if (_isCompany) 'nombre_empresa': _companyNameController.text,
          if (_isCompany) 'telefono_empresa': _phoneController.text,
          if (_isCompany) 'direccion': _selectedAddress,
        });

        if (mounted) {
          Navigator.pushReplacementNamed(
              context, _isCompany ? '/empresa_home' : '/persona_home');
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Este correo ya está registrado. Por favor, use otro.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al registrar: ${e.message}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar: ${e.toString()}')),
        );
      }
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

  Future<void> _login() async {
    try {
      Navigator.pushReplacementNamed(
        context,
        '/login',
      );
    } catch (e) {
      if (mounted) {
        // Verifica si el widget sigue montado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar sesión: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF643CB9), // Color que coincide con el fondo de la imagen
              Color(0xFF7B1EA2), // Color hacia el cual se hace el gradiente
            ],
            begin: Alignment(0.0, -0.5), // Empieza un poco arriba del centro
            end: Alignment.bottomCenter, // Termina en la parte inferior
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Registro de Usuario',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre Completo',
                          labelStyle: TextStyle(color: Color(0xFF643CB0)),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 3) {
                            return 'Nombre debe tener al menos 3 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Correo Electrónico',
                          labelStyle: TextStyle(color: Color(0xFF643CB0)),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || !value.contains('@')) {
                            return 'Ingrese un correo electrónico válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          labelStyle: TextStyle(color: Color(0xFF643CB0)),
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.length < 8) {
                            return 'La contraseña debe tener al menos 8 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _userType,
                        items: const [
                          DropdownMenuItem(
                              value: 'persona', child: Text('Persona')),
                          DropdownMenuItem(
                              value: 'empresa', child: Text('Empresa')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _userType = value!;
                            _isCompany = value == 'empresa';
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Usuario',
                          labelStyle: TextStyle(color: Color(0xFF643CB0)),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null) {
                            return 'Seleccione el tipo de usuario';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      if (_isCompany) ...[
                        TextFormField(
                          controller: _companyNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de la Empresa',
                            labelStyle: TextStyle(color: Color(0xFF643CB0)),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 3) {
                              return 'El nombre de la empresa debe tener al menos 3 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono de la Empresa',
                            labelStyle: TextStyle(color: Color(0xFF643CB0)),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 8) {
                              return 'El teléfono debe tener al menos 8 dígitos';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Dirección Física',
                            labelStyle: TextStyle(color: Color(0xFF643CB0)),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'La dirección es obligatoria';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _selectLocation,
                          child: const Text('Seleccionar Ubicación en el Mapa'),
                        ),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF643CB9),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Registrarse',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: _login,
                        child: const Text(
                          "Ya tienes cuenta? Inicia sesion",
                          style:
                              TextStyle(color: Color.fromARGB(179, 90, 90, 90)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
