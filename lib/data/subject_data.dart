// lib/data/subject_data.dart
class SubjectData {
  // إنشاء مثيل وحيد (Singleton)
  static final SubjectData _instance = SubjectData._internal();
  factory SubjectData() => _instance;
  SubjectData._internal();

  // قائمة المواد المُضافة يدويًا (تبدأ فارغة ويمكن تعديلها)
  List<String> teacherSubjects = [];

  /// إضافة مادة جديدة إذا لم تكن موجودة بالفعل
  void addSubject(String subject) {
    subject = subject.trim();
    if (subject.isNotEmpty && !teacherSubjects.contains(subject)) {
      teacherSubjects.add(subject);
    }
  }

  /// استرجاع القائمة الحالية للمواد
  List<String> getSubjects() => teacherSubjects;
}
