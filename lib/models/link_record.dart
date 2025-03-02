class LinkRecord {
  final int? id;
  final String title; // اسم الرابط
  final String url;
  final int folderId;
  final int userId;
  final int schoolId; // حقل جديد لربط الرابط بالمدرسة

  LinkRecord({
    this.id,
    required this.title,
    required this.url,
    required this.folderId,
    required this.userId,
    required this.schoolId,
  });

  /// تحويل صف قاعدة البيانات (Map) إلى كائن LinkRecord
  factory LinkRecord.fromMap(Map<String, dynamic> map) {
    // معالجة قيمة url في حال كانت تأتي كـ List<int> أو String
    String urlValue;
    if (map['url'] is String) {
      urlValue = map['url'];
    } else if (map['url'] is List<int>) {
      urlValue = String.fromCharCodes(map['url']);
    } else {
      urlValue = map['url'].toString();
    }

    return LinkRecord(
      id: map['id'] as int?,
      title: map['title'] as String,
      url: urlValue,
      folderId: map['folderId'] as int,
      userId: map['userId'] as int,
      schoolId: map['schoolId'] as int,
    );
  }

  /// تحويل كائن LinkRecord إلى خريطة (Map)
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'url': url,
    'folderId': folderId,
    'userId': userId,
    'schoolId': schoolId,
  };

  /// إتاحة نسخة معدَّلة من هذا الكائن
  LinkRecord copyWith({
    int? id,
    String? title,
    String? url,
    int? folderId,
    int? userId,
    int? schoolId,
  }) {
    return LinkRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      folderId: folderId ?? this.folderId,
      userId: userId ?? this.userId,
      schoolId: schoolId ?? this.schoolId,
    );
  }
}
