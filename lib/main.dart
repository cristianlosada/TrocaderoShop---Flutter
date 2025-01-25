import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trocadero_shop/core/constants/app_routes.dart';
import 'package:trocadero_shop/core/utils/funtions.dart';
import 'package:trocadero_shop/presentation/screens/auth/login_screen.dart';
import 'package:trocadero_shop/presentation/screens/auth/register_screen.dart';
import 'package:trocadero_shop/presentation/screens/auth/verify_email_screen.dart';
import 'package:trocadero_shop/presentation/screens/navigation/personas.dart';
import 'package:trocadero_shop/presentation/screens/navigation/empresas.dart';
import 'package:provider/provider.dart';
import 'package:trocadero_shop/presentation/screens/navigation/cart/cart_provider.dart';
import 'package:trocadero_shop/core/utils/biometric_auth.dart'; // Clase para la autenticación biométrica

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => CartProvider()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: MaterialApp(
        debugShowCheckedModeBanner:
            true, // Esta línea oculta la etiqueta de Debug
        title: 'TrocaderoShop',
        theme: ThemeData(
          primarySwatch: Colors.purple,
        ),
        initialRoute:
            AppRoutes.authWrapper, // Usa una ruta inicial en lugar de home
        routes: {
          AppRoutes.authWrapper: (context) => const AuthWrapper(),
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.personas: (context) => const Personas(),
          AppRoutes.empresas: (context) => const Empresas(),
          AppRoutes.register: (context) => const RegisterScreen(),
        },
      ),
    );
  }
}

// Modificación del AuthWrapper para incluir autenticación biométrica
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          final User user = snapshot.data!;
          // Verificar si el correo está validado
          if (!user.emailVerified) {
            // Redirigir a la pantalla de verificación de correo
            return VerifyEmailScreen(user: user);
          }
          // Usuario autenticado con Firebase
          final String userId = snapshot.data!.uid;
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('usuarios')
                .doc(userId)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (userSnapshot.hasData) {
                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final String userType = userData['tipo_usuario'] ?? 'persona';

                return FutureBuilder<List>(
                  future: BiometricAuth().authenticateWithBiometrics(),
                  builder: (context, biometricSnapshot) {
                    if (biometricSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    // Verificar si los datos están disponibles y si no hay error
                    if (biometricSnapshot.hasError) {
                      return Center(
                          child: Text('Error: ${biometricSnapshot.error}'));
                    }

                    if (biometricSnapshot.hasData) {
                      // Verifica que los datos sean una lista válida
                      List<dynamic> result = biometricSnapshot.data!;
                      bool isAuthenticated = result[0];
                      String message = result[1];
                      if (isAuthenticated == true) {
                        // Si la autenticación biométrica fue exitosa
                        if (userType == 'persona') {
                          return const Personas();
                        } else if (userType == 'empresa') {
                          return const Empresas();
                        }
                      }
                      Functions().showErrorSnackBar(context, message: message);
                    }

                    // Manejo de errores inesperados
                    return const LoginScreen();
                  },
                );
              }
              // En caso de error al obtener el usuario desde Firestore
              return const LoginScreen();
            },
          );
        }

        // Si no hay usuario autenticado en Firebase
        return const LoginScreen();
      },
    );
  }
}
