// lib/screens/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/mysql_data_service.dart';
import 'user_list_screen.dart';
import '../providers/user_provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // متغيرات الإدخال
  String newGrade = 'الأول';
  String newSubject = ''; // يبدأ فارغاً ليتم استكماله بالاقتراحات
  String newRole = 'user';
  bool _loading = false;
  bool _obscurePassword = true;

  final List<String> educationLevels = [
    'الأول',
    'الثاني',
    'الثالث',
    'الرابع',
    'الخامس',
    'السادس',
  ];

  // قائمة لتخزين التخصصات المُضافة يدويًا والمسترجعة من قاعدة البيانات
  final List<String> _savedTeacherSubjects = [];

  @override
  void initState() {
    super.initState();
    newSubject = '';
    _loadSubjectsFromDB();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// دالة لتحميل قائمة المواد الفريدة لمستخدمي نوع teacher من قاعدة البيانات
  Future<void> _loadSubjectsFromDB() async {
    try {
      final currentAdmin =
          Provider.of<UserProvider>(context, listen: false).user;
      if (currentAdmin != null) {
        List<String> subjects = await MySQLDataService.instance
            .getTeacherSubjects(currentAdmin.schoolId);
        setState(() {
          _savedTeacherSubjects.clear();
          _savedTeacherSubjects.addAll(subjects);
        });
      }
    } catch (e) {
      debugPrint("Error loading subjects: $e");
    }
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

      String finalGrade = '';
      String finalSubject = '';

      if (newRole == 'user') {
        finalGrade = newGrade;
      } else if (newRole == 'teacher') {
        finalSubject = newSubject;
        if (finalSubject.isNotEmpty &&
            !_savedTeacherSubjects.contains(finalSubject.trim())) {
          _savedTeacherSubjects.add(finalSubject.trim());
          // يمكنك تحديث قاعدة البيانات هنا لتخزين المادة بشكل دائم
        }
      }

      User newUser = User(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        role: newRole,
        grade: finalGrade,
        subject: finalSubject,
        schoolId: currentAdmin.schoolId,
      );

      try {
        await MySQLDataService.instance.registerUser(newUser);
        _showSnackBar('تم إضافة المستخدم بنجاح', Colors.green);
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
        content: Text(
          message,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _resetForm() {
    _usernameController.clear();
    _passwordController.clear();
    setState(() {
      newRole = 'user';
      newGrade = 'الأول';
      newSubject = '';
      _obscurePassword = true;
    });
  }

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
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
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
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_alt, size: 24),
          const SizedBox(width: 8),
          Text(
            'إدارة المستخدمين',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadSubjectsFromDB,
          tooltip: 'تحديث البيانات',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _loadSubjectsFromDB,
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.person_add, size: 48, color: Color(0xFF2F62FF)),
          const SizedBox(height: 8),
          Text(
            'إضافة مستخدم جديد',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2F62FF),
            ),
          ),
          Text(
            'أدخل بيانات المستخدم الجديد',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildUserForm() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
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
              _buildPasswordField(),
              const SizedBox(height: 16),
              _buildRoleDropdown(),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child:
                    newRole == 'user'
                        ? _buildGradeDropdown()
                        : newRole == 'teacher'
                        ? _buildSubjectField()
                        : const SizedBox.shrink(),
              ),
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
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF2F62FF)),
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.cairo(),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'كلمة المرور',
        labelStyle: GoogleFonts.cairo(),
        prefixIcon: const Icon(Icons.lock, color: Color(0xFF2F62FF)),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey[600],
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      validator:
          (val) => (val == null || val.isEmpty) ? 'أدخل كلمة المرور' : null,
      style: GoogleFonts.cairo(),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: DropdownButtonFormField<String>(
        value: newRole,
        items: [
          DropdownMenuItem(
            value: 'user',
            child: Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF2F62FF), size: 20),
                const SizedBox(width: 8),
                Text('طالب', style: GoogleFonts.cairo(color: Colors.black)),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'teacher',
            child: Row(
              children: [
                const Icon(Icons.school, color: Color(0xFF2F62FF), size: 20),
                const SizedBox(width: 8),
                Text('مدرس', style: GoogleFonts.cairo(color: Colors.black)),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'admin',
            child: Row(
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  color: Color(0xFF2F62FF),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('إدمن', style: GoogleFonts.cairo(color: Colors.black)),
              ],
            ),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() {
              newRole = value;
            });
          }
        },
        decoration: InputDecoration(
          labelText: 'الصلاحية',
          labelStyle: GoogleFonts.cairo(),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        style: GoogleFonts.cairo(),
        icon: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Icon(Icons.arrow_drop_down, color: Color(0xFF2F62FF)),
        ),
        isExpanded: true,
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildGradeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: DropdownButtonFormField<String>(
        value: newGrade,
        items:
            educationLevels
                .map(
                  (level) => DropdownMenuItem(
                    value: level,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.grade,
                          color: Color(0xFF2F62FF),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          level,
                          style: GoogleFonts.cairo(color: Colors.black),
                        ),
                      ],
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
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        style: GoogleFonts.cairo(),
        icon: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Icon(Icons.arrow_drop_down, color: Color(0xFF2F62FF)),
        ),
        isExpanded: true,
        dropdownColor: Colors.white,
      ),
    );
  }

  /// استخدام Autocomplete لاستكمال حقل "التخصص" داخل نفس مربع الإدخال
  /// تظهر الاقتراحات عند كتابة حرفين أو أكثر بناءً على القائمة _savedTeacherSubjects
  Widget _buildSubjectField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.length < 2) {
            return const Iterable<String>.empty();
          }
          return _savedTeacherSubjects.where(
            (option) => option.toLowerCase().contains(
              textEditingValue.text.toLowerCase(),
            ),
          );
        },
        onSelected: (String selection) {
          setState(() {
            newSubject = selection;
          });
        },
        initialValue: TextEditingValue(text: newSubject),
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          controller.addListener(() {
            setState(() {
              newSubject = controller.text;
            });
          });
          return TextField(
            controller: controller,
            focusNode: focusNode,
            onSubmitted: (value) => onFieldSubmitted(),
            decoration: InputDecoration(
              labelText: 'التخصص',
              labelStyle: GoogleFonts.cairo(),
              prefixIcon: const Icon(Icons.subject, color: Color(0xFF2F62FF)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
            ),
            style: GoogleFonts.cairo(),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final option = options.elementAt(index);
                    return InkWell(
                      onTap: () {
                        onSelected(option);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        child: Text(option, style: GoogleFonts.cairo()),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2F62FF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      onPressed: _loading ? null : _addUser,
      child:
          _loading
              ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'جاري الإضافة...',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'إضافة المستخدم',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildViewUsersButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Color(0xFF00796B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
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
      ),
    );
  }
}
