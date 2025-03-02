import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/mysql_data_service.dart';
import '../providers/user_provider.dart';

/// نموذج بيانات التقارير مع توزيعات إضافية
class ReportData {
  final int totalUsers;
  final int totalAdmins;
  final int totalFolders;
  final int totalFiles;
  final int totalLinks;
  final Map<String, int> userRoleDistribution;
  final Map<String, int> folderGradeDistribution;

  ReportData({
    required this.totalUsers,
    required this.totalAdmins,
    required this.totalFolders,
    required this.totalFiles,
    required this.totalLinks,
    required this.userRoleDistribution,
    required this.folderGradeDistribution,
  });
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<ReportData> _reportDataFuture;
  String selectedCategory = "الكل";
  final List<String> categoryOptions = [
    "الكل",
    "المستخدمون",
    "المجلدات",
    "الملفات",
    "الروابط",
  ];

  @override
  void initState() {
    super.initState();
    _reportDataFuture = _fetchReportData();
  }

  /// دالة جلب بيانات التقارير مع عزل بيانات المدرسة
  Future<ReportData> _fetchReportData() async {
    // الحصول على المستخدم الحالي لجلب schoolId
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;
    if (currentUser == null) {
      throw Exception("المستخدم غير موجود");
    }
    final schoolId = currentUser.schoolId;

    // جلب المستخدمين الخاصين بالمدرسة
    final users = await MySQLDataService.instance.getAllUsers(schoolId);
    int totalUsers = users.length;
    int totalAdmins =
        users.where((user) => user.role.toLowerCase() == 'admin').length;
    Map<String, int> userRoleDistribution = {
      "admin": totalAdmins,
      "user": totalUsers - totalAdmins,
    };

    // جلب المجلدات الخاص بالمؤسسة
    final folders = await MySQLDataService.instance.getAllFolders(schoolId);
    int totalFolders = folders.length;
    Map<String, int> folderGradeDistribution = {
      "الأول": 0,
      "الثاني": 0,
      "الثالث": 0,
      "الرابع": 0,
      "الخامس": 0,
      "السادس": 0,
    };
    for (var folder in folders) {
      if (folderGradeDistribution.containsKey(folder.grade)) {
        folderGradeDistribution[folder.grade] =
            folderGradeDistribution[folder.grade]! + 1;
      }
    }

    // جلب الملفات والروابط الخاصة بالمدرسة
    final conn = await MySQLDataService.instance.connection;
    final fileResults =
        (await conn.query('SELECT * FROM files WHERE schoolId = ?', [
          schoolId,
        ])).toList();
    int totalFiles = fileResults.length;
    final linkResults =
        (await conn.query('SELECT * FROM links WHERE schoolId = ?', [
          schoolId,
        ])).toList();
    int totalLinks = linkResults.length;

    return ReportData(
      totalUsers: totalUsers,
      totalAdmins: totalAdmins,
      totalFolders: totalFolders,
      totalFiles: totalFiles,
      totalLinks: totalLinks,
      userRoleDistribution: userRoleDistribution,
      folderGradeDistribution: folderGradeDistribution,
    );
  }

