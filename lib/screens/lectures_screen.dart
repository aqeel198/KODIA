import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// استيراد النماذج والخدمات
import 'package:school_platform/models/folder.dart';
import 'package:school_platform/providers/user_provider.dart';
import 'package:school_platform/services/mysql_data_service.dart';

// استيراد الشاشات الأخرى
import 'folder_contents_screen.dart';
import 'folder_upload_screen.dart';

class LecturesScreen extends StatefulWidget {
  const LecturesScreen({super.key});

  @override
  State<LecturesScreen> createState() => _LecturesScreenState();
}

class _LecturesScreenState extends State<LecturesScreen>
    with SingleTickerProviderStateMixin {
  /// خيار المرحلة الدراسية المختارة في الفلترة
  String selectedLectureFilter = 'الكل';

  /// قائمة الخيارات المتاحة
  final List<String> lectureFilterOptions = [
    'الكل',
    'الأول',
    'الثاني',
    'الثالث',
    'الرابع',
    'الخامس',
    'السادس',
  ];

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// جلب المجلدات من قاعدة البيانات
  Future<List<Folder>> _fetchFolders(BuildContext context) async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return [];

    // نجلب جميع المجلدات لهذه المدرسة
    final List<Folder> allFolders = await MySQLDataService.instance
        .getAllFolders(user.schoolId);

    // إن كان المستخدم طالبًا (role = user)، فلترة حسب مرحلته
    if (user.role.toLowerCase() == 'user') {
      return allFolders.where((folder) => folder.grade == user.grade).toList();
    }
    // خلاف ذلك (admin أو teacher)، نعيد المجلدات كلها
    return allFolders;
  }

  /// دالة لتحديد اللون بحسب المرحلة
  Color _getFolderColor(String grade) {
    switch (grade) {
      case 'الأول':
        return const Color(0xFF2196F3); // أزرق
      case 'الثاني':
        return const Color(0xFF4CAF50); // أخضر
      case 'الثالث':
        return const Color(0xFF9C27B0); // بنفسجي
      case 'الرابع':
        return const Color(0xFFFF9800); // برتقالي
      case 'الخامس':
        return const Color(0xFFE91E63); // وردي
      case 'السادس':
        return const Color(0xFF009688); // فيروزي
      default:
        return const Color(0xFF2F62FF); // أزرق غامق
    }
  }

  /// تحديث اسم المجلد
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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "تعديل المجلد",
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "اسم المجلد",
                    labelStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2F62FF),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: GoogleFonts.cairo(),
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
                  decoration: InputDecoration(
                    labelText: "اختر المرحلة",
                    labelStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2F62FF),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: GoogleFonts.cairo(),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        "إلغاء",
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F62FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "حفظ",
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
    );

    if (result != null) {
      try {
        await MySQLDataService.instance.updateFolder(result);
        setState(() {});
        _showSnackBar('تم تعديل المجلد بنجاح');
      } catch (e) {
        _showSnackBar('فشل تعديل المجلد: $e');
      }
    }
  }

  /// حذف المجلد
  Future<void> _deleteFolder(BuildContext context, Folder folder) async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return;

    // تأكيد الحذف
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red[700],
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'تأكيد الحذف',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'هل أنت متأكد من حذف "${folder.name}"؟',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'إلغاء',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'حذف',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
    );

    // إذا وافق المستخدم
    if (confirm == true) {
      try {
        // تمرير معرف المجلد ومعرف المدرسة
        final int deleteResult = await MySQLDataService.instance.deleteFolder(
          folder.id!,
          user.schoolId,
        );

        if (deleteResult > 0) {
          setState(() {});
          _showSnackBar('تم حذف المجلد بنجاح');
        } else {
          _showSnackBar('فشل حذف المجلد');
        }
      } catch (e) {
        _showSnackBar('حدث خطأ أثناء الحذف: $e');
      }
    }
  }

  /// ويدجت الخطأ عند الفشل في جلب البيانات
  Widget _buildErrorWidget(String message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red[700], size: 64),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.cairo(
                color: Colors.red[700],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded),
              label: Text("إعادة المحاولة", style: GoogleFonts.cairo()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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

  /// ويدجت عند عدم وجود أية مجلدات
  Widget _buildEmptyWidget(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final bool canManage =
        user != null &&
        (user.role.toLowerCase() == 'admin' ||
            user.role.toLowerCase() == 'teacher');

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_off_rounded,
                color: Colors.grey[400],
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "لا يوجد مجلدات",
              style: GoogleFonts.cairo(
                color: const Color(0xFF333333),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "لم يتم إضافة أي مجلدات بعد",
              style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (canManage) ...[
              const SizedBox(height: 32),
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
                icon: const Icon(Icons.add_rounded),
                label: Text("إضافة مجلد جديد", style: GoogleFonts.cairo()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F62FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
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

  /// تصميم القائمة مع الأنميشن
  Widget _buildFolderList(List<Folder> folders, user) {
    final bool canManage =
        (user.role.toLowerCase() == 'admin' ||
            user.role.toLowerCase() == 'teacher');

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: folders.length,
        itemBuilder: (context, index) {
          final folder = folders[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _getFolderColor(folder.grade).withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => FolderContentsScreen(folder: folder),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // أيقونة المجلد
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: _getFolderColor(
                                  folder.grade,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.folder_rounded,
                                color: _getFolderColor(folder.grade),
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // معلومات المجلد
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    folder.name,
                                    style: GoogleFonts.cairo(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF333333),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getFolderColor(
                                        folder.grade,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'المرحلة: ${folder.grade}',
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        color: _getFolderColor(folder.grade),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // أزرار التعديل والحذف إذا كان بإمكان المستخدم الإدارة
                            if (canManage)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildFolderActionButton(
                                    icon: Icons.edit_rounded,
                                    color: Colors.green[600]!,
                                    onPressed: () => _updateFolder(folder),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFolderActionButton(
                                    icon: Icons.delete_rounded,
                                    color: Colors.red[600]!,
                                    onPressed:
                                        () => _deleteFolder(context, folder),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// زر صغير (أيقونة التعديل أو الحذف)
  Widget _buildFolderActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }

  /// لعرض رسالة سريعة SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final bool canManage =
        user != null &&
        (user.role.toLowerCase() == 'admin' ||
            user.role.toLowerCase() == 'teacher');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'المحاضرات',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF2F62FF),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        /// هنا نضيف خاصية `floatingActionButtonLocation` لجعل الزر على اليمين (في RTL)
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,

        body: Column(
          children: [
            // قسم الفلترة يظهر فقط للإدمن والمدرس
            if (canManage)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "فلترة حسب المرحلة",
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedLectureFilter,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF2F62FF),
                          ),
                          isExpanded: true,
                          items:
                              lectureFilterOptions.map((level) {
                                return DropdownMenuItem<String>(
                                  value: level,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      level,
                                      style: GoogleFonts.cairo(
                                        fontSize: 16,
                                        color: const Color(0xFF333333),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedLectureFilter = value;
                              });
                            }
                          },
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF333333),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // عرض المجلدات
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => setState(() {}),
                color: const Color(0xFF2F62FF),
                child: FutureBuilder<List<Folder>>(
                  future: _fetchFolders(context),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        snapshot.data == null) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2F62FF),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return _buildErrorWidget('خطأ: ${snapshot.error}');
                    }

                    final allFolders = snapshot.data ?? [];
                    // تطبيق فلترة المرحلة (تنطبق على الإدمن والمدرس فقط)
                    final filteredFolders =
                        (canManage && selectedLectureFilter != 'الكل')
                            ? allFolders
                                .where(
                                  (folder) =>
                                      folder.grade == selectedLectureFilter,
                                )
                                .toList()
                            : allFolders;

                    if (filteredFolders.isEmpty) {
                      return _buildEmptyWidget(context);
                    }
                    return _buildFolderList(filteredFolders, user!);
                  },
                ),
              ),
            ),
          ],
        ),

        // زر إضافة المجلد يظهر فقط للإدمن والمدرس
        floatingActionButton:
            canManage
                ? ScaleTransition(
                  scale: _animationController,
                  child: FloatingActionButton.extended(
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
                    icon: const Icon(Icons.add_rounded),
                    label: Text(
                      "إضافة مجلد",
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                    elevation: 4,
                  ),
                )
                : null,
      ),
    );
  }
}
