class User {
  final int? id;
  final String username;
  final String password;
  final String role; // admin / user / teacher
  final String? grade; // المرحلة الدراسية (للمستخدم العادي user)
  final String? subject; // التخصص (للمدرس teacher)
  final int schoolId;
  final String schoolCode;
  final String? schoolName;
  final String? logoUrl;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.role,
    this.grade,
    this.subject,
    required this.schoolId,
    this.schoolCode = "",
    this.schoolName,
    this.logoUrl,
  });

  /// إنشاء كائن User من خريطة (Map)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      password: map['password'] as String,
      role: map['role']?.toString() ?? '',
      grade: map['grade']?.toString(),
      subject: map['subject']?.toString(),
      schoolId: map['schoolId'] as int,
      schoolCode: map['schoolCode'] as String? ?? '',
      schoolName: map['schoolName'] as String?,
      logoUrl: map['logoUrl'] as String?,
    );
  }

  /// تحويل كائن User إلى خريطة
  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
    'password': password,
    'role': role,
    'grade': grade,
    'subject': subject,
    'schoolId': schoolId,
    'schoolCode': schoolCode,
    'schoolName': schoolName,
    'logoUrl': logoUrl,
  };

  /// إنشاء نسخة جديدة مع تعديلات
  User copyWith({
    int? id,
    String? username,
    String? password,
    String? role,
    String? grade,
    String? subject,
    int? schoolId,
    String? schoolCode,
    String? schoolName,
    String? logoUrl,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      grade: grade ?? this.grade,
      subject: subject ?? this.subject,
      schoolId: schoolId ?? this.schoolId,
      schoolCode: schoolCode ?? this.schoolCode,
      schoolName: schoolName ?? this.schoolName,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }
}
