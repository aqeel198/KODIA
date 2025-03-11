import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/folder_upload_screen.dart';
import 'screens/lectures_screen.dart'; // شاشة المحاضرات
import 'screens/assignments_screen.dart'; // شاشة الواجبات
import 'utils/theme.dart';
import 'services/secure_storage_service.dart';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("Current Directory: ${Directory.current.path}");

  // تحميل متغيرات البيئة من ملف .env الموجود في جذر المشروع
  await dotenv.load(fileName: "assets/env/.env");

  // تنفيذ هذا الكود لمرة واحدة لتخزين كلمة مرور قاعدة البيانات بأمان
  // يُفضل تنفيذه أثناء مرحلة التطوير أو في شاشة إعدادات خاصة بالأدمن،
  // وبعد التأكد من تخزين البيانات، قم بإزالة هذا السطر.
  await SecureStorageService.write('DB_PASSWORD', 'ASDdsaWSS22');

  // إنشاء مزود المستخدم وتحميل بيانات المستخدم المُحفوظة إن وُجدت
  final userProvider = UserProvider();
  await userProvider.loadUser();

  runApp(
    ChangeNotifierProvider<UserProvider>.value(
      value: userProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        return MaterialApp(
          title: 'ITQAN-إتقان',
          debugShowCheckedModeBanner: false,
          theme:
              userProvider.user != null
                  ? MyTheme.getTheme(userProvider.user!.role)
                  : MyTheme.loginTheme,
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
            '/userManagement': (context) => const UserManagementScreen(),
            '/folderUpload': (context) => const FolderUploadScreen(),
            '/lectures':
                (context) => const LecturesScreen(), // مسار شاشة المحاضرات
            '/assignments':
                (context) => const AssignmentsScreen(), // مسار شاشة الواجبات
          },
          onGenerateRoute: (settings) {
            // يمكن هنا التقاط المسارات غير المعروفة وتمرير الـ arguments إذا لزم الأمر
            return null;
          },
        );
      },
    );
  }
}