  Widget _buildUserRolePieChart(Map<String, int> dataMap) {
    List<PieChartSectionData> sections = [];
    final total = dataMap.values.fold(0, (sum, value) => sum + value);
    if (total == 0) {
      sections.add(
        PieChartSectionData(
          value: 1,
          color: Colors.grey.shade400,
          title: "0%",
          radius: 60,
          titleStyle: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    } else {
      dataMap.forEach((key, value) {
        double percentage = (value / total) * 100;
        sections.add(
          PieChartSectionData(
            value: value.toDouble(),
            color:
                key == "admin"
                    ? const Color(0xFF3FA9F5)
                    : const Color(0xFF4CAF50),
            title: "${percentage.toStringAsFixed(1)}%",
            radius: 60,
            titleStyle: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      });
    }
    return Column(
      children: [
        SizedBox(
          height: 320,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 4,
              centerSpaceRadius: 50,
              borderData: FlBorderData(show: false),
              pieTouchData: PieTouchData(enabled: true),
            ),
            swapAnimationDuration: const Duration(milliseconds: 500),
            swapAnimationCurve: Curves.easeInOut,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem("إدمن", const Color(0xFF3FA9F5)),
            const SizedBox(width: 16),
            _buildLegendItem("مستخدم", const Color(0xFF4CAF50)),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildFolderGradeBarChart(Map<String, int> dataMap) {
    List<BarChartGroupData> barGroups = [];
    int index = 0;
    final maxValue =
        dataMap.values.isEmpty
            ? 1
            : dataMap.values.reduce((a, b) => a > b ? a : b);
    dataMap.forEach((grade, count) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: const Color(0xFF2F62FF),
              width: 22,
              borderRadius: BorderRadius.circular(6),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxValue.toDouble() + 2,
                color: Colors.blue.shade100,
              ),
            ),
          ],
        ),
      );
      index++;
    });
    return SizedBox(
      height: 320,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          minY: 1,
          maxY: maxValue.toDouble() + 2,
          barGroups: barGroups,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    value.toInt().toString(),
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  int idx = value.toInt();
                  if (idx < dataMap.keys.length) {
                    String grade = dataMap.keys.elementAt(idx);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        grade,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const Text("");
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true, drawVerticalLine: false),
        ),
        swapAnimationDuration: const Duration(milliseconds: 500),
        swapAnimationCurve: Curves.easeInOut,
      ),
    );
  }

  Widget _buildFilesAndLinksBarChart(ReportData data) {
    List<BarChartGroupData> barGroups = [];
    final values = [data.totalFiles, data.totalLinks];
    final labels = ["الملفات", "الروابط"];
    final colors = [const Color(0xFF9C27B0), const Color(0xFF009688)];
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    for (int i = 0; i < values.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: values[i].toDouble(),
              color: colors[i],
              width: 30,
              borderRadius: BorderRadius.circular(8),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: (maxValue < 1 ? 1 : maxValue).toDouble() + 2,
                color: Colors.grey.shade200,
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      height: 320,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          minY: 1,
          maxY: maxValue.toDouble() + 2,
          barGroups: barGroups,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    value.toInt().toString(),
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  int idx = value.toInt();
                  if (idx < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        labels[idx],
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const Text("");
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true, drawVerticalLine: false),
        ),
        swapAnimationDuration: const Duration(milliseconds: 500),
        swapAnimationCurve: Curves.easeInOut,
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(icon, size: 32, color: const Color(0xFF3FA9F5)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2F62FF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent(ReportData data) {
    TextStyle sectionTitleStyle = GoogleFonts.cairo(
      fontWeight: FontWeight.bold,
      fontSize: 18,
      color: const Color(0xFF2F62FF),
    );
    switch (selectedCategory) {
      case "المستخدمون":
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(
                'إجمالي المستخدمين',
                data.totalUsers.toString(),
                Icons.people,
              ),
              const SizedBox(height: 24),
              Text('توزيع المستخدمين حسب الصلاحية:', style: sectionTitleStyle),
              const SizedBox(height: 16),
              _buildUserRolePieChart(data.userRoleDistribution),
              const SizedBox(height: 24),
            ],
          ),
        );
      case "المجلدات":
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(
                'إجمالي المجلدات',
                data.totalFolders.toString(),
                Icons.folder,
              ),
              const SizedBox(height: 24),
              Text(
                'توزيع المجلدات حسب المرحلة الدراسية:',
                style: sectionTitleStyle,
              ),
              const SizedBox(height: 16),
              _buildFolderGradeBarChart(data.folderGradeDistribution),
              const SizedBox(height: 24),
            ],
          ),
        );
      case "الملفات":
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(
                'إجمالي الملفات',
                data.totalFiles.toString(),
                Icons.insert_drive_file,
              ),
              const SizedBox(height: 24),
              Text(
                'رسم بياني لمقارنة إجمالي الملفات والروابط:',
                style: sectionTitleStyle,
              ),
              const SizedBox(height: 16),
              _buildFilesAndLinksBarChart(data),
              const SizedBox(height: 24),
            ],
          ),
        );
      case "الروابط":
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(
                'إجمالي الروابط',
                data.totalLinks.toString(),
                Icons.link,
              ),
              const SizedBox(height: 24),
              Text(
                'رسم بياني لمقارنة إجمالي الملفات والروابط:',
                style: sectionTitleStyle,
              ),
              const SizedBox(height: 16),
              _buildFilesAndLinksBarChart(data),
              const SizedBox(height: 24),
            ],
          ),
        );
      case "الكل":
      default:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(
                'إجمالي المستخدمين',
                data.totalUsers.toString(),
                Icons.people,
              ),
              _buildInfoCard(
                'عدد الإدمن',
                data.totalAdmins.toString(),
                Icons.admin_panel_settings,
              ),
              _buildInfoCard(
                'إجمالي المجلدات',
                data.totalFolders.toString(),
                Icons.folder,
              ),
              _buildInfoCard(
                'إجمالي الملفات',
                data.totalFiles.toString(),
                Icons.insert_drive_file,
              ),
              _buildInfoCard(
                'إجمالي الروابط',
                data.totalLinks.toString(),
                Icons.link,
              ),
              const SizedBox(height: 24),
              Text('توزيع المستخدمين حسب الصلاحية:', style: sectionTitleStyle),
              const SizedBox(height: 16),
              _buildUserRolePieChart(data.userRoleDistribution),
              const SizedBox(height: 24),
              Text(
                'توزيع المجلدات حسب المرحلة الدراسية:',
                style: sectionTitleStyle,
              ),
              const SizedBox(height: 16),
              _buildFolderGradeBarChart(data.folderGradeDistribution),
              const SizedBox(height: 24),
              Text(
                'رسم بياني لمقارنة إجمالي الملفات والروابط:',
                style: sectionTitleStyle,
              ),
              const SizedBox(height: 16),
              _buildFilesAndLinksBarChart(data),
              const SizedBox(height: 24),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    if (user == null || user.role.toLowerCase() != 'admin') {
      return Scaffold(
        appBar: AppBar(
          title: Text('التقارير المتقدمة', style: GoogleFonts.cairo()),
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            'ليس لديك صلاحية الوصول لهذه الصفحة',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 18),
          ),
        ),
      );
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: Text('التقارير المتقدمة', style: GoogleFonts.cairo()),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3FA9F5), Color(0xFF2F62FF)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF2F62FF),
                    ),
                    isExpanded: true,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    items:
                        categoryOptions
                            .map(
                              (cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(
                                  cat,
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.cairo(),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedCategory = value;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Expanded(
                child: FutureBuilder<ReportData>(
                  future: _reportDataFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'خطأ: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(),
                        ),
                      );
                    }
                    final data = snapshot.data!;
                    return _buildReportContent(data);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
