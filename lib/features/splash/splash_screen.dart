import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../core/session/session_manager.dart';
import '../../core/network/dio_client.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Future<void> _bootstrap(BuildContext context) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');
    if (!context.mounted) return;
    if (token != null && token.isNotEmpty) {
      // Ensure client and session are initialized when app is cold-started
      await DioClient().setToken(token);
      SessionManager.instance.setAuthenticated(true);
      context.go('/home');
    } else {
      SessionManager.instance.setAuthenticated(false);
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap(context));
    return Scaffold(body: const Center(child: CircularProgressIndicator()));
  }
}
