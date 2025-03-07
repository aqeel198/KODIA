// FolderContentsScreen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/folder.dart';
import '../models/file_record.dart';
import '../models/link_record.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../services/mysql_data_service.dart';
import 'file_upload_screen.dart';
import 'link_upload_screen.dart';
import 'file_download_item.dart';
import 'youtube_video_screen.dart';
import 'edit_link_dialog.dart';

class FolderContentsScreen extends StatefulWidget {
  final Folder folder;
  const FolderContentsScreen({super.key, required this.folder});

  @override
  _FolderContentsScreenState createState() => _FolderContentsScreenState();
}

class _FolderContentsScreenState extends State<FolderContentsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: _buildAppBar(user),
        body: _buildBody(user),
        floatingActionButton: _buildFloatingActionButton(user),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(User? user) {
    return AppBar(
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
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
      ),
      title: Text(
        'مجلد: ${widget.folder.name}',
        style: GoogleFonts.cairo(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (user != null && user.role.toLowerCase() == 'admin')
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'file') {
                await _addFile();
              } else if (value == 'link') {
                await _addLink();
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'file',
                    child: Text('إضافة ملف', style: GoogleFonts.cairo()),
                  ),
                  PopupMenuItem<String>(
                    value: 'link',
                    child: Text('إضافة رابط', style: GoogleFonts.cairo()),
                  ),
                ],
            icon: const Icon(Icons.add, color: Colors.white),
          ),
      ],
    );
  }

  Widget _buildBody(User? user) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('الملفات'),
            _buildFilesFuture(user),
            const SizedBox(height: 30),
            _buildSectionHeader('الروابط'),
            _buildLinksFuture(user),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(User? user) {
    return user != null && user.role.toLowerCase() == 'admin'
        ? FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => _buildAddContentSheet(),
            );
          },
          backgroundColor: const Color(0xFF2F62FF),
          child: const Icon(Icons.add, color: Colors.white),
        )
        : Container();
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2F62FF),
        ),
      ),
    );
  }

  Widget _buildFilesFuture(User? user) {
    return FutureBuilder<List<FileRecord>>(
      future:
          user != null
              ? MySQLDataService.instance.getFilesByFolder(
                widget.folder.id!,
                user.schoolId,
              )
              : Future.value([]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildErrorWidget('خطأ في جلب الملفات: ${snapshot.error}');
        }
        final files = snapshot.data ?? [];
        return _buildFileList(files, user);
      },
    );
  }

  Widget _buildLinksFuture(User? user) {
    return FutureBuilder<List<LinkRecord>>(
      future:
          user != null
              ? MySQLDataService.instance.getLinksByFolder(
                widget.folder.id!,
                user.schoolId,
              )
              : Future.value([]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildErrorWidget('خطأ في جلب الروابط: ${snapshot.error}');
        }
        final links = snapshot.data ?? [];
        return _buildLinkList(links, user);
      },
    );
  }

  Widget _buildFileList(List<FileRecord> files, User? user) {
    if (files.isEmpty) {
      return _buildEmptyWidget('لا توجد ملفات في هذا المجلد');
    }
    return AnimationLimiter(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: files.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: FileDownloadItem(
                  file: files[index],
                  user: user,
                  onFileUpdated: () => setState(() {}),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLinkList(List<LinkRecord> links, User? user) {
    if (links.isEmpty) {
      return _buildEmptyWidget('لا توجد روابط في هذا المجلد');
    }
    return AnimationLimiter(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: links.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: _buildLinkCard(links[index], user)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLinkCard(LinkRecord link, User? user) {
    final bool isAdmin = (user != null && user.role.toLowerCase() == 'admin');
    final bool isYoutubeLink =
        link.url.contains('youtube.com') || link.url.contains('youtu.be');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openLink(link.url),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    isYoutubeLink ? Colors.red.shade100 : Colors.blue.shade100,
                child: Icon(
                  isYoutubeLink ? Icons.play_circle_filled : Icons.link,
                  color: isYoutubeLink ? Colors.red : Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.title,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (isAdmin) const SizedBox(height: 4),
                    if (isAdmin)
                      Text(
                        _truncateUrl(link.url),
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              if (isAdmin) ...[
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _updateLink(link),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteLink(link, user),
                ),
              ] else
                Icon(
                  isYoutubeLink ? Icons.play_arrow : Icons.open_in_new,
                  color: isYoutubeLink ? Colors.red : Colors.blue,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _truncateUrl(String url) {
    if (url.length <= 30) return url;
    return '${url.substring(0, 27)}...';
  }

  Future<void> _updateLink(LinkRecord link) async {
    final updatedLink = await showDialog<LinkRecord>(
      context: context,
      builder: (context) => EditLinkDialog(link: link),
    );
    if (updatedLink != null) {
      await MySQLDataService.instance.updateLink(updatedLink);
      setState(() {});
    }
  }

  Future<void> _confirmDeleteLink(LinkRecord link, User? user) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('تأكيد الحذف', style: GoogleFonts.cairo()),
            content: Text(
              'هل أنت متأكد من حذف هذا الرابط؟',
              style: GoogleFonts.cairo(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('إلغاء', style: GoogleFonts.cairo()),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: Text('حذف', style: GoogleFonts.cairo()),
              ),
            ],
          ),
    );
    if (confirm == true && user != null) {
      await MySQLDataService.instance.deleteLink(link.id!, user.schoolId);
      setState(() {});
    }
  }

  Future<void> _openLink(String url) async {
    if (!url.startsWith('http')) {
      url = 'https://$url';
    }
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => YoutubePlayerScreen(videoUrl: url),
        ),
      );
    } else {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لا يمكن فتح الرابط', style: GoogleFonts.cairo()),
          ),
        );
      }
    }
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          message,
          style: GoogleFonts.cairo(color: Colors.red, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          message,
          style: GoogleFonts.cairo(color: Colors.grey, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAddContentSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'إضافة محتوى جديد',
            style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildAddContentButton(
                  icon: Icons.insert_drive_file,
                  label: 'إضافة ملف',
                  color: const Color(0xFF3FA9F5),
                  onTap: () {
                    Navigator.pop(context);
                    _addFile();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAddContentButton(
                  icon: Icons.link,
                  label: 'إضافة رابط',
                  color: const Color(0xFF2F62FF),
                  onTap: () {
                    Navigator.pop(context);
                    _addLink();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddContentButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addFile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileUploadScreen(folder: widget.folder),
      ),
    );
    if (result == true) setState(() {});
  }

  Future<void> _addLink() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LinkUploadScreen(folder: widget.folder),
      ),
    );
    if (result == true) setState(() {});
  }
}
