import 'dart:async';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'app_logger.dart';

class _CachedStream {
  final String url;
  final DateTime expiresAt;

  _CachedStream({required this.url, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Helper utility for parsing YouTube URLs and extracting playable stream URLs
/// for native video player playback in Reels.
class YouTubeHelper {
  YouTubeHelper._();

  static final Map<String, _CachedStream> _streamCache = {};

  /// Checks if a given URL is a YouTube link (shorts, watch, youtu.be, embed, etc.)
  static bool isYouTubeUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final clean = url.trim().toLowerCase();
    return clean.contains('youtube.com') || clean.contains('youtu.be');
  }

  /// Extracts the 11-character video ID from various YouTube URL formats:
  /// - https://www.youtube.com/watch?v=VIDEO_ID
  /// - https://m.youtube.com/watch?v=VIDEO_ID
  /// - https://youtu.be/VIDEO_ID
  /// - https://www.youtube.com/shorts/VIDEO_ID
  /// - https://youtube.com/embed/VIDEO_ID
  static String? extractVideoId(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final clean = url.trim();

    final regExp = RegExp(
      r'(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=|shorts\/))([\w-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(clean);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }

    if (clean.length == 11 && RegExp(r'^[\w-]{11}$').hasMatch(clean)) {
      return clean;
    }

    try {
      return VideoId(clean).value;
    } catch (_) {
      return null;
    }
  }

  /// Returns the guaranteed high-quality YouTube thumbnail URL (100% supported for regular videos and Shorts)
  static String getThumbnailUrl(String videoId) {
    return 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
  }

  /// Returns the thumbnail URL - defaults to hqdefault as maxresdefault returns 404 for most Shorts
  static String getMaxResThumbnailUrl(String videoId) {
    return 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
  }

  /// Normalizes any YouTube thumbnail URL to ensure it doesn't 404 on maxresdefault
  static String safeThumbnailUrl(String? url, {String? fallbackVideoUrl}) {
    if (url != null && url.trim().isNotEmpty) {
      if (url.contains('maxresdefault.jpg')) {
        return url.replaceAll('maxresdefault.jpg', 'hqdefault.jpg');
      }
      return url;
    }
    if (fallbackVideoUrl != null && isYouTubeUrl(fallbackVideoUrl)) {
      final id = extractVideoId(fallbackVideoUrl);
      if (id != null) return getThumbnailUrl(id);
    }
    return '';
  }

  /// Resolves a YouTube URL into a direct playable stream URL (MP4)
  /// that can be used directly with `VideoPlayerController.networkUrl`.
  static Future<String?> resolveStreamUrl(String rawUrl) async {
    final id = extractVideoId(rawUrl);
    if (id == null) return null;

    final cached = _streamCache[id];
    if (cached != null && !cached.isExpired) {
      return cached.url;
    }

    YoutubeExplode? yt;
    try {
      yt = YoutubeExplode();
      final manifest = await yt.videos.streamsClient.getManifest(id);

      // 1. Prefer muxed stream (video + audio together)
      if (manifest.muxed.isNotEmpty) {
        final streamInfo = manifest.muxed.withHighestBitrate();
        final url = streamInfo.url.toString();
        _streamCache[id] = _CachedStream(
          url: url,
          expiresAt: DateTime.now().add(const Duration(hours: 3)),
        );
        return url;
      }

      // 2. Fallback to video-only if no muxed stream exists
      if (manifest.videoOnly.isNotEmpty) {
        final streamInfo = manifest.videoOnly.withHighestBitrate();
        final url = streamInfo.url.toString();
        _streamCache[id] = _CachedStream(
          url: url,
          expiresAt: DateTime.now().add(const Duration(hours: 3)),
        );
        return url;
      }
    } catch (e) {
      AppLogger.e('Error extracting YouTube stream URL for $id: $e');
    } finally {
      yt?.close();
    }
    return null;
  }
}
