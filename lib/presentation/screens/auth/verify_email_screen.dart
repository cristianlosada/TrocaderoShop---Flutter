import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trocadero_shop/core/constants/app_routes.dart';
import 'package:trocadero_shop/core/utils/funtions.dart';

class VerifyEmailScreen extends StatefulWidget {
  final User user;

  const VerifyEmailScreen({super.key, required this.user});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool isEmailVerified = false;
  bool isResending = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
  }

  Future<void> _checkEmailVerification() async {
    const int maxRetries = 3; // Máximo de intentos
    const Duration retryInterval =
        Duration(seconds: 2); // Intervalo entre intentos

    for (int i = 0; i < maxRetries; i++) {
      await widget.user.reload(); // Refresca el estado del usuario
      setState(() {
        isEmailVerified = widget.user.emailVerified;
      });
      print(widget.user);
      // print("Intento ${i + 1}: $isEmailVerified");

      if (isEmailVerified) {
        Navigator.pushReplacementNamed(context, AppRoutes.authWrapper);
        return; // Salir si está verificado
      }

      await Future.delayed(retryInterval); // Esperar antes de volver a intentar
    }

    // Mostrar mensaje si no se verifica tras varios intentos
    Functions().showErrorSnackBar(context,
        message:
            'No se pudo verificar el correo. Por favor intenta nuevamente.');
  }

  Future<void> _returnLogin() async {
    await widget.user.reload(); // Refresca el estado del usuario
    setState(() {
      isEmailVerified = widget.user.emailVerified;
    });

    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      isResending = true;
    });

    try {
      await widget.user.sendEmailVerification();
      Functions().showSuccessSnackBar(context,
          message: 'Correo de verificación enviado nuevamente.');
    } catch (e) {
      Functions().showErrorSnackBar(context,
          message: 'Error al enviar el correo: ${e.toString()}');
    } finally {
      setState(() {
        isResending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Correo',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF643CB0),
        iconTheme: const IconThemeData(
          color: Colors.white, // Color blanco para el ícono de retroceso
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              'images/assets/LogoTrocadero.png',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 32),
            const Text(
              'Por favor verifica tu correo electrónico antes de continuar. TrocaderoShop intenta validar automaticamente la verificacion por parte del usuario de forma temporal, si no obtienes respuesta intenta iniciar sesion nuevamente',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            _buildActionButton(
              context,
              label: 'Iniciar sesión con otra cuenta',
              onPressed: _returnLogin,
              isLoading: isResending,
              icon: Icons.login,
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              context,
              label: 'Reenviar correo de verificación',
              onPressed: isResending ? null : _resendVerificationEmail,
              isLoading: isResending,
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              context,
              label: 'Ya verifiqué mi correo',
              onPressed: _checkEmailVerification,
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required VoidCallback? onPressed,
    required IconData icon,
    bool isLoading = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF643CB0),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      icon: isLoading
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
