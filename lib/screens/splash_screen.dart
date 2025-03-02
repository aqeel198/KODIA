import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/user_provider.dart';
import '../services/mysql_data_service.dart';
import '../models/user.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _attemptAutoLogin();
  }

  Future<void> _attemptAutoLogin() async {
    String? storedUsername = await secureStorage.read(key: 'username');
    String? storedPassword = await secureStorage.read(key: 'password');
    String? storedSchoolCode = await secureStorage.read(key: 'schoolCode');

    if (storedPassword != null) {
      try {
        User? user = await MySQLDataService.instance.loginUser(
          storedUsername!,
          storedPassword,
          storedSchoolCode!,
        );
        if (user != null && mounted) {
          Provider.of<UserProvider>(context, listen: false).setUser(user);
          Navigator.pushReplacementNamed(context, '/home');
          return;
        }
      } catch (e) {
        print("Auto login error: $e");
      }
    }
    // في حال عدم نجاح تسجيل الدخول التلقائي
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
