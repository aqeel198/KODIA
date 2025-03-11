import 'package:flutter/material.dart';
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

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late Future<ReportData> _reportDataFuture;
  String selectedCategory = "الكل";
  final List<String> categoryOptions = [
    "الكل",
    "المستخدمون",
    "المجلدات",
    "الملفات",
    "الروابط",
  ];

  // متغيرات التحريك (الأنيميشن)
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _reportDataFuture = _fetchReportData();

    // إعداد التحريك (الأنيميشن)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// دالة جلب بيانات التقارير مع عزل بيانات المدرسة
  Future<ReportData> _fetchReportData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // الحصول على المستخدم الحالي لجلب schoolId
      final currentUser =
          Provider.of<UserProvider>(context, listen: false).user;
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

      setState(() {
        _isLoading = false;
      });

      return ReportData(
        totalUsers: totalUsers,
        totalAdmins: totalAdmins,
        totalFolders: totalFolders,
        totalFiles: totalFiles,
        totalLinks: totalLinks,
        userRoleDistribution: userRoleDistribution,
        folderGradeDistribution: folderGradeDistribution,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      rethrow;
    }
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
          badgeWidget: const Icon(
            Icons.person_off_outlined,
            color: Colors.white,
            size: 20,
          ),
          badgePositionPercentageOffset: 1.2,
        ),
      );
    } else {
      final colors = [
        const Color(0xFF5E35B1), // Deep purple for admin
        const Color(0xFF00BCD4), // Cyan for users
      ];

      int index = 0;
      dataMap.forEach((key, value) {
        double percentage = (value / total) * 100;

        Widget badgeWidget;
        if (key == "admin") {
          badgeWidget = Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: colors[index].withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: Colors.white,
              size: 16,
            ),
          );
        } else {
          badgeWidget = Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: colors[index].withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outlined,
              color: Colors.white,
              size: 16,
            ),
          );
        }

        sections.add(
          PieChartSectionData(
            value: value.toDouble(),
            color: colors[index],
            title: "${percentage.toStringAsFixed(1)}%",
            radius: 60,
            titleStyle: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: badgeWidget,
            badgePositionPercentageOffset: 1.2,
          ),
        );

        index++;
      });
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'توزيع المستخدمين',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                "إدمن (${dataMap['admin'] ?? 0})",
                const Color(0xFF5E35B1),
              ),
              const SizedBox(width: 24),
              _buildLegendItem(
                "مستخدم (${dataMap['user'] ?? 0})",
                const Color(0xFF00BCD4),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.3,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 4,
                centerSpaceRadius: 50,
                centerSpaceColor: Colors.white.withOpacity(0.8),
                borderData: FlBorderData(show: false),
                pieTouchData: PieTouchData(enabled: true),
              ),
              swapAnimationDuration: const Duration(milliseconds: 800),
              swapAnimationCurve: Curves.easeInOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
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
    final gradientColors = [
      const Color(0xFF8A2387),
      const Color(0xFFE94057),
      const Color(0xFFF27121),
    ];

    dataMap.forEach((grade, count) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              gradient: LinearGradient(
                colors: [gradientColors[0], gradientColors[2]],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 16, // تقليل العرض للتوافق مع الشاشات الصغيرة
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxValue.toDouble() + 2,
                color: Colors.grey.shade200,
              ),
            ),
          ],
        ),
      );
      index++;
    });

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade100.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'توزيع المجلدات حسب الصف',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: gradientColors[1],
            ),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.3,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                minY: 0,
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
                            fontSize: 10, // تقليل حجم الخط للتوافق
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
                                fontSize: 10, // تقليل حجم الخط للتوافق
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
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
                  },
                ),
              ),
              swapAnimationDuration: const Duration(milliseconds: 800),
              swapAnimationCurve: Curves.easeInOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesAndLinksBarChart(ReportData data) {
    List<BarChartGroupData> barGroups = [];
    final values = [data.totalFiles, data.totalLinks];
    final labels = ["الملفات", "الروابط"];
    final colors = [
      const Color(0xFF00897B), // Teal for files
      const Color(0xFF7E57C2), // Deep purple for links
    ];
    final maxValue =
        values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < values.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: values[i].toDouble(),
              gradient: LinearGradient(
                colors: [colors[i].withOpacity(0.7), colors[i]],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 30, // عرض متوسط متوافق مع الشاشات
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade100.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'مقارنة الملفات والروابط',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF7E57C2),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem("الملفات (${data.totalFiles})", colors[0]),
              const SizedBox(width: 24),
              _buildLegendItem("الروابط (${data.totalLinks})", colors[1]),
            ],
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.3,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                minY: 0,
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
                          // تبسيط التسميات للتوافق مع الشاشات الصغيرة
                          return Text(
                            labels[idx],
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colors[idx],
                            ),
                          );
                        }
                        return const Text("");
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
                  },
                ),
              ),
              swapAnimationDuration: const Duration(milliseconds: 800),
              swapAnimationCurve: Curves.easeInOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon, {
    Color? color,
    bool isHighlighted = false,
  }) {
    final cardColor = color ?? Theme.of(context).primaryColor;
    // استخدام FittedBox للتوافق مع جميع أحجام الشاشات
    return Card(
      elevation: isHighlighted ? 8 : 4,
      shadowColor: cardColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient:
              isHighlighted
                  ? LinearGradient(
                    colors: [
                      cardColor.withOpacity(0.9),
                      cardColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : null,
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    isHighlighted
                        ? Colors.white.withOpacity(0.2)
                        : cardColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isHighlighted ? Colors.white : cardColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color:
                            isHighlighted
                                ? Colors.white.withOpacity(0.8)
                                : Theme.of(context).textTheme.titleSmall?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color:
                            isHighlighted
                                ? Colors.white
                                : Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categoryOptions.length,
        itemBuilder: (context, index) {
          final category = categoryOptions[index];
          final isSelected = category == selectedCategory;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategory = category;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                          : [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                ),
                child: Center(
                  child: Text(
                    category,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected
                              ? Colors.white
                              : Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // التحقق من حجم الشاشة
              final isSmallScreen = constraints.maxWidth < 400;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(isSmallScreen),
                  SliverFadeTransition(
                    opacity: _fadeAnimation,
                    sliver: SliverToBoxAdapter(
                      child: _buildBody(isSmallScreen),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isSmallScreen) {
    return SliverAppBar(
      expandedHeight: isSmallScreen ? 140.0 : 180.0,
      floating: false,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'التقارير والإحصائيات',
          style: GoogleFonts.cairo(
            fontSize: isSmallScreen ? 16 : 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        centerTitle: true,
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withBlue(255),
                    Theme.of(context).colorScheme.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: isSmallScreen ? 60 : 80,
              right: 20,
              child: Icon(
                Icons.analytics_rounded,
                color: Colors.white,
                size: isSmallScreen ? 24 : 32,
              ),
            ),
          ],
        ),
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'تحديث البيانات',
          onPressed: () {
            setState(() {
              _reportDataFuture = _fetchReportData();
            });
          },
        ),
      ],
    );
  }

  Widget _buildBody(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCategorySelector(),
          FutureBuilder<ReportData>(
            future: _reportDataFuture,
            builder: (context, snapshot) {
              if (_isLoading) {
                return _buildLoadingState();
              } else if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              } else if (snapshot.hasData) {
                return _buildReportContent(snapshot.data!, isSmallScreen);
              } else {
                return _buildLoadingState();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'جاري تحميل البيانات...',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ أثناء تحميل البيانات',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.red.shade300,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _reportDataFuture = _fetchReportData();
              });
            },
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              'إعادة المحاولة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(ReportData data, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selectedCategory == "الكل" || selectedCategory == "المستخدمون") ...[
          _buildStatsOverview(data, isSmallScreen),
          _buildUserRolePieChart(data.userRoleDistribution),
        ],
        if (selectedCategory == "الكل" || selectedCategory == "المجلدات") ...[
          _buildFolderGradeBarChart(data.folderGradeDistribution),
        ],
        if (selectedCategory == "الكل" ||
            selectedCategory == "الملفات" ||
            selectedCategory == "الروابط") ...[
          _buildFilesAndLinksBarChart(data),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatsOverview(ReportData data, bool isSmallScreen) {
    // جعل شبكة البطاقات متوافقة مع جميع أحجام الشاشات
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Text(
              'نظرة عامة',
              style: GoogleFonts.cairo(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              // حساب عدد البطاقات في الصف بناءً على حجم الشاشة
              int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;

              return GridView(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: isSmallScreen ? 1.5 : 1.8,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildInfoCard(
                    "إجمالي المستخدمين",
                    data.totalUsers.toString(),
                    Icons.people_rounded,
                    color: const Color(0xFF5E35B1),
                    isHighlighted: data.totalUsers > 0,
                  ),
                  _buildInfoCard(
                    "إجمالي المجلدات",
                    data.totalFolders.toString(),
                    Icons.folder_rounded,
                    color: const Color(0xFFE94057),
                    isHighlighted: data.totalFolders > 0,
                  ),
                  _buildInfoCard(
                    "إجمالي الملفات",
                    data.totalFiles.toString(),
                    Icons.insert_drive_file_rounded,
                    color: const Color(0xFF00897B),
                    isHighlighted: data.totalFiles > 0,
                  ),
                  _buildInfoCard(
                    "إجمالي الروابط",
                    data.totalLinks.toString(),
                    Icons.link_rounded,
                    color: const Color(0xFF7E57C2),
                    isHighlighted: data.totalLinks > 0,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
