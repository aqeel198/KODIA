import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'reports_screen.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';
import 'lectures_screen.dart';
import 'home_screen_logic.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final HomeScreenLogic _logic = HomeScreenLogic();

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuint,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// بناء واجهة الصفحة الرئيسية
  Widget _buildBodyWithSubscriptionText(User user, int? daysLeft) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24.0), // حشوة سفلية
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // تحذير الاشتراك للإدمن فقط إذا تبقى 30 يوماً أو أقل
            if (user.role.toLowerCase() == 'admin' &&
                daysLeft != null &&
                daysLeft <= 30)
              _buildSubscriptionWarning(daysLeft),

            // ترحيب المستخدم
            _buildWelcomeSection(user),

            // عنوان القسم
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                "الخدمات المتاحة",
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
            ),

            // الكروت الرئيسية
            _buildMainCards(user),
          ],
        ),
      ),
    );
  }

  /// قسم الترحيب
  Widget _buildWelcomeSection(User user) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2F62FF), Color(0xFF3FA9F5)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F62FF).withOpacity(0.3),
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_animation),
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "مرحباً ${user.username}،",
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "نتمنى لك يوماً دراسياً موفقاً",
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بطاقات الصفحة الرئيسية
  Widget _buildMainCards(User user) {
    // جميع المستخدمين يرون بطاقة "المحاضرات"
    final List<Map<String, dynamic>> cardItems = [
      {
        'title': 'المحاضرات',
        'subtitle': 'عرض جميع المحاضرات المتاحة',
        'icon': Icons.video_library_rounded,
        'color': const Color(0xFF2F62FF),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LecturesScreen()),
          );
        },
      },
    ];

    // إن كان المستخدم إدمن، نضيف باقي البطاقات
    if (user.role.toLowerCase() == 'admin') {
      cardItems.addAll([
        {
          'title': 'الواجبات',
          'subtitle': 'متابعة الواجبات المدرسية',
          'icon': Icons.assignment_rounded,
          'color': const Color(0xFF4CAF50),
          'onTap': () {
            _showFeatureNotAvailableDialog();
          },
        },
        {
          'title': 'الجدول الدراسي',
          'subtitle': 'عرض جدول الحصص الأسبوعي',
          'icon': Icons.calendar_today_rounded,
          'color': const Color(0xFF2196F3),
          'onTap': () {
            _showFeatureNotAvailableDialog();
          },
        },
        {
          'title': 'البث المباشر',
          'subtitle': 'حضور الحصص عبر الإنترنت',
          'icon': Icons.live_tv_rounded,
          'color': const Color(0xFFF44336),
          'onTap': () {
            _showFeatureNotAvailableDialog();
          },
        },
        {
          'title': 'التقارير',
          'subtitle': 'إحصائيات وتقارير المدرسة',
          'icon': Icons.bar_chart_rounded,
          'color': const Color(0xFFAB47BC),
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReportsScreen()),
            );
          },
        },
        {
          'title': 'إدارة المستخدمين',
          'subtitle': 'إضافة وتعديل حسابات المستخدمين',
          'icon': Icons.people_alt_rounded,
          'color': const Color(0xFFFFA726),
          'onTap': () {
            Navigator.pushNamed(context, "/userManagement");
          },
        },
      ]);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cardItems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          // جرّب تعديل النسبة إن أردت تكبير أو تصغير البطاقات
          childAspectRatio: 0.85,
        ),
        itemBuilder: (context, index) {
          final item = cardItems[index];

          // تأخير ظهور كل بطاقة
          final delayedAnimation = _animation.value - (index * 0.1);
          final animationValue = delayedAnimation.clamp(0.0, 1.0);

          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - animationValue)),
                child: Opacity(opacity: 1, child: child),
              );
            },
            child: GestureDetector(
              onTap: item['onTap'],
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: item['color'].withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: item['color'].withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item['icon'], size: 32, color: item['color']),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item['title'],
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        item['subtitle'],
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// شريط التطبيقات العلوي
  PreferredSizeWidget _buildAppBar(User user) {
    final schoolName = user.schoolName ?? "جاري التحميل...";
    final schoolLogo = user.logoUrl ?? "";

    return AppBar(
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 70,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          schoolLogo.isNotEmpty
              ? Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  image: DecorationImage(
                    image: NetworkImage(schoolLogo),
                    fit: BoxFit.cover,
                  ),
                ),
              )
              : Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2F62FF).withOpacity(0.1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school,
                  color: Color(0xFF2F62FF),
                  size: 24,
                ),
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              schoolName,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: Color(0xFF2F62FF),
                size: 22,
              ),
              tooltip: "تسجيل الخروج",
              onPressed: () => _logic.logout(context),
            ),
          ),
        ],
      ),
    );
  }

  /// ويدجت تحذير الاشتراك
  Widget _buildSubscriptionWarning(int daysLeft) {
    Color bgColor;
    IconData iconData;
    String message;

    if (daysLeft < 0) {
      bgColor = const Color(0xFFFEE8E6);
      iconData = Icons.error_outline_rounded;
      message = 'انتهى الاشتراك! يرجى التجديد فوراً.';
    } else if (daysLeft <= 1) {
      bgColor = const Color(0xFFFFF3E0);
      iconData = Icons.warning_amber_rounded;
      message = 'سينتهي الاشتراك غداً! يرجى التجديد.';
    } else if (daysLeft <= 7) {
      bgColor = const Color(0xFFFFF8E1);
      iconData = Icons.access_time_rounded;
      message = 'عدد الأيام المتبقية على انتهاء الاشتراك: $daysLeft أيام';
    } else {
      bgColor = const Color(0xFFFFFDE7);
      iconData = Icons.info_outline_rounded;
      message = 'عدد الأيام المتبقية على انتهاء الاشتراك: $daysLeft يوم';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(iconData, color: const Color(0xFFFF9800), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.cairo(
                color: const Color(0xFF333333),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // استدعاء دالة التجديد التي تعرض الرقم
              _showRenewDialog();
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(
              "تجديد",
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// دالة عرض رسالة التجديد مع الرقم
  void _showRenewDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F62FF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF2F62FF),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "يرجى التواصل عبر الرقم التالي",
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '07715935012',
                  style: TextStyle(
                    letterSpacing: 1.5,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 255, 102, 0),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F62FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "موافق",
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// دالة عرض رسالة الميزة غير المتوفرة
  void _showFeatureNotAvailableDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.grey,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "هذه الميزة غير متوفرة لديك",
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "موافق",
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: SizedBox());
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(user),
        body: SafeArea(
          // <-- أضفنا SafeArea هنا
          child: FutureBuilder<int?>(
            future: _logic.fetchDaysLeftForSubscription(context),
            builder: (context, snapshot) {
              final daysLeft = snapshot.data;
              return _buildBodyWithSubscriptionText(user, daysLeft);
            },
          ),
        ),
      ),
    );
  }
}
