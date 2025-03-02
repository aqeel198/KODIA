import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../models/file_record.dart';
import '../services/mysql_data_service.dart';

class FileDownloadItem extends StatefulWidget {
  final FileRecord file;
  final dynamic user; // تأكد من توافق نوع الـ user حسب تعريفك
  /// callback لإعلام الشاشة الرئيسية بحدوث تعديل (مثلاً بعد حذف أو تعديل الملف)
  final VoidCallback? onFileUpdated;
  const FileDownloadItem({
    super.key,
    required this.file,
    this.user,
    this.onFileUpdated,
  });

  @override
  _FileDownloadItemState createState() => _FileDownloadItemState();
}

class _FileDownloadItemState extends State<FileDownloadItem> {
  bool _downloading = false;
  double _progress = 0.0;
  CancelToken? _cancelToken; // متغير لإلغاء عملية التنزيل

  @override
  void dispose() {
    _cancelToken?.cancel("Widget disposed");
    super.dispose();
  }

  /// بناء المسار المحلي للملف داخل Documents
  Future<String> _getLocalFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = widget.file.filePath.split('/').last;
    return "${dir.path}/$fileName";
  }

  Future<void> _downloadFile() async {
    final localPath = await _getLocalFilePath();
    final fileOnDevice = File(localPath);

    if (await fileOnDevice.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("الملف موجود بالفعل على جهازك")),
        );
      }
      return;
    }

    // تضمين schoolId كمعامل في رابط التنزيل
    final fullUrl =
        "http://xcodeapps.shop/${widget.file.filePath}?schoolId=${widget.file.schoolId}";
    if (mounted) {
      setState(() {
        _downloading = true;
        _progress = 0.0;
      });
    }
    _cancelToken = CancelToken();
    try {
      Dio dio = Dio();
      await dio.download(
        fullUrl,
        localPath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() {
              _progress = received / total;
            });
          }
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("تم تنزيل الملف بنجاح")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("حدث خطأ أثناء التحميل: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
        });
      }
    }
  }

  Future<void> _openFile() async {
    final localPath = await _getLocalFilePath();
    final fileOnDevice = File(localPath);
    if (await fileOnDevice.exists()) {
      final result = await OpenFile.open(localPath);
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("لا يمكن فتح الملف")));
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("الملف غير محمل. يرجى تنزيله أولاً.")),
        );
      }
    }
  }

  Future<void> _deleteFile() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد من حذف هذا الملف؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
    if (confirm) {
      try {
        // إضافة schoolId في بيانات الحذف
        FormData formData = FormData.fromMap({
          'action': 'delete',
          'id': widget.file.id,
          'filePath': widget.file.filePath,
          'schoolId': widget.file.schoolId,
        });
        final response = await Dio().post(
          'https://xcodeapps.shop/almnsa.php',
          data: formData,
        );
        print("Response: ${response.data}");
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("تم حذف الملف")));
        }
        widget.onFileUpdated?.call();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("حدث خطأ أثناء حذف الملف: $e")),
          );
        }
      }
    }
  }

  Future<void> _updateFile() async {
    TextEditingController nameController = TextEditingController(
      text: widget.file.fileName,
    );
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('تعديل الملف'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم الملف'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                try {
                  final updatedFile = widget.file.copyWith(
                    fileName: nameController.text,
                    filePath: widget.file.filePath,
                  );
                  await MySQLDataService.instance.updateFile(updatedFile);
                  Navigator.pop(context);
                  widget.onFileUpdated?.call();
                } catch (e) {
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('حدث خطأ أثناء التعديل: $e')),
                    );
                  }
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _openFile,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
          title: Text(
            widget.file.fileName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle:
              _downloading
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: _progress),
                      const SizedBox(height: 4),
                      Text(
                        "جاري التنزيل... ${(_progress * 100).toStringAsFixed(0)}%",
                      ),
                    ],
                  )
                  : null,
          trailing: FittedBox(
            fit: BoxFit.contain,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.user != null && widget.user.role == 'admin') ...[
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: _updateFile,
                    tooltip: 'تعديل الملف',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _deleteFile,
                    tooltip: 'حذف الملف',
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: _downloading ? null : _downloadFile,
                  tooltip: 'تنزيل الملف',
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: _openFile,
                  tooltip: 'فتح الملف',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
