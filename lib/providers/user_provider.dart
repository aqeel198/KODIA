import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  User? get user => _user;

  /// تحميل بيانات المستخدم من SharedPreferences
  Future<void> loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('role');
    String? username = prefs.getString('username');
    String? password = prefs.getString('password');
    String? grade = prefs.getString('grade');
    String? subject = prefs.getString('subject'); // التخصص
    int? schoolId = prefs.getInt('schoolId');
    String? schoolCode = prefs.getString('schoolCode');
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
        grade: grade,
        subject: subject,
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
    String? grade,
    String? subject,
    required int schoolId,
    required String schoolCode,
    String? schoolName,
    String? logoUrl,
  }) async {
    _user = User(
      role: role,
      username: username,
      password: password,
      grade: grade,
      subject: subject,
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
    if (grade != null) await prefs.setString('grade', grade);
    if (subject != null) await prefs.setString('subject', subject);
    await prefs.setInt('schoolId', schoolId);
    await prefs.setString('schoolCode', schoolCode);
    if (schoolName != null) prefs.setString('schoolName', schoolName);
    if (logoUrl != null) prefs.setString('logoUrl', logoUrl);
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    _user = null;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('role');
    await prefs.remove('username');
    await prefs.remove('password');
    await prefs.remove('grade');
    await prefs.remove('subject');
    await prefs.remove('schoolId');
    await prefs.remove('schoolCode');
    await prefs.remove('schoolName');
    await prefs.remove('logoUrl');
  }

  void setUser(User? newUser) {
    _user = newUser;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
