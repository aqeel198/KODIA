import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/user_provider.dart';
import '../services/mysql_data_service.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _schoolCodeController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;
  Animation<double>? _opacityAnimation;

  // استخدام flutter_secure_storage لتخزين البيانات الحساسة
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // محاولة تسجيل الدخول التلقائي
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeIn),
    );

    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _schoolCodeController.dispose();
    super.dispose();
  }

  /// التحقق من بيانات التسجيل المخزنة
  Future<void> _checkLoginStatus() async {
    String? storedUsername = await secureStorage.read(key: 'username');
    String? storedPassword = await secureStorage.read(key: 'password');
    String? storedSchoolCode = await secureStorage.read(key: 'schoolCode');

    if (storedUsername != null &&
        storedPassword != null &&
        storedSchoolCode != null) {
      try {
        setState(() => _loading = true);

        // تسجيل الدخول ببيانات التخزين الآمن
        User? user = await MySQLDataService.instance.loginUser(
          storedUsername,
          storedPassword,
          storedSchoolCode,
        );
        if (user != null && mounted) {
          // جلب بيانات المدرسة
          final schoolDetails = await ApiService.fetchSchoolDetails(
            storedSchoolCode.trim(),
          );

          user = user.copyWith(
            schoolName: schoolDetails['name'] ?? '',
            logoUrl: schoolDetails['logo_url'] ?? '',
          );

          Provider.of<UserProvider>(context, listen: false).setUser(user);

          // الانتقال للصفحة الرئيسية
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          setState(() => _loading = false);
        }
      } catch (e) {
        setState(() => _loading = false);
        print("Auto login error: $e");
      }
    }
  }

  /// تسجيل الدخول اليدوي
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);

      try {
        // تسجيل الدخول من قاعدة البيانات
        User? user = await MySQLDataService.instance.loginUser(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
          _schoolCodeController.text.trim(),
        );

        if (user != null) {
          // حفظ بيانات الدخول
          await secureStorage.write(
            key: 'username',
            value: _usernameController.text.trim(),
          );
          await secureStorage.write(
            key: 'password',
            value: _passwordController.text.trim(),
          );
          await secureStorage.write(
            key: 'schoolCode',
            value: _schoolCodeController.text.trim(),
          );

          // جلب بيانات المدرسة
          final schoolDetails = await ApiService.fetchSchoolDetails(
            _schoolCodeController.text.trim(),
          );

          // إضافة اسم المدرسة وشعارها إلى user
          user = user.copyWith(
            schoolName: schoolDetails['name'] ?? '',
            logoUrl: schoolDetails['logo_url'] ?? '',
          );

          // وضع user في الـ Provider
          Provider.of<UserProvider>(context, listen: false).setUser(user);

          // إظهار إشعار نجاح
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'تم تسجيل الدخول بنجاح',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(10),
              duration: const Duration(seconds: 1),
            ),
          );

          // عرض حوار ترحيبي (سيغلق تلقائيًا بعد 2 ثانية)
          await _showWelcomeDialog(user);

          // بعد إغلاق الحوار، نذهب للشاشة الرئيسية
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          _showErrorSnackBar('بيانات غير صحيحة أو رمز مدرسة غير صحيح');
        }
      } catch (e) {
        if (e.toString().contains("اشتراك المنصة منتهي")) {
          _showErrorSnackBar('اشتراك المنصة منتهي. يجب تجديد الاشتراك.');
        } else {
          _showErrorSnackBar('حدث خطأ: $e');
        }
      } finally {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    }
  }

  /// حوار ترحيب يُغلق تلقائيًا بعد 2 ثوان
  Future<void> _showWelcomeDialog(User user) async {
    final schoolLogo = user.logoUrl ?? "";
    final schoolName = user.schoolName ?? "";
    final userName = user.username;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // إغلاقه تلقائيًا بعد 2 ثانية
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && Navigator.canPop(ctx)) {
            Navigator.pop(ctx); // إغلاق الـ Dialog
          }
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (schoolLogo.isNotEmpty)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(schoolLogo),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                const Icon(Icons.school, size: 80, color: Colors.blueGrey),
              const SizedBox(height: 16),
              Text(
                'مرحباً $userName',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              if (schoolName.isNotEmpty)
                Text(
                  'أهلاً بك في $schoolName',
                  style: GoogleFonts.cairo(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: FadeTransition(
                  opacity: _opacityAnimation!,
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      // شعار أو أيقونة التطبيق
                      Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              size: 70,
                              color: Color(0xFF2E3192),
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .scale(delay: 200.ms, duration: 500.ms),
                      const SizedBox(height: 30),

                      // نص الترحيب
                      Text(
                            'مرحباً بك',
                            style: GoogleFonts.cairo(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 300.ms)
                          .moveY(
                            begin: 20,
                            end: 0,
                            delay: 300.ms,
                            duration: 600.ms,
                          ),
                      Text(
                        'قم بتسجيل الدخول للوصول إلى حسابك',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
                      const SizedBox(height: 40),

                      // بطاقة تسجيل الدخول
                      Container(
                            width:
                                isTablet ? size.width * 0.7 : double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // حقل اسم المستخدم
                                    _buildInputLabel('اسم المستخدم'),
                                    const SizedBox(height: 8),
                                    _buildTextField(
                                      controller: _usernameController,
                                      hintText: 'أدخل اسم المستخدم',
                                      prefixIcon: Icons.person,
                                      validator:
                                          (val) =>
                                              (val == null || val.isEmpty)
                                                  ? 'أدخل اسم المستخدم'
                                                  : null,
                                    ),
                                    const SizedBox(height: 24),

                                    // حقل كلمة المرور
                                    _buildInputLabel('كلمة المرور'),
                                    const SizedBox(height: 8),
                                    _buildTextField(
                                      controller: _passwordController,
                                      hintText: 'أدخل كلمة المرور',
                                      prefixIcon: Icons.lock,
                                      obscureText: _obscurePassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                      validator:
                                          (val) =>
                                              (val == null || val.isEmpty)
                                                  ? 'أدخل كلمة المرور'
                                                  : null,
                                    ),
                                    const SizedBox(height: 24),

                                    // حقل رمز المدرسة
                                    _buildInputLabel('رمز المدرسة'),
                                    const SizedBox(height: 8),
                                    _buildTextField(
                                      controller: _schoolCodeController,
                                      hintText: 'أدخل رمز المدرسة',
                                      prefixIcon: Icons.school,
                                      validator:
                                          (val) =>
                                              (val == null || val.isEmpty)
                                                  ? 'أدخل رمز المدرسة'
                                                  : null,
                                    ),
                                    const SizedBox(height: 30),

                                    // زر تسجيل الدخول
                                    Center(
                                      child: ScaleTransition(
                                        scale: _scaleAnimation!,
                                        child: Container(
                                              width: double.infinity,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF2E3192),
                                                    Color(0xFF1BFFFF),
                                                  ],
                                                  begin: Alignment.centerRight,
                                                  end: Alignment.centerLeft,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFF2E3192,
                                                    ).withOpacity(0.3),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                ],
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap:
                                                      _loading ? null : _login,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  splashColor: Colors.white
                                                      .withOpacity(0.2),
                                                  highlightColor:
                                                      Colors.transparent,
                                                  child: Center(
                                                    child:
                                                        _loading
                                                            ? const SizedBox(
                                                              height: 24,
                                                              width: 24,
                                                              child: CircularProgressIndicator(
                                                                valueColor:
                                                                    AlwaysStoppedAnimation<
                                                                      Color
                                                                    >(
                                                                      Colors
                                                                          .white,
                                                                    ),
                                                                strokeWidth: 2,
                                                              ),
                                                            )
                                                            : Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Text(
                                                                  'تسجيل الدخول',
                                                                  style: GoogleFonts.cairo(
                                                                    fontSize:
                                                                        18,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color:
                                                                        Colors
                                                                            .white,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                const Icon(
                                                                  Icons
                                                                      .arrow_forward,
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                              ],
                                                            ),
                                                  ),
                                                ),
                                              ),
                                            )
                                            .animate(
                                              onPlay:
                                                  (controller) => controller
                                                      .repeat(reverse: true),
                                            )
                                            .shimmer(
                                              duration: 3.seconds,
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 800.ms, delay: 500.ms)
                          .moveY(
                            begin: 30,
                            end: 0,
                            delay: 500.ms,
                            curve: Curves.easeOutQuad,
                          ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          style: GoogleFonts.cairo(fontSize: 16, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            prefixIcon: Icon(prefixIcon, color: const Color(0xFF2E3192)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E3192), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .moveX(begin: -10, end: 0, duration: 400.ms);
  }
}
