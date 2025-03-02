class User {
  final int? id;
  final String username;
  final String password;
  final String role; // "admin" أو "user"
  final String? grade; // المرحلة الدراسية (للطلاب)، يمكن أن تكون null للإدمن
  final int schoolId; // معرف المدرسة
  final String schoolCode; // رمز المدرسة

  User({
    this.id,
    required this.username,
    required this.password,
    required this.role,
    this.grade,
    required this.schoolId,
    this.schoolCode = "",
  });

  /// ينشئ كائن User من خريطة (Map)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      password: map['password'] as String,
      role: map['role']?.toString() ?? '',
      grade: map['grade']?.toString(),
      schoolId: map['schoolId'] as int,
      schoolCode: map['schoolCode'] as String? ?? '',
    );
  }

  /// يحول كائن User إلى خريطة (Map)
  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
    'password': password,
    'role': role,
    'grade': grade,
    'schoolId': schoolId,
    'schoolCode': schoolCode,
  };

  /// ينشئ نسخة جديدة من User مع التعديلات المطلوبة
  User copyWith({
    int? id,
    String? username,
    String? password,
    String? role,
    String? grade,
    int? schoolId,
    String? schoolCode,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      grade: grade ?? this.grade,
      schoolId: schoolId ?? this.schoolId,
      schoolCode: schoolCode ?? this.schoolCode,
    );
  }
}
