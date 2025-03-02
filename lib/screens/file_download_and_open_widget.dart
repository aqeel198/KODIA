import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:google_fonts/google_fonts.dart';

class FileDownloadAndOpenWidget extends StatefulWidget {
  /// عنوان URL الأساسي للملف على السيرفر (بدون معلمات)
  final String fileUrl;

  /// اسم الملف مع الامتداد كما تريد حفظه على الجهاز، مثال: "yourfile.pdf"
  final String fileName;

  /// معرّف المدرسة (schoolId) لتحميل الملف الخاص بمدرستك
  final int schoolId;

  const FileDownloadAndOpenWidget({
    super.key,
    required this.fileUrl,
    required this.fileName,
    required this.schoolId,
  });

  @override
  _FileDownloadAndOpenWidgetState createState() =>
      _FileDownloadAndOpenWidgetState();
}

class _FileDownloadAndOpenWidgetState extends State<FileDownloadAndOpenWidget> {
  bool _downloading = false;
  double _progress = 0.0;
  String? _localFilePath;

  /// دالة لتحميل الملف باستخدام Dio وحفظه في دليل التطبيق
  Future<void> _downloadFile() async {
    setState(() {
      _downloading = true;
      _progress = 0.0;
    });
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/${widget.fileName}";

      Dio dio = Dio();
      // تضمين schoolId كمعامل (query parameter) في URL التحميل لضمان عزل بيانات المدرسة
      final downloadUrl = "${widget.fileUrl}?schoolId=${widget.schoolId}";
      await dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
            });
          }
        },
      );

      setState(() {
        _localFilePath = filePath;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("تم تنزيل الملف بنجاح", style: GoogleFonts.cairo()),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "حدث خطأ أثناء التحميل: $e",
            style: GoogleFonts.cairo(),
          ),
        ),
      );
    } finally {
      setState(() {
        _downloading = false;
      });
    }
  }

  /// دالة لفتح الملف باستخدام مكتبة OpenFile
  Future<void> _openFile() async {
    if (_localFilePath != null) {
      final result = await OpenFile.open(_localFilePath!);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("لا يمكن فتح الملف", style: GoogleFonts.cairo()),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "الملف غير موجود. قم بتنزيله أولاً",
            style: GoogleFonts.cairo(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_downloading)
          Column(
            children: [
              CircularProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text(
                "${(_progress * 100).toStringAsFixed(0)}%",
                style: GoogleFonts.cairo(),
              ),
            ],
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: Text("تنزيل الملف", style: GoogleFonts.cairo()),
              onPressed: _downloading ? null : _downloadFile,
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: Text("فتح الملف", style: GoogleFonts.cairo()),
              onPressed: _localFilePath != null ? _openFile : null,
            ),
          ],
        ),
      ],
    );
  }
}
