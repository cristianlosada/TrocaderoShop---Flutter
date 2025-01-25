import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:trocadero_shop/core/utils/funtions.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        Navigator.pushReplacementNamed(context, '/');
      } on FirebaseAuthException catch (e) {
        Functions().showErrorSnackBar(context, message :_getFirebaseAuthErrorMessage(e.code));
      } catch (e) {
        Functions().showErrorSnackBar(context, message :
            'Error desconocido al iniciar sesión: ${e.toString()}');
      }
    }
  }

  Future<void> _loginWithBiometrics() async {
    try {
      final bool canAuthenticate = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        Functions().showErrorSnackBar(context, message :'Tu dispositivo no admite biometría.');
        return;
      }

      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Inicia sesión con tu biometría',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (authenticated) {
        Functions().showSuccessSnackBar(context, message :'Autenticación biométrica exitosa.');
        // obtener tipo de usuario de logueado
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      print(e.toString());
      Functions().showErrorSnackBar(context, message :'Error con la biometría: ${e.toString()}');
    }
  }

  String _getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No se encontró un usuario con ese correo.';
      case 'wrong-password':
        return 'La contraseña es incorrecta.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Por favor, intente más tarde.';
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      default:
        return 'Error al iniciar sesión.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF643CB9), Color(0xFF7B1EA2)],
            begin: Alignment(0.0, -0.5),
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'images/assets/LogoTrocadero.png',
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 20),
                  _buildLoginCard(),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text(
                      "¿No tienes cuenta? Regístrate",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 8,
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Iniciar Sesión',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _emailController,
                labelText: 'Correo Electrónico',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Ingrese un correo electrónico válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _passwordController,
                labelText: 'Contraseña',
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return 'La contraseña debe tener al menos 8 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildLoginButton(),
              // const SizedBox(height: 10),
              // _buildBiometricButton(),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen()),
                  );
                },
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(color: Color.fromARGB(179, 90, 90, 90)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Color(0xFF643CB0)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _login,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF643CB0),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: const Text(
        'Iniciar sesión',
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }

  // Widget _buildBiometricButton() {
  //   return ElevatedButton.icon(
  //     onPressed: _loginWithBiometrics,
  //     icon: const Icon(Icons.fingerprint),
  //     label: const Text('Iniciar sesión con biometría'),
  //     style: ElevatedButton.styleFrom(
  //       backgroundColor: Colors.green,
  //       padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(30),
  //       ),
  //     ),
  //   );
  // }
}
