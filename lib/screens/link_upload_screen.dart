import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/folder.dart';
import '../models/link_record.dart';
import '../providers/user_provider.dart';
import '../services/mysql_data_service.dart';

class LinkUploadScreen extends StatefulWidget {
  final Folder folder;
  const LinkUploadScreen({super.key, required this.folder});

  @override
  _LinkUploadScreenState createState() => _LinkUploadScreenState();
}

class _LinkUploadScreenState extends State<LinkUploadScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String linkTitle = '';
  String linkUrl = '';
  bool _loading = false;

  late AnimationController _buttonController;

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.0,
      upperBound: 0.05,
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }

  /// رفع الرابط إلى قاعدة البيانات مع تمرير schoolId
  Future<void> _uploadLink() async {
    if (_formKey.currentState!.validate()) {
      // تقليم القيم المدخلة
      linkTitle = linkTitle.trim();
      linkUrl = linkUrl.trim();

      setState(() => _loading = true);
      final currentUser =
          Provider.of<UserProvider>(context, listen: false).user;
      if (currentUser == null) {
        setState(() => _loading = false);
        return;
      }

      // إنشاء كائن LinkRecord مع تمرير schoolId
      LinkRecord newLink = LinkRecord(
        title: linkTitle,
        url: linkUrl,
        folderId: widget.folder.id!,
        userId: currentUser.id!,
        schoolId: currentUser.schoolId, // التعديل هنا
      );

      try {
        await MySQLDataService.instance.uploadLink(newLink);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع الرابط بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("خطأ في رفع الرابط: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  /// فتح الرابط باستخدام url_launcher
  Future<void> _launchURL(String url) async {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("لا يمكن فتح الرابط")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3FA9F5), Color(0xFF2F62FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: const Text(
            'رفع رابط',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            Tooltip(
                              message: 'أدخل عنوان الرابط الذي تود رفعه',
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'عنوان الرابط',
                                  labelStyle: const TextStyle(fontSize: 18),
                                  prefixIcon: const Icon(
                                    Icons.title,
                                    color: Colors.blue,
                                  ),
                                  filled: true,
                                  fillColor: Colors.blue[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator:
                                    (val) =>
                                        (val == null || val.trim().isEmpty)
                                            ? 'أدخل عنوان الرابط'
                                            : null,
                                onChanged: (val) => linkTitle = val,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Tooltip(
                              message: 'أدخل الرابط الإلكتروني (URL) بشكل صحيح',
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'رابط URL',
                                  labelStyle: const TextStyle(fontSize: 18),
                                  prefixIcon: const Icon(
                                    Icons.link,
                                    color: Colors.blue,
                                  ),
                                  filled: true,
                                  fillColor: Colors.blue[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator:
                                    (val) =>
                                        (val == null || val.trim().isEmpty)
                                            ? 'أدخل الرابط'
                                            : null,
                                onChanged: (val) => linkUrl = val,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // زر مع تأثير hover للرفع
                            MouseRegion(
                              onEnter: (_) => _buttonController.forward(),
                              onExit: (_) => _buttonController.reverse(),
                              child: AnimatedBuilder(
                                animation: _buttonController,
                                builder: (context, child) {
                                  double scale = 1 + _buttonController.value;
                                  return Transform.scale(
                                    scale: scale,
                                    child: child,
                                  );
                                },
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[700],
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 8,
                                  ),
                                  onPressed: _uploadLink,
                                  child: const Text(
                                    'رفع الرابط',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // معاينة الرابط (يمكن النقر عليه)
                            if (linkUrl.isNotEmpty)
                              InkWell(
                                onTap: () => _launchURL(linkUrl),
                                child: Text(
                                  linkTitle.isNotEmpty ? linkTitle : linkUrl,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}
