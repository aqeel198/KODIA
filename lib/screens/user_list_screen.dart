import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/user_provider.dart';
import '../services/mysql_data_service.dart';
import '../data/subject_data.dart'; // في حال أردت استخدامه لأغراض أخرى

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // فلتر للمراحل
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

  // فلتر للتخصص للمدرسين
  String selectedSubjectFilter = 'الكل';

  String searchQuery = '';

  Future<List<User>>? _usersFuture;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // ضبط شريط الحالة ليكون شفاف مع أيقونات فاتحة اللون
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // لتحديث الشريط العلوي عند تغيير التبويب
      _refreshData();
    });
    _refreshData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _usersFuture = _fetchUsers();
    });
    await _usersFuture;
    setState(() {
      _isLoading = false;
    });
  }

  Future<List<User>> _fetchUsers() async {
    final currentAdmin = Provider.of<UserProvider>(context, listen: false).user;
    if (currentAdmin == null) return [];
    List<User> allUsers = await MySQLDataService.instance.getAllUsers(
      currentAdmin.schoolId,
    );
    return _filterUsers(allUsers);
  }

  List<User> _filterUsers(List<User> users) {
    return users.where((user) {
      bool roleMatch = false;
      if (_tabController.index == 0) {
        roleMatch = user.role.toLowerCase() == 'user';
      } else if (_tabController.index == 1) {
        roleMatch = user.role.toLowerCase() == 'teacher';
      } else if (_tabController.index == 2) {
        roleMatch = user.role.toLowerCase() == 'admin';
      }

      bool additionalFilter = true;
      if (user.role.toLowerCase() == 'user' && _tabController.index == 0) {
        additionalFilter =
            (selectedGradeFilter == 'الكل') ||
            (user.grade == selectedGradeFilter);
      }
      if (user.role.toLowerCase() == 'teacher' && _tabController.index == 1) {
        additionalFilter =
            (selectedSubjectFilter == 'الكل') ||
            (user.subject == selectedSubjectFilter);
      }
      bool searchMatch =
          searchQuery.isEmpty ||
          user.username.toLowerCase().contains(searchQuery.toLowerCase());

      return roleMatch && additionalFilter && searchMatch;
    }).toList();
  }

  Future<void> _deleteUser(User user) async {
    bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'تأكيد الحذف',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
                content: Text(
                  'هل أنت متأكد من حذف المستخدم "${user.username}"؟',
                  style: GoogleFonts.cairo(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'إلغاء',
                      style: GoogleFonts.cairo(color: Colors.grey[700]),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      'حذف',
                      style: GoogleFonts.cairo(color: Colors.white),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
    if (confirm) {
      try {
        setState(() => _isLoading = true);
        await MySQLDataService.instance.deleteUser(user.id!, user.schoolId);
        _showSnackBar('تم حذف المستخدم "${user.username}" بنجاح', Colors.green);
        _refreshData();
      } catch (e) {
        _showSnackBar('فشل الحذف: $e', Colors.red);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateUser(User user) async {
    User? updatedUser = await showDialog<User>(
      context: context,
      builder: (context) => _EditUserDialog(user: user, isNewUser: false),
    );
    if (updatedUser != null) {
      try {
        setState(() => _isLoading = true);
        await MySQLDataService.instance.updateUser(updatedUser);
        _showSnackBar(
          'تم تعديل المستخدم "${updatedUser.username}" بنجاح',
          Colors.green,
        );
        _refreshData();
      } catch (e) {
        _showSnackBar('فشل التعديل: $e', Colors.red);
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<List<String>> _fetchTeacherSubjects() async {
    final currentAdmin = Provider.of<UserProvider>(context, listen: false).user;
    if (currentAdmin == null) return [];
    List<String> subjects = await MySQLDataService.instance.getTeacherSubjects(
      currentAdmin.schoolId,
    );
    subjects = subjects.toSet().toList();
    subjects.sort();
    subjects.insert(0, 'الكل');
    return subjects;
  }

  /// بناء الشريط العلوي المخصص بناءً على التبويب النشط
  Widget _buildCustomTopBar() {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double screenWidth = MediaQuery.of(context).size.width;
    // تغيير حجم النص والأيقونات حسب حجم الشاشة
    final double iconSize = screenWidth < 360 ? 20 : 24;
    final double fontSize = screenWidth < 360 ? 16 : 20;
    String title;
    IconData iconData;
    switch (_tabController.index) {
      case 0:
        title = "الطلاب";
        iconData = Icons.person;
        break;
      case 1:
        title = "التدريسيين";
        iconData = Icons.school;
        break;
      case 2:
        title = "الإدمن";
        iconData = Icons.admin_panel_settings;
        break;
      default:
        title = "المستخدمين";
        iconData = Icons.people;
    }

    // ارتفاع الشريط المخصص
    const double barHeight = 60;
    return Container(
      height: statusBarHeight + barHeight,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3FA9F5), Color(0xFF2F62FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.only(top: statusBarHeight),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // زر العودة أو أي زر آخر في الجهة اليسرى (يمكن تعديله)
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: iconSize),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          // العنوان مع أيقونة التبويب
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconData, color: Colors.white, size: iconSize),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // زر التحديث في الجهة اليمنى
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white, size: iconSize),
            onPressed: _refreshData,
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Column(
          children: [_buildCustomTopBar(), Expanded(child: _buildBody())],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildFilterSection()),
              SliverToBoxAdapter(child: _buildUserList()),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Column(
            children: [
              _buildTabBar(),
              const SizedBox(height: 16),
              if (_tabController.index == 0) _buildGradeFilter(),
              if (_tabController.index == 1)
                FutureBuilder<List<String>>(
                  future: _fetchTeacherSubjects(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'خطأ في جلب التخصصات',
                            style: GoogleFonts.cairo(color: Colors.red),
                          ),
                        ),
                      );
                    }
                    final dynamicTeacherSubjects = snapshot.data ?? ['الكل'];
                    return _buildTeacherSubjectFilter(dynamicTeacherSubjects);
                  },
                ),
              const SizedBox(height: 16),
              _buildSearchField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    // تحديد حجم الخط بناءً على عرض الشاشة
    final tabTextSize =
        screenWidth < 360
            ? 12.0
            : screenWidth < 600
            ? 14.0
            : 16.0;

    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // خلفية متدرّجة عصرية
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEDF1F4), Color(0xFFDCE3EC)],
          ),
          boxShadow: [
            // ظل خفيف (نيو مورفيزم/Modern Shadow)
            BoxShadow(
              color: Colors.black12,
              offset: Offset(2, 2),
              blurRadius: 6,
            ),
            BoxShadow(
              color: Colors.white60,
              offset: Offset(-2, -2),
              blurRadius: 6,
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          // توزيع التابات بالتساوي عبر العرض المتاح
          isScrollable: false,
          // إخفاء الفاصل بين التابات
          dividerColor: Colors.transparent,
          indicatorColor: Colors.transparent,

          // تصميم المؤشر (الخلفية الملوّنة للتاب المفعّل)
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(18.0),
            gradient: const LinearGradient(
              colors: [Color(0xFF3FA9F5), Color(0xFF2F62FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x4D3FA9F5), // ظل خفيف للتاب المفعّل
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),

          // لون نص التاب المفعّل
          labelColor: Colors.white,
          // لون نص التاب غير المفعّل
          unselectedLabelColor: Colors.black54,

          // ستايل الخط
          labelStyle: GoogleFonts.cairo(
            fontSize: tabTextSize,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: GoogleFonts.cairo(
            fontSize: tabTextSize,
            fontWeight: FontWeight.w400,
          ),

          // تقليل الفراغات بين التابات
          labelPadding: EdgeInsets.zero,
          // لجعل الأيقونة والنص بجانب بعضهما أفقيًا بشكل افتراضي
          tabs: [
            Tab(
              child: Row(
                textDirection:
                    TextDirection.rtl, // عرض النص قبل الأيقونة (عربي)
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('الطلاب'),
                  const SizedBox(width: 6),
                  Icon(Icons.person, size: tabTextSize + 2),
                ],
              ),
            ),
            Tab(
              child: Row(
                textDirection: TextDirection.rtl,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('التدريسيين'),
                  const SizedBox(width: 6),
                  Icon(Icons.school, size: tabTextSize + 2),
                ],
              ),
            ),
            Tab(
              child: Row(
                textDirection: TextDirection.rtl,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('الإدمن'),
                  const SizedBox(width: 6),
                  Icon(Icons.admin_panel_settings, size: tabTextSize + 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /*************  ✨ Codeium Command ⭐  *************/
  /// Builds a dropdown filter for selecting the grade level.
  ///
  /// This widget displays a dropdown menu with various grade levels

  /******  d9ddf42b-ed39-4d84-a0fb-02cf49a5560e  *******/
  Widget _buildGradeFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedGradeFilter,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2F62FF)),
          isExpanded: true,
          items:
              gradeFilterLevels
                  .map(
                    (level) => DropdownMenuItem(
                      value: level,
                      child: Row(
                        children: [
                          Icon(
                            level == 'الكل' ? Icons.all_inclusive : Icons.grade,
                            color: const Color(0xFF2F62FF),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            level,
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ],
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
          style: GoogleFonts.cairo(color: Colors.black),
          dropdownColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTeacherSubjectFilter(List<String> dynamicSubjects) {
    if (!dynamicSubjects.contains(selectedSubjectFilter)) {
      selectedSubjectFilter = 'الكل';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedSubjectFilter,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2F62FF)),
          isExpanded: true,
          items:
              dynamicSubjects
                  .map(
                    (subject) => DropdownMenuItem(
                      value: subject,
                      child: Row(
                        children: [
                          Icon(
                            subject == 'الكل'
                                ? Icons.all_inclusive
                                : Icons.subject,
                            color: const Color(0xFF2F62FF),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            subject,
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedSubjectFilter = value;
              });
              _refreshData();
            }
          },
          style: GoogleFonts.cairo(color: Colors.black),
          dropdownColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    String label;
    IconData searchIcon;
    if (_tabController.index == 2) {
      label = 'بحث بالإدمن (اسم الادمن)';
      searchIcon = Icons.admin_panel_settings;
    } else if (_tabController.index == 1) {
      label = 'بحث بالتدريسيين (اسم المدرس)';
      searchIcon = Icons.school;
    } else {
      label = 'بحث بالطلاب (اسم الطالب)';
      searchIcon = Icons.person;
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(),
          prefixIcon: Icon(searchIcon, color: const Color(0xFF2F62FF)),
          suffixIcon:
              searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      setState(() => searchQuery = '');
                      _refreshData();
                    },
                  )
                  : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[200]!, width: 1),
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
        onChanged: (value) {
          setState(() => searchQuery = value);
          _refreshData();
        },
        style: GoogleFonts.cairo(),
      ),
    );
  }

  Widget _buildUserList() {
    return FutureBuilder<List<User>>(
      future: _usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_isLoading) {
          return const Padding(
            padding: EdgeInsets.only(top: 50),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'خطأ: ${snapshot.error}',
                    style: GoogleFonts.cairo(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refreshData,
                    icon: const Icon(Icons.refresh),
                    label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F62FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _tabController.index == 0
                        ? Icons.person_off
                        : _tabController.index == 1
                        ? Icons.school_outlined
                        : Icons.admin_panel_settings_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا يوجد مستخدمون.',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (searchQuery.isNotEmpty ||
                      selectedGradeFilter != 'الكل' ||
                      selectedSubjectFilter != 'الكل')
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          searchQuery = '';
                          selectedGradeFilter = 'الكل';
                          selectedSubjectFilter = 'الكل';
                        });
                        _refreshData();
                      },
                      icon: const Icon(Icons.filter_alt_off),
                      label: Text('إزالة الفلاتر', style: GoogleFonts.cairo()),
                    ),
                ],
              ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    String subtitleText;
    IconData roleIcon;
    Color roleColor;
    if (user.role.toLowerCase() == 'user') {
      final displayGrade =
          (user.grade == null || user.grade!.isEmpty) ? 'لا يوجد' : user.grade!;
      subtitleText = 'المرحلة الدراسية: $displayGrade | الصلاحية: طالب';
      roleIcon = Icons.person;
      roleColor = Colors.blue;
    } else if (user.role.toLowerCase() == 'teacher') {
      final displaySubj =
          (user.subject == null || user.subject!.isEmpty)
              ? 'غير محدد'
              : user.subject!;
      subtitleText = 'التخصص: $displaySubj | الصلاحية: مدرس';
      roleIcon = Icons.school;
      roleColor = Colors.green;
    } else {
      subtitleText = 'الصلاحية: إدمن';
      roleIcon = Icons.admin_panel_settings;
      roleColor = Colors.purple;
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: roleColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: roleColor.withOpacity(0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: roleColor.withOpacity(0.2),
                child: Icon(roleIcon, color: roleColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: GoogleFonts.cairo(
                        fontSize: isSmallScreen ? 15 : 17,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitleText,
                      style: GoogleFonts.cairo(
                        color: Colors.grey[700],
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _updateUser(user),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.edit,
                          color: Colors.green[600],
                          size: isSmallScreen ? 20 : 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _deleteUser(user),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.delete,
                          color: Colors.red[600],
                          size: isSmallScreen ? 20 : 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
  late String _subject;
  bool _showPassword = false;

  final List<String> educationLevels = [
    'الأول',
    'الثاني',
    'الثالث',
    'الرابع',
    'الخامس',
    'السادس',
  ];

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _passwordController = TextEditingController(text: widget.user.password);
    _role = widget.user.role;
    _grade = widget.user.grade ?? '';
    _subject = widget.user.subject ?? '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      backgroundColor: Colors.white,
      child: Container(
        width: dialogWidth,
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.isNewUser ? Icons.person_add : Icons.edit,
                      color: const Color(0xFF2F62FF),
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isNewUser ? 'إضافة مستخدم جديد' : 'تعديل المستخدم',
                      style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2F62FF),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const Divider(height: 32),
                _buildTextField(
                  controller: _usernameController,
                  label: 'اسم المستخدم',
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 16),
                _buildRoleDropdown(),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child:
                      _role.toLowerCase() == 'user'
                          ? _buildGradeDropdown()
                          : _role.toLowerCase() == 'teacher'
                          ? _buildSubjectField()
                          : const SizedBox.shrink(),
                ),
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
                        String finalGrade = '';
                        String finalSubject = '';
                        if (_role.toLowerCase() == 'user') {
                          finalGrade = _grade;
                        } else if (_role.toLowerCase() == 'teacher') {
                          finalSubject = _subject;
                        }
                        final updatedUser = widget.user.copyWith(
                          username: _usernameController.text,
                          password: _passwordController.text,
                          role: _role,
                          grade: finalGrade,
                          subject: finalSubject,
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
      ),
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
        value: _role,
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
          if (value == null) return;
          setState(() {
            _role = value;
          });
        },
        decoration: InputDecoration(
          labelText: 'الصلاحية',
          labelStyle: GoogleFonts.cairo(),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        style: GoogleFonts.cairo(color: Colors.black),
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
        value: (_grade.isEmpty) ? 'الأول' : _grade,
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
              _grade = value;
            });
          }
        },
        decoration: InputDecoration(
          labelText: 'المرحلة الدراسية',
          labelStyle: GoogleFonts.cairo(),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        style: GoogleFonts.cairo(color: Colors.black),
        icon: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Icon(Icons.arrow_drop_down, color: Color(0xFF2F62FF)),
        ),
        isExpanded: true,
        dropdownColor: Colors.white,
      ),
    );
  }

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
          return SubjectData().teacherSubjects.where(
            (option) => option.toLowerCase().contains(
              textEditingValue.text.toLowerCase(),
            ),
          );
        },
        onSelected: (String selection) {
          setState(() {
            _subject = selection;
          });
        },
        initialValue: TextEditingValue(text: _subject),
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          controller.addListener(() {
            setState(() {
              _subject = controller.text;
            });
          });
          return TextField(
            controller: controller,
            focusNode: focusNode,
            onSubmitted: (_) => onFieldSubmitted(),
            decoration: InputDecoration(
              labelText: 'التخصص',
              labelStyle: GoogleFonts.cairo(),
              prefixIcon: const Icon(Icons.subject, color: Color(0xFF2F62FF)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
                      onTap: () => onSelected(option),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 1),
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
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 1),
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
            icon: Icon(
              _showPassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
            ),
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

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? const Color(0xFF2F62FF) : Colors.grey[200],
        foregroundColor: isPrimary ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: isPrimary ? 2 : 0,
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
