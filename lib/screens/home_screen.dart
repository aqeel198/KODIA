import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:school_platform/models/user.dart';
import 'package:school_platform/models/folder.dart';
import 'package:school_platform/providers/user_provider.dart';
import 'package:school_platform/services/mysql_data_service.dart';
import 'package:school_platform/screens/folder_upload_screen.dart';
import 'package:school_platform/screens/folder_contents_screen.dart';
import 'package:school_platform/screens/reports_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String selectedFilter = 'الكل';
  final List<String> filterLevels = [
    'الكل',
    'الأول',
    'الثاني',
    'الثالث',
    'الرابع',
    'الخامس',
    'السادس',
  ];

  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // أنشئ AnimationController لرسوم بسيطة (اختياري)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// جلب تاريخ انتهاء الاشتراك وحساب الأيام المتبقية
  Future<int?> _fetchDaysLeftForSubscription() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return null;
    try {
      final subEnd = await MySQLDataService.instance.getSubscriptionEndDate(
        user.schoolId,
      );
      if (subEnd == null) return null;
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final subDate = DateTime(subEnd.year, subEnd.month, subEnd.day);
      return subDate.difference(todayDate).inDays;
    } catch (e) {
      print("Error fetching subscription days: $e");
      return null;
    }
  }

  /// جلب قائمة المجلدات
  Future<List<Folder>> _fetchFolders() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return [];
    List<Folder> allFolders = await MySQLDataService.instance.getAllFolders(
      user.schoolId,
    );

    // فلترة حسب دور المستخدم
    if (user.role.toLowerCase() == 'user') {
      // الطالب يرى فقط مجلداته التي توافق مرحلته
      return allFolders.where((folder) => folder.grade == user.grade).toList();
    } else if (user.role.toLowerCase() == 'admin') {
      // المدير يستطيع فلترة المجلدات
      return selectedFilter == 'الكل'
          ? allFolders
          : allFolders
              .where((folder) => folder.grade == selectedFilter)
              .toList();
    }
    return allFolders;
  }

  /// دالة تسجيل الخروج
  Future<void> _logout() async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout, size: 60, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      'تسجيل الخروج',
                      style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'هل أنت متأكد من تسجيل الخروج؟',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            'تسجيل الخروج',
                            style: GoogleFonts.cairo(fontSize: 16),
                          ),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'إلغاء',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;

    if (confirm) {
      // مسح بيانات تسجيل الدخول المخزنة
      await secureStorage.delete(key: 'username');
      await secureStorage.delete(key: 'password');
      await secureStorage.delete(key: 'schoolCode');

      // إعادة تعيين user في الـ Provider
      Provider.of<UserProvider>(context, listen: false).setUser(null);

      // العودة لصفحة تسجيل الدخول
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // دالة تعديل المجلد
  Future<void> _updateFolder(Folder folder) async {
    TextEditingController nameController = TextEditingController(
      text: folder.name,
    );
    String selectedGrade = folder.grade;
    final List<String> gradeOptions = [
      'الأول',
      'الثاني',
      'الثالث',
      'الرابع',
      'الخامس',
      'السادس',
    ];

    final result = await showDialog<Folder>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("تعديل المجلد", style: GoogleFonts.cairo()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "اسم المجلد"),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedGrade,
                items:
                    gradeOptions.map((grade) {
                      return DropdownMenuItem<String>(
                        value: grade,
                        child: Text(grade, style: GoogleFonts.cairo()),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedGrade = value;
                  }
                },
                decoration: const InputDecoration(labelText: "اختر المرحلة"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("إلغاء", style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedFolder = Folder(
                  id: folder.id,
                  name: nameController.text,
                  grade: selectedGrade,
                  schoolId: folder.schoolId,
                  userId: folder.userId,
                );
                Navigator.pop(context, updatedFolder);
              },
              child: Text("حفظ", style: GoogleFonts.cairo()),
            ),
          ],
        );
      },
    );

    if (result != null) {
      try {
        await MySQLDataService.instance.updateFolder(result);
        setState(() {});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تعديل المجلد: $e', style: GoogleFonts.cairo()),
          ),
        );
      }
    }
  }

  // دالة حذف المجلد
  Future<void> _deleteFolder(Folder folder) async {
    try {
      bool confirm =
          await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("حذف المجلد", style: GoogleFonts.cairo()),
                content: Text(
                  "هل أنت متأكد من حذف هذا المجلد؟",
                  style: GoogleFonts.cairo(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text("إلغاء", style: GoogleFonts.cairo()),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      "حذف",
                      style: GoogleFonts.cairo(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ) ??
          false;

      if (confirm) {
        final user = Provider.of<UserProvider>(context, listen: false).user!;
        await MySQLDataService.instance.deleteFolder(folder.id!, user.schoolId);
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل حذف المجلد: $e', style: GoogleFonts.cairo()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // نجلب كائن user من UserProvider
    final user = Provider.of<UserProvider>(context).user;

    // إذا كان user غير مهيأ بعد، نعرض شاشة انتظار
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: SizedBox());
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: _buildAppBar(user),
        body: FutureBuilder<int?>(
          future: _fetchDaysLeftForSubscription(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'خطأ: ${snapshot.error}',
                  style: GoogleFonts.cairo(),
                ),
              );
            }
            final daysLeft = snapshot.data;
            return _buildBodyWithSubscriptionText(user, daysLeft);
          },
        ),
        floatingActionButton: _buildFloatingActionButton(user),
      ),
    );
  }

  Widget _buildBodyWithSubscriptionText(User user, int? daysLeft) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFF5F7FA)),
      child: Column(
        children: [
          // تنبيه بقرب انتهاء الاشتراك (إن كان Admin)
          if (user.role.toLowerCase() == 'admin' &&
              daysLeft != null &&
              daysLeft <= 30)
            _buildSubscriptionWarning(daysLeft),

          // قسم الفلترة (إن كان Admin)
          if (user.role.toLowerCase() == 'admin') _buildFilterSection(),

          // قائمة المجلدات
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: FutureBuilder<List<Folder>>(
                future: _fetchFolders(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _buildErrorWidget('خطأ: ${snapshot.error}');
                  }
                  final folders = snapshot.data ?? [];
                  if (folders.isEmpty) {
                    return _buildEmptyWidget();
                  }
                  return _buildFolderList(folders, user);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionWarning(int daysLeft) {
    Color textColor = Colors.green;
    if (daysLeft < 0) {
      textColor = Colors.red;
    } else if (daysLeft <= 1) {
      textColor = Colors.deepOrange;
    } else if (daysLeft <= 7) {
      textColor = Colors.orange;
    } else if (daysLeft <= 30) {
      textColor = Colors.yellow.shade700;
    }

    String message =
        daysLeft < 0
            ? 'انتهى الاشتراك! يرجى التجديد فوراً.'
            : 'عدد الأيام المتبقية على انتهاء الاشتراك: $daysLeft يوم';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: textColor.withOpacity(0.2),
      child: Text(
        message,
        style: GoogleFonts.cairo(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFilterSection() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _animation.value)),
          child: Opacity(
            opacity: _animation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المجلدات',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2F62FF),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'فلترة حسب المرحلة: ',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedFilter,
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xFF2F62FF),
                            ),
                            items:
                                filterLevels.map((level) {
                                  return DropdownMenuItem<String>(
                                    value: level,
                                    child: Text(
                                      level,
                                      style: GoogleFonts.cairo(
                                        color: const Color(0xFF2F62FF),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => selectedFilter = value);
                              }
                            },
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
      },
    );
  }

  Widget _buildFolderList(List<Folder> folders, User user) {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: folders.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildFolderCard(folders[index], user),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFolderCard(Folder folder, User user) {
    final bool isAdmin = (user.role.toLowerCase() == 'admin');
    final Color folderColor = _getFolderColor(folder.grade);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FolderContentsScreen(folder: folder),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                folderColor.withOpacity(0.05),
                folderColor.withOpacity(0.1),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: folderColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.folder, color: folderColor, size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.name,
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: folderColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: folderColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: folderColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'المرحلة: ${folder.grade}',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: folderColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAdmin)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFolderActionButton(
                        icon: Icons.edit,
                        color: Colors.green,
                        onPressed: () => _updateFolder(folder),
                      ),
                      _buildFolderActionButton(
                        icon: Icons.delete,
                        color: Colors.red,
                        onPressed: () => _deleteFolder(folder),
                      ),
                    ],
                  )
                else
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: folderColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: folderColor,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFolderActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 22),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.cairo(
                color: Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: Text("إعادة المحاولة", style: GoogleFonts.cairo()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_off, color: Colors.grey.shade400, size: 80),
            const SizedBox(height: 16),
            Text(
              "لا يوجد مجلدات",
              style: GoogleFonts.cairo(
                color: Colors.grey,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              selectedFilter != 'الكل'
                  ? "لا توجد مجلدات للمرحلة: $selectedFilter"
                  : "لم يتم إضافة أي مجلدات بعد",
              style: GoogleFonts.cairo(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (Provider.of<UserProvider>(context).user?.role.toLowerCase() ==
                'admin') ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FolderUploadScreen(),
                    ),
                  );
                  if (result == true) {
                    setState(() {});
                  }
                },
                icon: const Icon(Icons.add),
                label: Text("إضافة مجلد جديد", style: GoogleFonts.cairo()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F62FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getFolderColor(String grade) {
    switch (grade) {
      case 'الأول':
        return Colors.blue;
      case 'الثاني':
        return Colors.green;
      case 'الثالث':
        return Colors.purple;
      case 'الرابع':
        return Colors.orange;
      case 'الخامس':
        return Colors.pink;
      case 'السادس':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  Align? _buildFloatingActionButton(User? user) {
    return (user != null && user.role.toLowerCase() == 'admin')
        ? Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20.0, right: 30.0),
            child: ScaleTransition(
              scale: _animation,
              child: FloatingActionButton.extended(
                tooltip: 'إضافة مجلد',
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FolderUploadScreen(),
                    ),
                  );
                  if (result == true) {
                    setState(() {});
                  }
                },
                backgroundColor: const Color(0xFF2F62FF),
                icon: const Icon(Icons.add_circle, color: Colors.white),
                label: Text('إضافة مجلد', style: GoogleFonts.cairo()),
              ),
            ),
          ),
        )
        : null;
  }

  /// نقرأ اسم المدرسة والشعار مباشرةً من user
  PreferredSizeWidget _buildAppBar(User user) {
    final schoolName = user.schoolName ?? "جاري التحميل...";
    final schoolLogo = user.logoUrl ?? "";

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
      automaticallyImplyLeading: false,
      title: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // الجهة اليسرى (بالعربية: يمين الشاشة) تضم الشعار واسم المدرسة والترحيب
            Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // شعار المدرسة
                  schoolLogo.isNotEmpty
                      ? Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: NetworkImage(schoolLogo),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                      : const Icon(Icons.school, color: Colors.white, size: 50),
                  const SizedBox(width: 12),
                  // نصوص المدرسة والترحيب
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schoolName,
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "مرحباً ${user.username}",
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // الجهة اليمنى (بالعربية: يسار الشاشة) تضم أزرار الإدارة وتسجيل الخروج
            Row(
              children: [
                if (user.role.toLowerCase() == "admin") ...[
                  IconButton(
                    icon: const Icon(Icons.bar_chart, color: Colors.white),
                    tooltip: "عرض التقارير",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReportsScreen(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.person, color: Colors.white),
                    tooltip: "إدارة المستخدمين",
                    onPressed:
                        () => Navigator.pushNamed(context, "/userManagement"),
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.exit_to_app, color: Colors.white),
                  tooltip: "تسجيل الخروج",
                  onPressed: _logout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
