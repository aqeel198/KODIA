class Folder {
  final int? id;
  final String name;
  final int userId;
  final String grade; // المرحلة الدراسية (كما في الكود الحالي)
  final int schoolId; // حقل جديد لربط المجلد بالمدرسة

  Folder({
    this.id,
    required this.name,
    required this.userId,
    required this.grade,
    required this.schoolId,
  });

  /// يُحوّل بيانات الخريطة (Map) إلى كائن Folder
  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'] as int?,
      name: map['name'] as String,
      userId: map['userId'] as int,
      grade: map['grade']?.toString() ?? '',
      schoolId: map['schoolId'] as int,
    );
  }

  /// يُحوّل كائن Folder إلى Map (خريطة)
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'userId': userId,
    'grade': grade,
    'schoolId': schoolId,
  };

  /// يُنشئ نسخة معدّلة من الكائن مع تغيير الحقول المحددة فقط
  Folder copyWith({
    int? id,
    String? name,
    int? userId,
    String? grade,
    int? schoolId,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      grade: grade ?? this.grade,
      schoolId: schoolId ?? this.schoolId,
    );
  }
}
