import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubePlayerOverlay extends StatefulWidget {
  final String fieldName; // e.g., 'category', 'checkout', etc.

  const YoutubePlayerOverlay({super.key, required this.fieldName});

  @override
  State<YoutubePlayerOverlay> createState() => _YoutubePlayerOverlayState();
}

class _YoutubePlayerOverlayState extends State<YoutubePlayerOverlay> {
  YoutubePlayerController? _controller;
  bool _isLoading = true;
  String? _videoUrl;

  @override
  void initState() {
    super.initState();
    _fetchVideoUrl();
  }

  Future<void> _fetchVideoUrl() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('InAppVideo').doc('video_link').get();
      if (doc.exists && doc.data() != null && doc.data()![widget.fieldName] != null) {
        _videoUrl = doc.data()![widget.fieldName];
        final videoId = YoutubePlayer.convertUrlToId(_videoUrl!);

        if (videoId != null) {
          _controller = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: true,
              mute: false,
              forceHD: true,
            ),
          );
        }
      }
    } catch (e) {
      print("❌ Error fetching video URL: $e");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
          Center(
            child: _isLoading
                ? const CircularProgressIndicator()
                : _controller != null
                ? AspectRatio(
              aspectRatio: 9 / 16,
              child: YoutubePlayer(
                controller: _controller!,
                showVideoProgressIndicator: true,
              ),
            )
                : const Text("Video not available", style: TextStyle(color: Colors.white)),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                radius: 18,
                child: Icon(Icons.close, color: Colors.white, size: 24),
              ),
              onPressed: () => Navigator.pop(context),

            ),
          ),
        ],
      ),
    );
  }
}
