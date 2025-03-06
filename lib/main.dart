import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/folder_upload_screen.dart';
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
          title: 'EduNi',
          debugShowCheckedModeBanner: false,
          theme:
              userProvider.user != null
                  ? MyTheme.getTheme(userProvider.user!.role)
                  : MyTheme.loginTheme,
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/home':
                (context) =>
                    const HomeScreen(), // يستقبل HomeScreen الـ arguments من LoginScreen
            '/userManagement': (context) => const UserManagementScreen(),
            '/folderUpload': (context) => const FolderUploadScreen(),
          },
          // onGenerateRoute يمكن استخدامه لالتقاط المسارات غير المعروفة إذا لزم الأمر
          onGenerateRoute: (settings) {
            // مثال: يمكنك التحقق من settings.name وتمرير الـ arguments للصفحات حسب الحاجة
            return null;
          },
        );
      },
    );
  }
}
