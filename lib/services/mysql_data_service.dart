import 'package:mysql1/mysql1.dart';
import 'data_service.dart';
import '../models/user.dart';
import '../models/folder.dart';
import '../models/file_record.dart';
import '../models/link_record.dart';

class MySQLDataService implements DataService {
  static final MySQLDataService instance = MySQLDataService._init();
  MySqlConnection? _connection;

  MySQLDataService._init();

  /// إنشاء اتصال بقاعدة البيانات (أو إعادة استخدامه إن كان موجودًا وصالحًا)
  Future<MySqlConnection> get connection async {
    if (_connection != null) {
      try {
        await _connection!.query("SELECT 1");
        return _connection!;
      } catch (e) {
        print("⚠️ الاتصال غير صالح أو مغلق، سيتم إعادة الاتصال: $e");
        await closeConnection();
      }
    }
    try {
      final settings = ConnectionSettings(
        host: 'sxb1plzcpnl508429.prod.sxb1.secureserver.net',
        port: 3306,
        user: 'admin',
        password: 'ASDdsaWSS22',
        db: 'almnsaDB',
      );

      _connection = await MySqlConnection.connect(settings);
      print("✅ تم الاتصال بقاعدة البيانات بنجاح!");

      // ضبط الترميز لضمان تخزين النصوص العربية بشكل صحيح
      await _connection!.query("SET NAMES 'utf8mb4'");
      await _connection!.query("SET CHARACTER SET utf8mb4");
      await _connection!.query("SET character_set_connection=utf8mb4");

      return _connection!;
    } catch (e) {
      print("❌ فشل الاتصال بقاعدة البيانات: $e");
      rethrow;
    }
  }

