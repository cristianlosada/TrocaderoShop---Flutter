import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuth {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<List> authenticateWithBiometrics() async {
    try {
      // Verifica si el dispositivo tiene soporte para biometría
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        debugPrint("Biometría no disponible en este dispositivo.");
        return [false, "Biometría no disponible en este dispositivo."];
      }

      // Verifica si el dispositivo soporta la autenticación biométrica
      final bool canAuthenticate = await _localAuth.isDeviceSupported();
      if (!canAuthenticate) {
        debugPrint("Tu dispositivo no admite biometría.");
        return [true, "Tu dispositivo no admite biometría."];
      }

      // Intenta realizar la autenticación biométrica
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Usa tu huella para acceder a la aplicación',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      return [
        didAuthenticate,
        didAuthenticate ? "Autenticación exitosa" : "Autenticación fallida"
      ];
    } catch (e) {
      // Manejo de excepciones
      debugPrint("Error durante la autenticación biométrica: $e");
      return [false, "Error durante la autenticación biométrica. Detalles: $e"];
    }
  }
}
