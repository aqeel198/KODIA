import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/folder.dart';
import '../providers/user_provider.dart';
import '../services/upload_service.dart';

class FileUploadScreen extends StatefulWidget {
  final Folder folder;
  const FileUploadScreen({super.key, required this.folder});

  @override
  _FileUploadScreenState createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen>
    with SingleTickerProviderStateMixin {
  String fileNameInput = "";
  final bool _loading = false;
  bool _dialogLoading = false;

  // متحكم الأنيميشن لتأثير hover على الزر داخل الحوار
  late AnimationController _buttonController;

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.0,
      upperBound: 0.05,
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _showFileNameInputDialog() async {
    fileNameInput = "";
    _dialogLoading = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "أدخل اسم الملف",
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Padding(
                  // نضيف Padding من الأسفل يساوي المساحة التي يشغلها الكيبورد
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // حقل إدخال اسم الملف
                          TextField(
                            autofocus: true,
                            onChanged: (value) => fileNameInput = value,
                            decoration: InputDecoration(
                              labelText: "اسم الملف",
                              labelStyle: GoogleFonts.cairo(),
                              hintText: "مثال: ملف عربي",
                              hintStyle: GoogleFonts.cairo(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            style: GoogleFonts.cairo(),
                          ),
                          const SizedBox(height: 20),
                          _dialogLoading
                              ? const CircularProgressIndicator()
                              : MouseRegion(
                                onEnter: (_) => _buttonController.forward(),
                                onExit: (_) => _buttonController.reverse(),
                                child: AnimatedBuilder(
                                  animation: _buttonController,
                                  builder: (context, child) {
                                    double scale = 1 + _buttonController.value;
                                    return Transform.scale(
                                      scale: scale,
                                      child: child,
                                    );
                                  },
                                  // نلف الزر داخل SizedBox لتحديد العرض
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.attach_file),
                                      label: Text(
                                        "اختر ملف PDF",
                                        style: GoogleFonts.cairo(),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[700],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                      ),
                                      onPressed: () async {
                                        // التحقق من إدخال اسم الملف
                                        if (fileNameInput.trim().isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "يرجى إدخال اسم الملف قبل اختيار الملف",
                                                style: GoogleFonts.cairo(),
                                              ),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                          return;
                                        }
                                        setStateDialog(() {
                                          _dialogLoading = true;
                                        });
                                        // فتح File Picker لملفات PDF
                                        FilePickerResult? result =
                                            await FilePicker.platform.pickFiles(
                                              type: FileType.custom,
                                              allowedExtensions: ['pdf'],
                                            );
                                        if (result == null ||
                                            result.files.isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "لم يتم اختيار أي ملف",
                                                style: GoogleFonts.cairo(),
                                              ),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                          setStateDialog(() {
                                            _dialogLoading = false;
                                          });
                                          return;
                                        }
                                        final file = result.files.single;
                                        if (file.extension?.toLowerCase() !=
                                            'pdf') {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "يرجى اختيار ملفات PDF فقط",
                                                style: GoogleFonts.cairo(),
                                              ),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                          setStateDialog(() {
                                            _dialogLoading = false;
                                          });
                                          return;
                                        } else if (file.path == null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "خطأ: مسار الملف غير متوفر",
                                                style: GoogleFonts.cairo(),
                                              ),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                          setStateDialog(() {
                                            _dialogLoading = false;
                                          });
                                          return;
                                        }

                                        // الحصول على المستخدم الحالي
                                        final currentUser =
                                            Provider.of<UserProvider>(
                                              context,
                                              listen: false,
                                            ).user;
                                        if (currentUser == null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "خطأ: المستخدم غير موجود",
                                                style: GoogleFonts.cairo(),
                                              ),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                          setStateDialog(() {
                                            _dialogLoading = false;
                                          });
                                          return;
                                        }

                                        try {
                                          // رفع الملف
                                          await UploadService.uploadPdfFile(
                                            filePath: file.path!,
                                            fileName: fileNameInput,
                                            folderId: widget.folder.id!,
                                            userId: currentUser.id!,
                                            schoolId: currentUser.schoolId,
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "تم رفع الملف '$fileNameInput' بنجاح",
                                                style: GoogleFonts.cairo(),
                                              ),
                                              backgroundColor:
                                                  Colors.green[600],
                                            ),
                                          );
                                          Navigator.of(
                                            context,
                                          ).pop(); // إغلاق الحوار
                                          Navigator.pop(
                                            context,
                                            true,
                                          ); // إغلاق الشاشة
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "خطأ في رفع الملف: $e",
                                                style: GoogleFonts.cairo(),
                                              ),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        } finally {
                                          setStateDialog(() {
                                            _dialogLoading = false;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("إلغاء", style: GoogleFonts.cairo()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with blue gradient
      appBar: AppBar(
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
          "رفع ملف",
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child:
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                  icon: const Icon(Icons.file_upload),
                  label: Text("رفع ملف", style: GoogleFonts.cairo()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                  ),
                  onPressed: _showFileNameInputDialog,
                ),
      ),
    );
  }
}
