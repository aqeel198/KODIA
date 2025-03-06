import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  /// دالة لاسترجاع بيانات المدرسة (الاسم ورابط الشعار)
  /// بناءً على رمز المدرسة (schoolCode).
  static Future<Map<String, dynamic>> fetchSchoolDetails(
    String schoolCode,
  ) async {
    // استبدل المسار أدناه بالمسار الفعلي للملف getSchoolDetails.php على نطاقك
    final url = Uri.parse(
      'http://xcodeapps.shop/service/getSchoolDetails.php?school_code=$schoolCode',
    );

    // إرسال طلب GET إلى الخادم
    final response = await http.get(url);

    // طباعة حالة الاستجابة ومحتواها لتسهيل التصحيح (Debug)
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    // التحقق من حالة الاستجابة
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // في حال رجوع خطأ من الخادم (مثل عدم وجود مدرسة بهذا الرمز)
      if (data.containsKey('error')) {
        throw Exception(data['error']);
      }

      // إذا نجحت العملية وتم استرجاع البيانات بنجاح
      return data; // Map يحتوي على name, logo_url
    } else {
      // إذا لم تكن حالة الاستجابة 200، نرمي استثناء
      throw Exception('فشل استرجاع بيانات المدرسة');
    }
  }
}
