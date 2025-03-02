import 'package:flutter/foundation.dart';
import '../models/file_record.dart';

class FilesProvider with ChangeNotifier {
  final List<FileRecord> _files = [];

  /// قائمة الملفات غير قابلة للتعديل مباشرة.
  List<FileRecord> get files => List.unmodifiable(_files);

  /// تعيين قائمة جديدة من الملفات وإعلام المستمعين.
  void setFiles(List<FileRecord> files) {
    _files
      ..clear()
      ..addAll(files);
    notifyListeners();
  }

  /// إضافة ملف جديد إلى القائمة.
  void addFile(FileRecord file) {
    _files.add(file);
    notifyListeners();
  }

  /// تحديث ملف موجود بالمعرف المحدد.
  void updateFile(FileRecord updatedFile) {
    final index = _files.indexWhere((file) => file.id == updatedFile.id);
    if (index != -1) {
      _files[index] = updatedFile;
      notifyListeners();
    }
  }

  /// إزالة الملف بناءً على المعرف.
  void removeFile(int fileId) {
    _files.removeWhere((file) => file.id == fileId);
    notifyListeners();
  }
}
