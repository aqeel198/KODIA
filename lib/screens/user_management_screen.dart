import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import '../services/mysql_data_service.dart';
import 'user_list_screen.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String newGrade = 'الأول';
  String newRole = 'user';
  bool _loading = false;

  final List<String> educationLevels = [
    'الأول',
    'الثاني',
    'الثالث',
    'الرابع',
    'الخامس',
    'السادس',
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _addUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);

      final currentAdmin =
          Provider.of<UserProvider>(context, listen: false).user;
      if (currentAdmin == null) {
        _showSnackBar('خطأ: لم يتم العثور على معلومات المستخدم', Colors.red);
        setState(() => _loading = false);
        return;
      }

      final String finalGrade =
          (newRole == 'admin') ? '' : (newGrade.isEmpty ? 'الأول' : newGrade);

      User newUser = User(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        role: newRole,
        grade: finalGrade,
        schoolId: currentAdmin.schoolId,
      );

      try {
        await MySQLDataService.instance.registerUser(newUser);
        _showSnackBar(
          newRole == 'admin'
              ? 'تمت إضافة الإدمن بنجاح'
              : 'تمت إضافة المستخدم بنجاح',
          Colors.green,
        );
        _resetForm();
      } catch (e) {
        _handleError(e);
      }
      setState(() => _loading = false);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _resetForm() {
    _usernameController.clear();
    _passwordController.clear();
    setState(() {
      newRole = 'user';
      newGrade = 'الأول';
    });
  }

  // تعديل رسالة الخطأ لتوضيح أن التحقق يتم بناءً على نفس المدرسة
  void _handleError(dynamic e) {
    if (e.toString().contains('Duplicate entry')) {
      _showSnackBar(
        'المستخدم موجود بالفعل في هذه المدرسة، أدخل اسم آخر',
        Colors.red,
      );
    } else {
      _showSnackBar('خطأ في إضافة المستخدم: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(appBar: _buildAppBar(), body: _buildBody()),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3FA9F5), Color(0xFF2F62FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Text(
        'إدارة المستخدمين',
        style: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildUserForm(),
            const SizedBox(height: 24),
            _buildViewUsersButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      'إضافة مستخدم جديد',
      textAlign: TextAlign.center,
      style: GoogleFonts.cairo(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF2F62FF),
      ),
    );
  }

  Widget _buildUserForm() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                controller: _usernameController,
                labelText: 'اسم المستخدم',
                prefixIcon: Icons.person,
                validator:
                    (val) =>
                        (val == null || val.isEmpty)
                            ? 'أدخل اسم المستخدم'
                            : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                labelText: 'كلمة المرور',
                prefixIcon: Icons.lock,
                obscureText: true,
                validator:
                    (val) =>
                        (val == null || val.isEmpty)
                            ? 'أدخل كلمة المرور'
                            : null,
              ),
              const SizedBox(height: 16),
              _buildRoleDropdown(),
              const SizedBox(height: 16),
              if (newRole == 'user') _buildGradeDropdown(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.cairo(),
        prefixIcon: Icon(prefixIcon),
        filled: true,
        fillColor: Colors.blue[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
        ),
      ),
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.cairo(),
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: newRole,
      items: [
        DropdownMenuItem(
          value: 'user',
          child: Text('مستخدم', style: GoogleFonts.cairo(color: Colors.black)),
        ),
        DropdownMenuItem(
          value: 'admin',
          child: Text('إدمن', style: GoogleFonts.cairo(color: Colors.black)),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            newRole = value;
            if (newRole == 'admin') {
              newGrade = '';
            } else if (newGrade.isEmpty) {
              newGrade = educationLevels[0];
            }
          });
        }
      },
      decoration: InputDecoration(
        labelText: 'الصلاحية',
        labelStyle: GoogleFonts.cairo(),
        prefixIcon: const Icon(Icons.admin_panel_settings),
        filled: true,
        fillColor: Colors.blue[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
        ),
      ),
      style: GoogleFonts.cairo(),
    );
  }

  Widget _buildGradeDropdown() {
    return DropdownButtonFormField<String>(
      value: newGrade,
      items:
          educationLevels
              .map(
                (level) => DropdownMenuItem(
                  value: level,
                  child: Text(
                    level,
                    style: GoogleFonts.cairo(color: Colors.black),
                  ),
                ),
              )
              .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            newGrade = value;
          });
        }
      },
      decoration: InputDecoration(
        labelText: 'المرحلة الدراسية',
        labelStyle: GoogleFonts.cairo(),
        prefixIcon: const Icon(Icons.school),
        filled: true,
        fillColor: Colors.blue[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
        ),
      ),
      style: GoogleFonts.cairo(),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2F62FF),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _loading ? null : _addUser,
      child:
          _loading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                'إضافة المستخدم',
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 16),
              ),
    );
  }

  Widget _buildViewUsersButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserListScreen()),
        );
      },
      icon: const Icon(Icons.list_alt, color: Colors.white),
      label: Text(
        'عرض جميع المستخدمين',
        style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