  /// إغلاق الاتصال عند الحاجة
  Future<void> closeConnection() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
      print("🔌 تم إغلاق الاتصال بقاعدة البيانات.");
    }
  }

  // ----------------------------
  //         تسجيل الدخول
  // ----------------------------
  @override
  Future<User?> loginUser(
    String username,
    String password,
    String schoolCode,
  ) async {
    final conn = await connection;
    try {
      // استعلام يجلب بيانات المستخدم مع تاريخ انتهاء الاشتراك الخاص بالمدرسة
      var results = await conn.query(
        '''
        SELECT u.*, s.subscription_end 
        FROM users u 
        JOIN schools s ON u.schoolId = s.id 
        WHERE u.username = ? 
          AND u.password = ? 
          AND s.school_code = ?
        ''',
        [username, password, schoolCode],
      );

      if (results.isNotEmpty) {
        var row = results.first;
        // الحصول على تاريخ انتهاء الاشتراك وتحويله إلى DateTime
        DateTime subscriptionEnd;
        if (row.fields['subscription_end'] is DateTime) {
          subscriptionEnd = row.fields['subscription_end'];
        } else {
          subscriptionEnd = DateTime.parse(
            row.fields['subscription_end'].toString(),
          );
        }
        // التحقق من انتهاء الاشتراك: إذا كان تاريخ الاشتراك أقل من تاريخ اليوم، نرفع استثناء
        if (subscriptionEnd.isBefore(DateTime.now())) {
          throw Exception("اشتراك المنصة منتهي. يجب تجديد الاشتراك.");
        }
        return User.fromMap(row.fields);
      }
      return null;
    } catch (e) {
      print("❌ خطأ في loginUser: $e");
      rethrow;
    }
  }

  /// جلب تاريخ انتهاء الاشتراك (subscription_end) ككائن DateTime
  Future<DateTime?> getSubscriptionEndDate(int schoolId) async {
    final conn = await connection;
    try {
      var results = await conn.query(
        'SELECT subscription_end FROM schools WHERE id = ?',
        [schoolId],
      );
      if (results.isNotEmpty) {
        final row = results.first.fields;
        final subEnd = row['subscription_end'];
        if (subEnd is DateTime) {
          return subEnd;
        } else if (subEnd is String) {
          return DateTime.parse(subEnd);
        }
      }
      return null;
    } catch (e) {
      print("❌ خطأ في getSubscriptionEndDate: $e");
      rethrow;
    }
  }

  @override
  Future<int> registerUser(User user) async {
    final conn = await connection;
    // التحقق من عدم تكرار اسم المستخدم لنفس المدرسة
    var results = await conn.query(
      'SELECT COUNT(*) AS count FROM users WHERE username = ? AND schoolId = ?',
      [user.username, user.schoolId],
    );
    int count = results.first.fields['count'] as int;
    if (count > 0) {
      throw Exception('Duplicate entry');
    }

    try {
      var result = await conn.query(
        'INSERT INTO users (username, password, role, grade, schoolId) VALUES (?, ?, ?, ?, ?)',
        [user.username, user.password, user.role, user.grade, user.schoolId],
      );
      return result.insertId!;
    } catch (e) {
      print("❌ خطأ في registerUser: $e");
      rethrow;
    }
  }

  @override
  Future<List<User>> getAllUsers(int schoolId) async {
    final conn = await connection;
    try {
      var results = await conn.query('SELECT * FROM users WHERE schoolId = ?', [
        schoolId,
      ]);
      return results.map((row) => User.fromMap(row.fields)).toList();
    } catch (e) {
      print("❌ خطأ في getAllUsers: $e");
      rethrow;
    }
  }

  @override
  Future<int> updateUser(User user) async {
    final conn = await connection;
    try {
      var result = await conn.query(
        'UPDATE users SET username = ?, password = ?, role = ?, grade = ? WHERE id = ? AND schoolId = ?',
        [
          user.username,
          user.password,
          user.role,
          user.grade,
          user.id,
          user.schoolId,
        ],
      );
      return result.affectedRows!;
    } catch (e) {
      print("❌ خطأ في updateUser: $e");
      rethrow;
    }
  }

  @override
  Future<int> deleteUser(int id, int schoolId) async {
    final conn = await connection;
    try {
      var result = await conn.query(
        'DELETE FROM users WHERE id = ? AND schoolId = ?',
        [id, schoolId],
      );
      return result.affectedRows!;
    } catch (e) {
      print("❌ خطأ في deleteUser: $e");
      rethrow;
    }
  }

  // ----------------------------
  //         المجلدات
  // ----------------------------
  @override
  Future<int> addFolder(Folder folder) async {
    final conn = await connection;
    try {
      var result = await conn.query(
        'INSERT INTO folders (name, userId, grade, schoolId) VALUES (?, ?, ?, ?)',
        [folder.name, folder.userId, folder.grade, folder.schoolId],
      );
      return result.insertId!;
    } catch (e) {
      print("❌ خطأ في addFolder: $e");
      rethrow;
    }
  }

  @override
  Future<int> updateFolder(Folder folder) async {
    final conn = await connection;
    try {
      var result = await conn.query(
        'UPDATE folders SET name = ?, userId = ?, grade = ? WHERE id = ? AND schoolId = ?',
        [folder.name, folder.userId, folder.grade, folder.id, folder.schoolId],
      );
      return result.affectedRows!;
    } catch (e) {
      print("❌ خطأ في updateFolder: $e");
      rethrow;
    }
  }

  @override
  Future<int> deleteFolder(int id, int schoolId) async {
    final conn = await connection;
    try {
      var result = await conn.query(
        'DELETE FROM folders WHERE id = ? AND schoolId = ?',
        [id, schoolId],
      );
      return result.affectedRows!;
    } catch (e) {
      print("❌ خطأ في deleteFolder: $e");
      rethrow;
    }
  }

  @override
  Future<List<Folder>> getAllFolders(int schoolId) async {
    final conn = await connection;
    try {
      var results = await conn.query(
        'SELECT * FROM folders WHERE schoolId = ?',
        [schoolId],
      );
      return results.map((row) => Folder.fromMap(row.fields)).toList();
    } catch (e) {
      print("❌ خطأ في getAllFolders: $e");
      rethrow;
    }
  }

  // ----------------------------
  //         الملفات
  // ----------------------------
  @override
  Future<int> uploadFile(FileRecord file) async {
    final conn = await connection;
    try {
      print(
        "🚀 رفع الملف: fileName=${file.fileName}, filePath=${file.filePath}, folderId=${file.folderId}, userId=${file.userId}, schoolId=${file.schoolId}",
      );
      var result = await conn.query(
        'INSERT INTO files (fileName, filePath, folderId, userId, schoolId) VALUES (?, ?, ?, ?, ?)',
        [
          file.fileName,
          file.filePath,
          file.folderId,
          file.userId,
          file.schoolId,
        ],
      );
      print("✅ تم إدخال الملف في قاعدة البيانات برقم: ${result.insertId}");
      return result.insertId!;
    } catch (e) {
      print("❌ خطأ في uploadFile: $e");
      rethrow;
    }
  }

  @override
  Future<int> updateFile(FileRecord file) async {
    final conn = await connection;
    try {
      var result = await conn.query(
        'UPDATE files SET fileName = ?, filePath = ?, folderId = ?, userId = ? WHERE id = ? AND schoolId = ?',
        [
          file.fileName,
          file.filePath,
          file.folderId,
          file.userId,
          file.id,
          file.schoolId,
        ],
      );
      return result.affectedRows!;
    } catch (e) {
      print("❌ خطأ في updateFile: $e");
      rethrow;
    }
  }

  @override
  Future<int> deleteFile(int id, int schoolId) async {
    final conn = await connection;
    try {
      var result = await conn.query(
        'DELETE FROM files WHERE id = ? AND schoolId = ?',
        [id, schoolId],
      );
      return result.affectedRows!;
    } catch (e) {
      print("❌ خطأ في deleteFile: $e");
      rethrow;
    }
  }

  @override
  Future<List<FileRecord>> getFilesByFolder(int folderId, int schoolId) async {
    final conn = await connection;
    try {
      var results = await conn.query(
        'SELECT * FROM files WHERE folderId = ? AND schoolId = ?',
        [folderId, schoolId],
      );
      var files = results.map((row) => FileRecord.fromMap(row.fields)).toList();
      print(
        "✅ تم جلب ${files.length} ملف/ملفات من المجلد رقم $folderId في المدرسة رقم $schoolId",
      );
      return files;
    } catch (e) {
      print("❌ خطأ في getFilesByFolder: $e");
      rethrow;
    }
  }

  // ----------------------------
  //         الروابط
  // ----------------------------
  @override
  Future<int> uploadLink(LinkRecord link) async {
    final conn = await connection;
    try {
      var result = await conn.query(
        'INSERT INTO links (title, url, folderId, userId, schoolId) VALUES (?, ?, ?, ?, ?)',
        [link.title, link.url, link.folderId, link.userId, link.schoolId],
      );
      return result.insertId!;
    } catch (e) {
      print("❌ خطأ في uploadLink: $e");
      rethrow;
    }
  }

  @override
  Future<int> updateLink(LinkRecord link) async {
    final conn = await connection;
    try {
      var result = await conn.query(
        'UPDATE links SET title = ?, url = ?, folderId = ?, userId = ? WHERE id = ? AND schoolId = ?',
        [
          link.title,
          link.url,
          link.folderId,
          link.userId,
          link.id,
          link.schoolId,
        ],
      );
      return result.affectedRows!;
    } catch (e) {
      print("❌ خطأ في updateLink: $e");
      rethrow;
    }
  }

  @override
  Future<int> deleteLink(int id, int schoolId) async {
    final conn = await connection;
    try {
      var result = await conn.query(
        'DELETE FROM links WHERE id = ? AND schoolId = ?',
        [id, schoolId],
      );
      return result.affectedRows!;
    } catch (e) {
      print("❌ خطأ في deleteLink: $e");
      rethrow;
    }
  }

  @override
  Future<List<LinkRecord>> getLinksByFolder(int folderId, int schoolId) async {
    final conn = await connection;
    try {
      var results = await conn.query(
        'SELECT * FROM links WHERE folderId = ? AND schoolId = ?',
        [folderId, schoolId],
      );
      return results.map((row) => LinkRecord.fromMap(row.fields)).toList();
    } catch (e) {
      print("❌ خطأ في getLinksByFolder: $e");
      rethrow;
    }
  }

  // ----------------------------
  //         تجديد الاشتراك (من جانب السيرفر)
  // ----------------------------
  Future<bool> renewSubscription(int schoolId, int days) async {
    final conn = await connection;
    try {
      var result = await conn.query(
        '''
        UPDATE schools 
        SET subscription_end = DATE_ADD(subscription_end, INTERVAL ? DAY) 
        WHERE id = ?
        ''',
        [days, schoolId],
      );
      return result.affectedRows! > 0;
    } catch (e) {
      print("❌ خطأ في renewSubscription: $e");
      return false;
    }
  }
}
