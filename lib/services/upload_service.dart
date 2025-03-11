import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'secure_storage_service.dart';

class UploadService {
  /// يسترجع عنوان URL للرفع من التخزين الآمن، وإذا لم يوجد يستخدم متغيرات البيئة أو القيمة الافتراضية.
  static Future<String> _getUploadUrl() async {
    final storedUrl = await SecureStorageService.read('UPLOAD_URL');
    return storedUrl ??
        (dotenv.env['UPLOAD_URL'] ?? "http://xcodeapps.shop/itqan.php");
  }

  /// يسترجع عنوان URL للاستبدال من التخزين الآمن، وإذا لم يوجد يستخدم متغيرات البيئة أو القيمة الافتراضية.
  static Future<String> _getReplaceUrl() async {
    final storedUrl = await SecureStorageService.read('REPLACE_URL');
    return storedUrl ??
        (dotenv.env['REPLACE_URL'] ?? "http://xcodeapps.shop/replace.php");
  }

  /// ترفع ملف PDF إلى سكربت الرفع على الخادم.
  static Future<void> uploadPdfFile({
    required String filePath,
    required String fileName,
    required int folderId,
    required int userId,
    required int schoolId,
  }) async {
    final uploadUrl = await _getUploadUrl();
    final uri = Uri.parse(uploadUrl);
    var request = http.MultipartRequest('POST', uri);

    // إضافة الملف
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    // إضافة الحقول النصية
    request.fields['fileName'] = fileName;
    request.fields['folderId'] = folderId.toString();
    request.fields['userId'] = userId.toString();
    request.fields['schoolId'] = schoolId.toString();

    var response = await request.send();
    var responseBody = await http.Response.fromStream(response);

    print("Response status: ${response.statusCode}");
    print("Response body: ${responseBody.body}");

    if (response.statusCode != 200) {
      throw Exception("فشل الرفع. الحالة: ${response.statusCode}");
    }
  }

  /// يستبدل ملف PDF موجود برفع ملف جديد وحذف الملف السابق عبر سكربت الاستبدال.
  static Future<void> replacePdfFile({
    required String filePath,
    required String fileName,
    required int folderId,
    required int userId,
    required int schoolId,
  }) async {
    final replaceUrl = await _getReplaceUrl();
    final uri = Uri.parse(replaceUrl);
    var request = http.MultipartRequest('POST', uri);

    // إضافة الملف الجديد
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    // إضافة الحقول النصية
    request.fields['fileName'] = fileName;
    request.fields['folderId'] = folderId.toString();
    request.fields['userId'] = userId.toString();
    request.fields['schoolId'] = schoolId.toString();

    var response = await request.send();
    var responseBody = await http.Response.fromStream(response);

    print("Replace Response status: ${response.statusCode}");
    print("Replace Response body: ${responseBody.body}");

    if (response.statusCode != 200) {
      throw Exception("فشل الاستبدال. الحالة: ${response.statusCode}");
    }
  }
}
