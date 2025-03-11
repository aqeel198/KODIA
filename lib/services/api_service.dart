import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'secure_storage_service.dart';

class ApiService {
  /// يسترجع عنوان الـ Base URL الخاص بالخدمة من التخزين الآمن،
  /// وإذا لم يوجد يستخدم متغيرات البيئة أو القيمة الافتراضية.
  /// يسترجع عنوان الـ Base URL الخاص بالخدمة من التخزين الآمن،
  /// وإذا لم يوجد يستخدم متغيرات البيئة أو القيمة الافتراضية.
  static Future<String> _getBaseUrl() async {
    final storedUrl = await SecureStorageService.read('SCHOOL_SERVICE_URL');
    return storedUrl ??
        (dotenv.env['SCHOOL_SERVICE_URL'] ?? "http://xcodeapps.shop/service");
  }

  /// دالة لاسترجاع بيانات المدرسة (الاسم ورابط الشعار)
  /// بناءً على رمز المدرسة (schoolCode).
  static Future<Map<String, dynamic>> fetchSchoolDetails(
    String schoolCode,
  ) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse(
      '$baseUrl/getSchoolDetails.php?school_code=$schoolCode',
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
