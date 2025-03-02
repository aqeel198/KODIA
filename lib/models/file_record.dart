class FileRecord {
  final int? id;
  final String fileName;
  final String filePath;
  final int folderId;
  final int userId;
  final int schoolId; // حقل جديد لربط الملف بالمدرسة

  FileRecord({
    this.id,
    required this.fileName,
    required this.filePath,
    required this.folderId,
    required this.userId,
    required this.schoolId,
  });

  factory FileRecord.fromMap(Map<String, dynamic> map) {
    String pathValue;
    if (map['filePath'] is String) {
      pathValue = map['filePath'];
    } else if (map['filePath'] is List<int>) {
      pathValue = String.fromCharCodes(map['filePath']);
    } else {
      pathValue = map['filePath']?.toString() ?? '';
    }

    return FileRecord(
      id: map['id'] as int?,
      fileName: map['fileName'] as String,
      filePath: pathValue,
      folderId: map['folderId'] as int,
      userId: map['userId'] as int,
      schoolId:
          map['schoolId'] as int, // تأكد من أن عمود schoolId موجود في الاستعلام
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'fileName': fileName,
    'filePath': filePath,
    'folderId': folderId,
    'userId': userId,
    'schoolId': schoolId,
  };

  FileRecord copyWith({
    int? id,
    String? fileName,
    String? filePath,
    int? folderId,
    int? userId,
    int? schoolId,
  }) {
    return FileRecord(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      folderId: folderId ?? this.folderId,
      userId: userId ?? this.userId,
      schoolId: schoolId ?? this.schoolId,
    );
  }
}
