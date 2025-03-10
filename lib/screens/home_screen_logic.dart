import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:school_platform/models/folder.dart';
import 'package:school_platform/models/user.dart';
import 'package:school_platform/providers/user_provider.dart';
import 'package:school_platform/services/mysql_data_service.dart';

class HomeScreenLogic {
  /// للتخزين الآمن (تسجيل الخروج)
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  /// جلب عدد الأيام المتبقية على الاشتراك
  Future<int?> fetchDaysLeftForSubscription(BuildContext context) async {
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
  Future<List<Folder>> fetchFolders(BuildContext context) async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return [];

    List<Folder> allFolders = await MySQLDataService.instance.getAllFolders(
      user.schoolId,
    );

    // فلترة حسب دور المستخدم
    final String role = user.role.toLowerCase();
    if (role == 'user') {
      // الطالب يرى فقط المجلدات التي توافق مرحلته
      return allFolders.where((folder) => folder.grade == user.grade).toList();
    } else if (role == 'admin') {
      // الإدمن يرى الكل (يمكنه فلترة لاحقًا إن أراد)
      return allFolders;
    } else if (role == 'teacher') {
      // المعلم يرى الكل
      return allFolders;
    }
    return allFolders;
  }

  /// تسجيل الخروج
  Future<void> logout(BuildContext context) async {
    bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (ctx) {
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
                          onPressed: () => Navigator.pop(ctx, true),
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
                          onPressed: () => Navigator.pop(ctx, false),
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
      await secureStorage.delete(key: 'username');
      await secureStorage.delete(key: 'password');
      await secureStorage.delete(key: 'schoolCode');

      Provider.of<UserProvider>(context, listen: false).setUser(null);
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  /// تعديل المجلد
  Future<void> updateFolder(
    BuildContext context,
    Folder folder,
    VoidCallback onSuccess,
  ) async {
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
      builder: (ctx) {
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
              onPressed: () => Navigator.pop(ctx),
              child: Text("إلغاء", style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedFolder = Folder(
                  id: folder.id,
                  name: nameController.text.trim(),
                  grade: selectedGrade,
                  schoolId: folder.schoolId,
                  userId: folder.userId,
                );
                Navigator.pop(ctx, updatedFolder);
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
        onSuccess(); // استدعاء setState() من الخارج
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تعديل المجلد: $e', style: GoogleFonts.cairo()),
          ),
        );
      }
    }
  }

  /// حذف المجلد
  Future<void> deleteFolder(
    BuildContext context,
    Folder folder,
    VoidCallback onSuccess,
  ) async {
    try {
      bool confirm =
          await showDialog<bool>(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: Text("حذف المجلد", style: GoogleFonts.cairo()),
                content: Text(
                  "هل أنت متأكد من حذف هذا المجلد؟",
                  style: GoogleFonts.cairo(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text("إلغاء", style: GoogleFonts.cairo()),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
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
        onSuccess(); // استدعاء setState() من الخارج
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل حذف المجلد: $e', style: GoogleFonts.cairo()),
        ),
      );
    }
  }
}
