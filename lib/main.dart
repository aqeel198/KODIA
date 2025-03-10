import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/folder_upload_screen.dart';
import 'screens/lectures_screen.dart'; // إضافة شاشة المحاضرات
import 'screens/assignments_screen.dart'; // إضافة شاشة الواجبات
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final userProvider = UserProvider();
  await userProvider.loadUser(); // تحميل بيانات المستخدم المُحفوظة إن وُجدت
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
          title: 'ITQAN-إتقان"',
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
