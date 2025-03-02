import '../models/user.dart';
import '../models/folder.dart';
import '../models/file_record.dart';
import '../models/link_record.dart';

abstract class DataService {
  // عمليات المستخدم
  Future<int> registerUser(User user);
  Future<User?> loginUser(String username, String password, String schoolCode);
  Future<List<User>> getAllUsers(int schoolId);
  Future<int> updateUser(User user);
  Future<int> deleteUser(int id, int schoolId);

  // عمليات المجلدات
  Future<int> addFolder(Folder folder);
  Future<int> updateFolder(Folder folder);
  Future<int> deleteFolder(int id, int schoolId);
  Future<List<Folder>> getAllFolders(int schoolId);

  // عمليات الملفات
  Future<int> uploadFile(FileRecord file);
  Future<int> updateFile(FileRecord file);
  Future<int> deleteFile(int id, int schoolId);
  Future<List<FileRecord>> getFilesByFolder(int folderId, int schoolId);

  // عمليات الروابط
  Future<int> uploadLink(LinkRecord link);
  Future<int> updateLink(LinkRecord link);
  Future<int> deleteLink(int id, int schoolId);
  Future<List<LinkRecord>> getLinksByFolder(int folderId, int schoolId);
}
