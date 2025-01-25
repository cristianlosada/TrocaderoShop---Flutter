// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'forgot_password.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();

//   Future<void> _login() async {
//     if (_formKey.currentState?.validate() ?? false) {
//       try {
//         // Inicia sesión con correo y contraseña
//         await FirebaseAuth.instance.signInWithEmailAndPassword(
//           email: _emailController.text,
//           password: _passwordController.text,
//         );
//       } on FirebaseAuthException catch (e) {
//         String errorMessage;
//         // print(e.code);
//         switch (e.code) {
//           case 'user-not-found':
//             errorMessage = 'No se encontró un usuario con ese correo.';
//             break;
//           case 'invalid-credential':
//             errorMessage =
//                 'La contraseña es incorrecta. Por favor, inténtalo de nuevo.';
//             break;
//           case 'user-disabled':
//             errorMessage = 'Esta cuenta ha sido deshabilitada.';
//             break;
//           case 'too-many-requests':
//             errorMessage = 'Demasiados intentos. Por favor, intente más tarde.';
//             break;
//           case 'invalid-email':
//             errorMessage = 'El formato del correo electrónico no es válido.';
//             break;
//           default:
//             errorMessage = 'Error al iniciar sesión: ${e.message}';
//         }
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(errorMessage)),
//           );
//         }
//       } catch (e) {
//         if (mounted) {
//           // Manejo de otros errores
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Error al iniciar sesión 2: ${e.toString()}')),
//           );
//         }
//       }
//     }
//   }

//   Future<void> _register() async {
//     try {
//       Navigator.pushReplacementNamed(
//         context,
//         '/register',
//       );
//     } catch (e) {
//       if (mounted) {
//         // Verifica si el widget sigue montado
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error al iniciar sesión: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Color(0xFF643CB9), // Color que coincide con el fondo de la imagen
//               Color(0xFF7B1EA2), // Color hacia el cual se hace el gradiente
//             ],
//             begin: Alignment(0.0, -0.5), // Empieza un poco arriba del centro
//             end: Alignment.bottomCenter, // Termina en la parte inferior
//           ),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 30.0),
//           child: Center(
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Image.asset(
//                     'images/assets/LogoTrocadero.png',
//                     width: 200,
//                     height: 200,
//                   ),
//                   const SizedBox(height: 20),
//                   Card(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                     elevation: 8,
//                     color: Colors.white.withOpacity(0.9),
//                     child: Padding(
//                       padding: const EdgeInsets.all(20.0),
//                       child: Form(
//                         key: _formKey,
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             const Text(
//                               'Iniciar Sesión',
//                               style: TextStyle(
//                                   fontSize: 24, fontWeight: FontWeight.bold),
//                             ),
//                             const SizedBox(height: 20),
//                             TextFormField(
//                               controller: _emailController,
//                               decoration: InputDecoration(
//                                 labelText: 'Correo Electrónico',
//                                 labelStyle:
//                                     const TextStyle(color: Color(0xFF643CB0)),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                               ),
//                               keyboardType: TextInputType.emailAddress,
//                               validator: (value) {
//                                 if (value == null ||
//                                     value.isEmpty ||
//                                     !value.contains('@')) {
//                                   return 'Ingrese un correo electrónico válido';
//                                 }
//                                 return null;
//                               },
//                             ),
//                             const SizedBox(height: 15),
//                             TextFormField(
//                               controller: _passwordController,
//                               decoration: InputDecoration(
//                                 labelText: 'Contraseña',
//                                 labelStyle:
//                                     const TextStyle(color: Color(0xFF643CB0)),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                               ),
//                               obscureText: true,
//                               validator: (value) {
//                                 if (value == null || value.length < 8) {
//                                   return 'La contraseña debe tener al menos 8 caracteres';
//                                 }
//                                 return null;
//                               },
//                             ),
//                             const SizedBox(height: 20),
//                             ElevatedButton(
//                               onPressed: _login,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: const Color(0xFF643CB0),
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 40, vertical: 15),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(30),
//                                 ),
//                               ),
//                               child: const Text(
//                                 'Iniciar sesion',
//                                 style: TextStyle(
//                                     fontSize: 18, color: Colors.white),
//                               ),
//                             ),
//                             const SizedBox(height: 10),
//                             TextButton(
//                               onPressed: () {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (context) => const ForgotPasswordScreen(),
//                                   ),
//                                 );
//                               },
//                               child: const Text(
//                                 'Olvidaste tu contraseña?',
//                                 style: TextStyle(
//                                     color: Color.fromARGB(179, 90, 90, 90)),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   TextButton(
//                     onPressed: _register,
//                     child: const Text(
//                       "No tienes cuenta? Registrate",
//                       style:
//                           TextStyle(color: Color.fromARGB(179, 255, 255, 255)),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
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
        // Inicia sesión con correo y contraseña
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No se encontró un usuario con ese correo.';
            break;
          case 'invalid-credential':
            errorMessage =
                'La contraseña es incorrecta. Por favor, inténtalo de nuevo.';
            break;
          case 'user-disabled':
            errorMessage = 'Esta cuenta ha sido deshabilitada.';
            break;
          case 'too-many-requests':
            errorMessage = 'Demasiados intentos. Por favor, intente más tarde.';
            break;
          case 'invalid-email':
            errorMessage = 'El formato del correo electrónico no es válido.';
            break;
          default:
            errorMessage = 'Error al iniciar sesión: ${e.message}';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al iniciar sesión: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _register() async {
    try {
      Navigator.pushReplacementNamed(
        context,
        '/register',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loginWithBiometrics() async {
    try {
      // Verifica si el dispositivo admite biometría
      final bool canAuthenticate = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tu dispositivo no admite biometría.')),
        );
        return;
      }

      // Autenticación biométrica
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Inicia sesión con tu biometría',
        options: const AuthenticationOptions(
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        // Aquí puedes manejar la lógica después de la autenticación biométrica.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autenticación biométrica exitosa.')),
        );

        // Redirige al usuario al home o realiza cualquier acción
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error con la biometría: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF643CB9),
              Color(0xFF7B1EA2),
            ],
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
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
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
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Correo Electrónico',
                                labelStyle:
                                    const TextStyle(color: Color(0xFF643CB0)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    !value.contains('@')) {
                                  return 'Ingrese un correo electrónico válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                labelStyle:
                                    const TextStyle(color: Color(0xFF643CB0)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.length < 8) {
                                  return 'La contraseña debe tener al menos 8 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF643CB0),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'Iniciar sesión',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: _loginWithBiometrics,
                              icon: const Icon(Icons.fingerprint),
                              label: const Text('Iniciar sesión con biometría'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(
                                    color: Color.fromARGB(179, 90, 90, 90)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _register,
                    child: const Text(
                      "¿No tienes cuenta? Regístrate",
                      style: TextStyle(
                          color: Color.fromARGB(179, 255, 255, 255)),
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
}
