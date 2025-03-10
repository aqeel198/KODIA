import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:school_platform/models/folder.dart';
import 'package:school_platform/providers/user_provider.dart';
import 'package:school_platform/services/mysql_data_service.dart';
import 'package:school_platform/screens/folder_contents_screen.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  _AssignmentsScreenState createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  /// دالة لجلب المجلدات التي تحتوي على الواجبات
  Future<List<Folder>> _fetchAssignmentFolders() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return [];
    List<Folder> allFolders = await MySQLDataService.instance.getAllFolders(
      user.schoolId,
    );
    // نفترض أن المجلدات التي تحتوي على كلمة "واجب" أو "assignment" تمثل الواجبات
    return allFolders
        .where(
          (folder) =>
              folder.name.toLowerCase().contains("واجب") ||
              folder.name.toLowerCase().contains("assignment"),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text("الواجبات", style: GoogleFonts.cairo()),
          backgroundColor: Colors.green,
        ),
        body: FutureBuilder<List<Folder>>(
          future: _fetchAssignmentFolders(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'حدث خطأ: ${snapshot.error}',
                  style: GoogleFonts.cairo(),
                ),
              );
            }
            final assignments = snapshot.data ?? [];
            if (assignments.isEmpty) {
              return Center(
                child: Text(
                  "لا توجد واجبات",
                  style: GoogleFonts.cairo(fontSize: 18),
                ),
              );
            }
            return ListView.builder(
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final folder = assignments[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Icon(Icons.assignment, color: Colors.green),
                    title: Text(
                      folder.name,
                      style: GoogleFonts.cairo(fontSize: 18),
                    ),
                    subtitle: Text(
                      "المرحلة: ${folder.grade}",
                      style: GoogleFonts.cairo(),
                    ),
                    onTap: () {
                      // الانتقال إلى شاشة محتويات المجلد عند النقر
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => FolderContentsScreen(folder: folder),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
