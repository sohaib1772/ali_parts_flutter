import 'dart:async';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'app_logger.dart';

/// Represents resolved playable streams for a YouTube video.
class YouTubePlayableStreams {
  /// The video stream URL (MP4 H.264 up to 1080p/720p).
  final String videoUrl;

  /// The audio stream URL (MP4 AAC stereo). Null if audio is already muxed into videoUrl.
  final String? audioUrl;

  /// Quality label (e.g. "1080p", "720p", "360p").
  final String? qualityLabel;

  /// Video width in pixels.
  final int? width;

  /// Video height in pixels.
  final int? height;

  const YouTubePlayableStreams({
    required this.videoUrl,
    this.audioUrl,
    this.qualityLabel,
    this.width,
    this.height,
  });

  /// True if video and audio are separate adaptive streams.
  bool get isAdaptive => audioUrl != null && audioUrl!.isNotEmpty;
}

class _CachedStreams {
  final YouTubePlayableStreams streams;
  final DateTime expiresAt;

  _CachedStreams({required this.streams, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Helper utility for parsing YouTube URLs and extracting playable stream URLs
/// for native video player playback in Reels.
class YouTubeHelper {
  YouTubeHelper._();

  static final Map<String, _CachedStreams> _streamCache = {};

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

  /// Resolves a YouTube URL into high-definition playable stream(s).
  ///
  /// YouTube serves HD resolutions (720p, 1080p) as separate adaptive video and audio
  /// streams. This method extracts the highest available H.264 (avc1) MP4 video stream
  /// (up to 1080p/720p) and AAC MP4 audio stream for flawless cross-platform playback.
  static Future<YouTubePlayableStreams?> resolveStreams(String rawUrl) async {
    final id = extractVideoId(rawUrl);
    if (id == null) return null;

    final cached = _streamCache[id];
    if (cached != null && !cached.isExpired) {
      return cached.streams;
    }

    YoutubeExplode? yt;
    try {
      yt = YoutubeExplode();
      final manifest = await yt.videos.streamsClient.getManifest(id);

      // 1. Prefer highest resolution MP4 (H.264 / avc1) video-only stream
      // along with highest quality AAC MP4 audio stream for full 1080p/720p HD.
      final mp4Videos = manifest.videoOnly
          .where((s) => s.container.name == 'mp4' && s.videoCodec.startsWith('avc1'))
          .toList();

      final mp4Audios = manifest.audioOnly
          .where((s) => s.container.name == 'mp4')
          .toList();

      if (mp4Videos.isNotEmpty && mp4Audios.isNotEmpty) {
        mp4Videos.sort((a, b) => b.bitrate.compareTo(a.bitrate));
        mp4Audios.sort((a, b) => b.bitrate.compareTo(a.bitrate));

        final bestVideo = mp4Videos.first;
        final bestAudio = mp4Audios.first;

        final result = YouTubePlayableStreams(
          videoUrl: bestVideo.url.toString(),
          audioUrl: bestAudio.url.toString(),
          qualityLabel: bestVideo.qualityLabel,
          width: bestVideo.videoResolution.width,
          height: bestVideo.videoResolution.height,
        );

        _streamCache[id] = _CachedStreams(
          streams: result,
          expiresAt: DateTime.now().add(const Duration(hours: 3)),
        );
        return result;
      }

      // 2. Fallback to muxed stream (video + audio together, usually 360p)
      if (manifest.muxed.isNotEmpty) {
        final streamInfo = manifest.muxed.withHighestBitrate();
        final result = YouTubePlayableStreams(
          videoUrl: streamInfo.url.toString(),
          audioUrl: null,
          qualityLabel: streamInfo.qualityLabel,
          width: streamInfo.videoResolution.width,
          height: streamInfo.videoResolution.height,
        );

        _streamCache[id] = _CachedStreams(
          streams: result,
          expiresAt: DateTime.now().add(const Duration(hours: 3)),
        );
        return result;
      }

      // 3. Fallback to any video-only stream
      if (manifest.videoOnly.isNotEmpty) {
        final streamInfo = manifest.videoOnly.withHighestBitrate();
        final result = YouTubePlayableStreams(
          videoUrl: streamInfo.url.toString(),
          audioUrl: null,
          qualityLabel: streamInfo.qualityLabel,
          width: streamInfo.videoResolution.width,
          height: streamInfo.videoResolution.height,
        );

        _streamCache[id] = _CachedStreams(
          streams: result,
          expiresAt: DateTime.now().add(const Duration(hours: 3)),
        );
        return result;
      }
    } catch (e) {
      AppLogger.e('Error extracting YouTube streams for $id: $e');
    } finally {
      yt?.close();
    }
    return null;
  }

  /// Resolves a YouTube URL into a direct playable stream URL (MP4)
  /// that can be used directly with `VideoPlayerController.networkUrl`.
  static Future<String?> resolveStreamUrl(String rawUrl) async {
    final id = extractVideoId(rawUrl);
    if (id == null) return null;

    final cached = _streamCache[id];
    if (cached != null && !cached.isExpired && cached.streams.audioUrl == null) {
      return cached.streams.videoUrl;
    }

    YoutubeExplode? yt;
    try {
      yt = YoutubeExplode();
      final manifest = await yt.videos.streamsClient.getManifest(id);

      // 1. Prefer progressive muxed stream (audio + video in a single track)
      // This guarantees zero AudioFocus collision on Android and smooth uninterrupted playback.
      if (manifest.muxed.isNotEmpty) {
        final streamInfo = manifest.muxed.withHighestBitrate();
        final url = streamInfo.url.toString();
        _streamCache[id] = _CachedStreams(
          streams: YouTubePlayableStreams(
            videoUrl: url,
            audioUrl: null,
            qualityLabel: streamInfo.qualityLabel,
            width: streamInfo.videoResolution.width,
            height: streamInfo.videoResolution.height,
          ),
          expiresAt: DateTime.now().add(const Duration(hours: 3)),
        );
        return url;
      }

      // 2. Fallback to video-only if no muxed stream exists
      if (manifest.videoOnly.isNotEmpty) {
        final streamInfo = manifest.videoOnly.withHighestBitrate();
        final url = streamInfo.url.toString();
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
