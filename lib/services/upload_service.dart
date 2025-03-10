import 'package:http/http.dart' as http;

class UploadService {
  /// ترفع ملف PDF إلى سكربت upload.php على الخادم.
  static Future<void> uploadPdfFile({
    required String filePath,
    required String fileName,
    required int folderId,
    required int userId,
    required int schoolId,
  }) async {
    final uri = Uri.parse("http://xcodeapps.shop/itqan.php");
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

  /// يستبدل ملف PDF موجود برفع ملف جديد وحذف الملف السابق عبر سكربت replace.php.
  static Future<void> replacePdfFile({
    required String filePath,
    required String fileName,
    required int folderId,
    required int userId,
    required int schoolId,
  }) async {
    final uri = Uri.parse("http://xcodeapps.shop/replace.php");
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
