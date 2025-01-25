import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuth {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        debugPrint("Biometría no disponible en este dispositivo.");
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Usa tu huella para iniciar sesión',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      debugPrint("Error durante la autenticación biométrica: $e");
      return false;
    }
  }
}
