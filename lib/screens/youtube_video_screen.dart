import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:google_fonts/google_fonts.dart';

class YoutubePlayerScreen extends StatefulWidget {
  final String videoUrl;
  const YoutubePlayerScreen({super.key, required this.videoUrl});

  @override
  // ignore: library_private_types_in_public_api
  _YoutubePlayerScreenState createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  late YoutubePlayerController _controller;
  late bool _isValidVideo;
  String? videoId;

  @override
  void initState() {
    super.initState();
    _secureScreen();
    videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    _isValidVideo = videoId != null && videoId!.isNotEmpty;
    if (_isValidVideo) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId!,
        flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
      );
    }
  }

  /// حماية الشاشة من التسجيل أو التقاط الصور باستخدام مكتبة screen_protector
  Future<void> _secureScreen() async {
    await ScreenProtector.preventScreenshotOn();
  }

  @override
  void dispose() {
    if (_isValidVideo) {
      _controller.dispose();
    }
    ScreenProtector.preventScreenshotOff();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isValidVideo) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'مشغل YouTube',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Text(
            'رابط الفيديو غير صالح',
            style: GoogleFonts.cairo(fontSize: 18, color: Colors.redAccent),
          ),
        ),
      );
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.blueAccent,
      ),
      builder: (context, player) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              'مشغل',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3FA9F5), Color(0xFF2F62FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Color(0xFFE0F7FA)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(child: player),
          ),
        );
      },
    );
  }
}
