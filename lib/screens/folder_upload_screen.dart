import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/folder.dart';
import '../providers/user_provider.dart';
import '../services/mysql_data_service.dart';
import 'package:google_fonts/google_fonts.dart';

class FolderUploadScreen extends StatefulWidget {
  const FolderUploadScreen({super.key});

  @override
  _FolderUploadScreenState createState() => _FolderUploadScreenState();
}

class _FolderUploadScreenState extends State<FolderUploadScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _folderNameController = TextEditingController();
  String folderGrade = 'الأول';
  bool _loading = false;

  final List<String> educationLevels = [
    'الأول',
    'الثاني',
    'الثالث',
    'الرابع',
    'الخامس',
    'السادس',
  ];

  late AnimationController _buttonController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _folderNameController.dispose();
    super.dispose();
  }

  Future<void> _uploadFolder() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);
      final currentUser =
          Provider.of<UserProvider>(context, listen: false).user;

      if (currentUser == null) {
        _showSnackBar('خطأ: لم يتم العثور على معلومات المستخدم', Colors.red);
        setState(() => _loading = false);
        return;
      }

      // إضافة schoolId للمجلد الجديد
      Folder newFolder = Folder(
        name: _folderNameController.text.trim(),
        userId: currentUser.id!,
        grade: folderGrade,
        schoolId: currentUser.schoolId, // تمرير schoolId هنا
      );

      try {
        await MySQLDataService.instance.addFolder(newFolder);
        _showSnackBar('تم إضافة المجلد بنجاح', Colors.green);
        Navigator.pop(context, true);
      } catch (e) {
        _showSnackBar('حدث خطأ أثناء إضافة المجلد: $e', Colors.red);
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: _buildAppBar(),
        body:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(),
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
      title: Text(
        'إضافة مجلد',
        style: GoogleFonts.cairo(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    return Center(
      child: SingleChildScrollView(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(24.0),
          margin: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3FA9F5), Color(0xFF2F62FF)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Card(
            color: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'أدخل بيانات المجلد',
                      style: GoogleFonts.cairo(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildFolderNameField(),
                    const SizedBox(height: 16),
                    _buildGradeDropdown(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFolderNameField() {
    return Tooltip(
      message: 'أدخل اسم المجلد الذي تود إضافته',
      child: TextFormField(
        controller: _folderNameController,
        decoration: InputDecoration(
          labelText: 'اسم المجلد',
          labelStyle: GoogleFonts.cairo(fontSize: 18),
          prefixIcon: const Icon(Icons.folder, color: Colors.blue),
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
        validator:
            (val) =>
                (val == null || val.trim().isEmpty) ? 'أدخل اسم المجلد' : null,
        style: GoogleFonts.cairo(),
      ),
    );
  }

  Widget _buildGradeDropdown() {
    return Tooltip(
      message: 'اختر المرحلة الدراسية للمجلد',
      child: DropdownButtonFormField<String>(
        value: folderGrade,
        items:
            educationLevels.map((level) {
              return DropdownMenuItem(
                value: level,
                child: Text(
                  level,
                  style: GoogleFonts.cairo(fontSize: 18, color: Colors.black),
                ),
              );
            }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => folderGrade = value);
          }
        },
        decoration: InputDecoration(
          labelText: 'المرحلة الدراسية للمجلد',
          labelStyle: GoogleFonts.cairo(fontSize: 18),
          prefixIcon: const Icon(Icons.school, color: Colors.blue),
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
        style: GoogleFonts.cairo(),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return MouseRegion(
      onEnter: (_) => _buttonController.forward(),
      onExit: (_) => _buttonController.reverse(),
      child: ScaleTransition(
        scale: _buttonScaleAnimation,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
          ),
          onPressed: _uploadFolder,
          child: Text(
            'إضافة المجلد',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
