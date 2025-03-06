import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  User? get user => _user;

  /// تحميل بيانات المستخدم المحفوظة من SharedPreferences
  Future<void> loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('role');
    String? username = prefs.getString('username');
    String? password = prefs.getString('password'); // إن وُجد
    String? grade = prefs.getString('grade'); // إن وُجد
    int? schoolId = prefs.getInt('schoolId'); // قيمة schoolId المحفوظة
    String? schoolCode = prefs.getString(
      'schoolCode',
    ); // قيمة schoolCode المحفوظة

    // الحقول الجديدة
    String? schoolName = prefs.getString('schoolName');
    String? logoUrl = prefs.getString('logoUrl');

    if (role != null &&
        username != null &&
        schoolId != null &&
        schoolCode != null) {
      _user = User(
        role: role,
        username: username,
        password: password ?? '',
        grade: grade ?? '',
        schoolId: schoolId,
        schoolCode: schoolCode,
        schoolName: schoolName,
        logoUrl: logoUrl,
      );
      notifyListeners();
    }
  }

  /// تسجيل الدخول وحفظ بيانات المستخدم
  Future<void> login({
    required String username,
    required String role,
    required String password,
    required String grade,
    required int schoolId,
    required String schoolCode,
    String? schoolName, // معلمة schoolName الجديدة
    String? logoUrl, // معلمة logoUrl الجديدة
  }) async {
    _user = User(
      role: role,
      username: username,
      password: password,
      grade: grade,
      schoolId: schoolId,
      schoolCode: schoolCode,
      schoolName: schoolName,
      logoUrl: logoUrl,
    );
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
    await prefs.setString('username', username);
    await prefs.setString('password', password);
    await prefs.setString('grade', grade);
    await prefs.setInt('schoolId', schoolId);
    await prefs.setString('schoolCode', schoolCode);

    // حفظ الحقول الجديدة إن وُجدت
    if (schoolName != null) {
      await prefs.setString('schoolName', schoolName);
    }
    if (logoUrl != null) {
      await prefs.setString('logoUrl', logoUrl);
    }
  }

  /// تسجيل الخروج ومسح بيانات المستخدم
  Future<void> logout() async {
    _user = null;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('role');
    await prefs.remove('username');
    await prefs.remove('password');
    await prefs.remove('grade');
    await prefs.remove('schoolId');
    await prefs.remove('schoolCode');

    // إزالة الحقول الجديدة
    await prefs.remove('schoolName');
    await prefs.remove('logoUrl');
  }

  /// تعيين المستخدم مباشرةً (مثلاً من نتيجة تسجيل دخول خارجي)
  void setUser(User? newUser) {
    _user = newUser;
    notifyListeners();
  }

  /// مسح بيانات المستخدم
  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
