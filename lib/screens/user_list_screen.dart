import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user.dart';
import '../providers/user_provider.dart';
import '../services/mysql_data_service.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedGradeFilter = 'الكل';
  final List<String> gradeFilterLevels = [
    'الكل',
    'الأول',
    'الثاني',
    'الثالث',
    'الرابع',
    'الخامس',
    'السادس',
  ];
  String searchQuery = '';

  Future<List<User>>? _usersFuture;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _refreshData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _usersFuture = _fetchUsers();
    });
  }

  Future<List<User>> _fetchUsers() async {
    final currentAdmin = Provider.of<UserProvider>(context, listen: false).user;
    if (currentAdmin == null) {
      return [];
    }

    List<User> allUsers = await MySQLDataService.instance.getAllUsers(
      currentAdmin.schoolId,
    );
    return _filterUsers(allUsers);
  }

  List<User> _filterUsers(List<User> users) {
    return users.where((user) {
      bool roleMatch =
          _tabController.index == 0
              ? user.role.toLowerCase() == 'user'
              : user.role.toLowerCase() == 'admin';
      bool gradeMatch = true;
      if (user.role.toLowerCase() == 'user') {
        gradeMatch =
            (selectedGradeFilter == 'الكل') ||
            (user.grade == selectedGradeFilter);
      }
      bool searchMatch =
          searchQuery.isEmpty ||
          user.username.toLowerCase().contains(searchQuery.toLowerCase());
      return roleMatch && gradeMatch && searchMatch;
    }).toList();
  }

  Future<void> _deleteUser(User user) async {
    bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('تأكيد الحذف', style: GoogleFonts.cairo()),
                content: Text(
                  'هل أنت متأكد من حذف هذا المستخدم؟',
                  style: GoogleFonts.cairo(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('إلغاء', style: GoogleFonts.cairo()),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('حذف', style: GoogleFonts.cairo()),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirm) {
      try {
        await MySQLDataService.instance.deleteUser(user.id!, user.schoolId);
        _showSnackBar('تم الحذف بنجاح', Colors.green);
        _refreshData();
      } catch (e) {
        _showSnackBar('فشل الحذف: $e', Colors.red);
      }
    }
  }

  Future<void> _updateUser(User user) async {
    User? updatedUser = await showDialog<User>(
      context: context,
      builder: (context) => _EditUserDialog(user: user, isNewUser: false),
    );

    try {
      await MySQLDataService.instance.updateUser(updatedUser!);
      _showSnackBar('تم التعديل بنجاح', Colors.green);
      _refreshData();
    } catch (e) {
      _showSnackBar('فشل التعديل: $e', Colors.red);
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
        'قائمة المستخدمين',
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
      onRefresh: _refreshData,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildFilterSection()),
          SliverToBoxAdapter(child: _buildUserList()),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTabBar(),
            const SizedBox(height: 16),
            if (_tabController.index == 0) _buildGradeFilter(),
            const SizedBox(height: 16),
            _buildSearchField(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: Colors.blue,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.black,
        tabs: [
          Tab(child: Text('المستخدمين', style: GoogleFonts.cairo())),
          Tab(child: Text('الإدمن', style: GoogleFonts.cairo())),
        ],
      ),
    );
  }

  Widget _buildGradeFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedGradeFilter,
          icon: const Icon(Icons.keyboard_arrow_down),
          isExpanded: true,
          items:
              gradeFilterLevels
                  .map(
                    (level) => DropdownMenuItem(
                      value: level,
                      child: Text(
                        level,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedGradeFilter = value;
              });
              _refreshData();
            }
          },
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        labelText:
            _tabController.index == 1
                ? 'بحث بالإدمن (اسم المستخدم)'
                : 'بحث بالمستخدمين (اسم المستخدم)',
        labelStyle: GoogleFonts.cairo(),
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.blue[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (value) {
        setState(() {
          searchQuery = value;
        });
        _refreshData();
      },
      style: GoogleFonts.cairo(),
    );
  }

  Widget _buildUserList() {
    return FutureBuilder<List<User>>(
      future: _usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 50),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text('خطأ: ${snapshot.error}', style: GoogleFonts.cairo()),
            ),
          );
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text('لا يوجد مستخدمون.', style: TextStyle(fontSize: 16)),
            ),
          );
        }
        return AnimationLimiter(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            itemBuilder: (context, index) {
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: _buildUserCard(users[index])),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildUserCard(User user) {
    final displayGrade = user.grade!.isEmpty ? 'لا يوجد' : user.grade;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(
            user.role.toLowerCase() == 'admin'
                ? Icons.admin_panel_settings
                : Icons.person,
            color: Colors.blue[800],
          ),
        ),
        title: Text(
          user.username,
          style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'المرحلة الدراسية: $displayGrade | الصلاحية: ${user.role}',
          style: GoogleFonts.cairo(color: Colors.grey[700], fontSize: 14),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.green),
              onPressed: () => _updateUser(user),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteUser(user),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditUserDialog extends StatefulWidget {
  final User user;
  final bool isNewUser;

  const _EditUserDialog({required this.user, required this.isNewUser});

  @override
  __EditUserDialogState createState() => __EditUserDialogState();
}

class __EditUserDialogState extends State<_EditUserDialog> {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late String _role;
  late String _grade;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _passwordController = TextEditingController(text: widget.user.password);
    _role = widget.user.role;
    _grade = _role == 'user' ? (widget.user.grade ?? 'الأول') : '';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isNewUser ? 'إضافة مستخدم جديد' : 'تعديل المستخدم',
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _usernameController,
                label: 'اسم المستخدم',
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              _buildPasswordField(),
              const SizedBox(height: 16),
              _buildDropdown(
                value: _role,
                label: 'الصلاحية',
                icon: Icons.admin_panel_settings,
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('مستخدم')),
                  DropdownMenuItem(value: 'admin', child: Text('إدمن')),
                ],
                onChanged: (value) {
                  setState(() {
                    _role = value!;
                    if (_role == 'admin') {
                      _grade = '';
                    } else {
                      if (_grade.isEmpty) {
                        _grade = 'الأول';
                      }
                    }
                  });
                },
              ),
              if (_role == 'user') ...[
                const SizedBox(height: 16),
                _buildDropdown(
                  value: _grade.isEmpty ? 'الأول' : _grade,
                  label: 'المرحلة الدراسية',
                  icon: Icons.school,
                  items:
                      [
                            'الأول',
                            'الثاني',
                            'الثالث',
                            'الرابع',
                            'الخامس',
                            'السادس',
                          ]
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
                  onChanged: (value) => setState(() => _grade = value!),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildButton(
                    label: 'إلغاء',
                    onPressed: () => Navigator.pop(context),
                    isPrimary: false,
                  ),
                  _buildButton(
                    label: widget.isNewUser ? 'إضافة' : 'حفظ',
                    onPressed: () {
                      final updatedUser = widget.user.copyWith(
                        username: _usernameController.text,
                        password: _passwordController.text,
                        role: _role,
                        grade: _grade,
                      );
                      Navigator.pop(context, updatedUser);
                    },
                    isPrimary: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.cairo(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(),
          prefixIcon: Icon(icon, color: const Color(0xFF2F62FF)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: !_showPassword,
        style: GoogleFonts.cairo(),
        decoration: InputDecoration(
          labelText: 'كلمة المرور',
          labelStyle: GoogleFonts.cairo(),
          prefixIcon: const Icon(Icons.lock, color: Color(0xFF2F62FF)),
          suffixIcon: IconButton(
            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.cairo(),
            prefixIcon: Icon(icon, color: const Color(0xFF2F62FF)),
            border: InputBorder.none,
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2F62FF)),
          style: GoogleFonts.cairo(color: Colors.black), // تعديل هنا
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? const Color(0xFF2F62FF) : Colors.grey[300],
        foregroundColor: isPrimary ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: GoogleFonts.cairo()),
    );
  }
}
