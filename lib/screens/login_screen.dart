import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/user_provider.dart';
import '../services/mysql_data_service.dart';
import '../models/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String username = '';
  String password = '';
  String schoolCode = ''; // رمز المدرسة
  bool _loading = false;
  AnimationController? _animationController;

  // استخدام flutter_secure_storage لتخزين البيانات الحساسة
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  // التحقق من بيانات تسجيل الدخول المخزنة بشكل آمن
  Future<void> _checkLoginStatus() async {
    String? storedUsername = await secureStorage.read(key: 'username');
    String? storedPassword = await secureStorage.read(key: 'password');
    String? storedSchoolCode = await secureStorage.read(key: 'schoolCode');

    if (storedUsername != null &&
        storedPassword != null &&
        storedSchoolCode != null) {
      try {
        User? user = await MySQLDataService.instance.loginUser(
          storedUsername,
          storedPassword,
          storedSchoolCode,
        );
        if (user != null && mounted) {
          Provider.of<UserProvider>(context, listen: false).setUser(user);
          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (e) {
        print("Auto login error: $e");
      }
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);
      try {
        User? user = await MySQLDataService.instance.loginUser(
          username,
          password,
          schoolCode,
        );
        if (user != null) {
          // حفظ بيانات تسجيل الدخول بشكل آمن
          await secureStorage.write(key: 'username', value: username);
          await secureStorage.write(key: 'password', value: password);
          await secureStorage.write(key: 'schoolCode', value: schoolCode);

          Provider.of<UserProvider>(context, listen: false).setUser(user);
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('بيانات غير صحيحة أو رمز مدرسة غير صحيح'),
            ),
          );
        }
      } catch (e) {
        if (e.toString().contains("اشتراك المنصة منتهي")) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('اشتراك المنصة منتهي. يجب تجديد الاشتراك.'),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
        }
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final animationController = _animationController;
    double screenWidth = MediaQuery.of(context).size.width * 0.9;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: Container(
                width: screenWidth,
                margin: const EdgeInsets.all(16.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3FA9F5), Color(0xFF2F62FF)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Card(
                    color: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'مرحباً بك',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Tooltip(
                                message: 'أدخل اسم المستخدم الخاص بك',
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'اسم المستخدم',
                                    labelStyle: const TextStyle(fontSize: 18),
                                    prefixIcon: const Icon(
                                      Icons.person,
                                      color: Colors.blue,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator:
                                      (val) =>
                                          (val == null || val.isEmpty)
                                              ? 'أدخل اسم المستخدم'
                                              : null,
                                  onChanged: (val) => username = val,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Tooltip(
                                message: 'أدخل كلمة المرور الخاصة بك',
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'كلمة المرور',
                                    labelStyle: const TextStyle(fontSize: 18),
                                    prefixIcon: const Icon(
                                      Icons.lock,
                                      color: Colors.blue,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  obscureText: true,
                                  validator:
                                      (val) =>
                                          (val == null || val.isEmpty)
                                              ? 'أدخل كلمة المرور'
                                              : null,
                                  onChanged: (val) => password = val,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Tooltip(
                                message: 'أدخل رمز المدرسة',
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'رمز المدرسة',
                                    labelStyle: const TextStyle(fontSize: 18),
                                    prefixIcon: const Icon(
                                      Icons.school,
                                      color: Colors.blue,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator:
                                      (val) =>
                                          (val == null || val.isEmpty)
                                              ? 'أدخل رمز المدرسة'
                                              : null,
                                  onChanged: (val) => schoolCode = val,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            MouseRegion(
                              onEnter: (_) => animationController?.forward(),
                              onExit: (_) => animationController?.reverse(),
                              child: AnimatedBuilder(
                                animation:
                                    animationController ??
                                    kAlwaysCompleteAnimation,
                                builder: (context, child) {
                                  double scale =
                                      1 +
                                      ((animationController?.value ?? 0) *
                                          0.05);
                                  return Transform.scale(
                                    scale: scale,
                                    child: child,
                                  );
                                },
                                child: ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 48,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                    elevation: 8,
                                  ),
                                  child:
                                      _loading
                                          ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const Text(
                                            'دخول',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
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
