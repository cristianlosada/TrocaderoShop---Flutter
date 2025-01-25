import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_app_check/firebase_app_check.dart';
// import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:trocadero_shop/core/constants/app_routes.dart';
import 'package:trocadero_shop/presentation/screens/auth/login_screen.dart';
import 'package:trocadero_shop/presentation/screens/auth/register_screen.dart';
import 'package:trocadero_shop/presentation/screens/navigation/personas.dart';
import 'package:trocadero_shop/presentation/screens/navigation/empresas.dart';

import 'package:provider/provider.dart';
import 'package:trocadero_shop/presentation/screens/navigation/cart/cart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // await FirebaseAppCheck.instance.activate(
  //   androidProvider: AndroidProvider.playIntegrity, // Usa SafetyNet si no tienes Play Integrity.
  // );
  // await FirebaseAppCheck.instance.activate(webRecaptchaSiteKey: 'test-site-key');
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

// Ruta para verificar el estado de autenticación
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
          // Aquí puedes obtener el tipo de usuario desde Firestore
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

                if (userType == 'persona') {
                  return const Personas();
                } else if (userType == 'empresa') {
                  return const Empresas();
                }
              }

              // Manejo de alguna actividad cuando no se puede iniciar sesion
              // ScaffoldMessenger.of(context).showSnackBar(
              //   SnackBar(
              //     content: Text('ha sucedido algo al iniciar sesion $userId')),
              // );

              // En caso de que el usuario no exista en Firestore o haya un error
              return const LoginScreen();
            },
          );
        }

        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('ha sucedido algo al iniciar sesion')),
        // );

        // Si no hay usuario autenticado
        return const LoginScreen();
      },
    );
  }
}
