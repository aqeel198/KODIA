import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import '../services/mysql_data_service.dart';
import 'user_list_screen.dart';
import 'package:provider/provider.dart'; // <-- أضف هذا للاستفادة من UserProvider
import '../providers/user_provider.dart'; // <-- لاستيراد UserProvider

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

      // جلب المستخدم الحالي (الذي يفترض أنه Admin) للحصول على schoolId
      final currentAdmin =
          Provider.of<UserProvider>(context, listen: false).user;
      if (currentAdmin == null) {
        _showSnackBar(
          'خطأ: لم يتم العثور على معلومات المستخدم',
          Colors.redAccent,
        );
        setState(() => _loading = false);
        return;
      }

      // إذا كان الدور Admin، لا نستخدم قيمة grade
      final String finalGrade =
          (newRole == 'admin') ? '' : (newGrade.isEmpty ? 'الأول' : newGrade);

      // إنشاء كائن المستخدم الجديد مع ربطه بـ schoolId الخاص بالإدمن
      User newUser = User(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        role: newRole,
        grade: finalGrade,
        schoolId: currentAdmin.schoolId, // <-- التعديل الأهم
      );

      try {
        await MySQLDataService.instance.registerUser(newUser);
        _showSnackBar(
          newRole == 'admin'
              ? 'تمت إضافة الإدمن بنجاح'
              : 'تمت إضافة المستخدم بنجاح',
          Colors.green[600]!,
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
        content: Text(message),
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

  void _handleError(dynamic e) {
    if (e.toString().contains('Duplicate entry')) {
      _showSnackBar('المستخدم موجود بالفعل، أدخل اسم آخر', Colors.redAccent);
    } else {
      _showSnackBar('خطأ في إضافة المستخدم: $e', Colors.redAccent);
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
      title: const Text(
        'إدارة المستخدمين',
        style: TextStyle(
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
    return const Text(
      'إضافة مستخدم جديد',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2F62FF),
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
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: newRole,
      items: const [
        DropdownMenuItem(value: 'user', child: Text('مستخدم')),
        DropdownMenuItem(value: 'admin', child: Text('إدمن')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            newRole = value;
            // إذا تم اختيار إدمن، نجعل grade فارغ
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
    );
  }

  Widget _buildGradeDropdown() {
    return DropdownButtonFormField<String>(
      value: newGrade,
      items:
          educationLevels
              .map(
                (level) => DropdownMenuItem(value: level, child: Text(level)),
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
              : const Text(
                'إضافة المستخدم',
                style: TextStyle(color: Colors.white, fontSize: 16),
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
      label: const Text(
        'عرض جميع المستخدمين',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
