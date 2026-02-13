import 'dart:io';
// import 'package:smtc_windows/smtc_windows.dart'; // REMOVED
// import 'package:windows_taskbar/windows_taskbar.dart'; // REMOVED

class WindowsTaskbarService {
  static final WindowsTaskbarService _instance =
      WindowsTaskbarService._internal();

  factory WindowsTaskbarService() {
    return _instance;
  }

  WindowsTaskbarService._internal();

  bool _isInitialized = false;

    final String nextIcon = 'assets/win_icon_next.ico';
    final String playIcon = 'assets/win_icon_play.ico';
    final String pauseIcon = 'assets/win_icon_pause.ico';

    try {
      await WindowsTaskbar.setThumbnailToolbar([
        ThumbnailToolbarButton(
          ThumbnailToolbarAssetIcon(prevIcon),
          'Previous',
          () {
            _onPrevious?.call();
          },
        ),
        ThumbnailToolbarButton(
          ThumbnailToolbarAssetIcon(isPlaying ? pauseIcon : playIcon),
          isPlaying ? 'Pause' : 'Play',
          () {
            if (isPlaying) {
              _onPause?.call();
            } else {
              _onPlay?.call();
            }
          },
        ),
        ThumbnailToolbarButton(
          ThumbnailToolbarAssetIcon(nextIcon),
          'Next',
          () {
            _onNext?.call();
          },
        ),
      ]);
    } catch (_) {}
  }

  Future<void> updateMetadata({
    required String title,
    required String artist,
    required String album,
    String? thumbnailPath,
  }) async {
    if (!_isInitialized || _smtc == null) return;
    try {
      // SANITIZE INPUTS (Prevent Rust Panic)
      final safeTitle = title.isEmpty ? "Unknown Title" : title;
      final safeArtist = artist.isEmpty ? "Unknown Artist" : artist;
      final safeAlbum = album.isEmpty ? "Unknown Album" : album;

      String? safeThumbnail = thumbnailPath;

      if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
        if (thumbnailPath.startsWith("http")) {
          // URLs are generally handled by specific implementations or ignored if unsupported
          // but we'll pass it through as is.
        } else {
          // For local files, verify existence!
          final file = File(thumbnailPath);
          if (!await file.exists()) {
            // print("⚠️ SMTC Warning: Thumbnail file does not exist: $thumbnailPath");
            safeThumbnail = null;
          }
        }
      } else {
        safeThumbnail = null;
      }

      _smtc!.updateMetadata(MusicMetadata(
        title: safeTitle,
        artist: safeArtist,
        album: safeAlbum,
        thumbnail: safeThumbnail,
      ));
    } catch (_) {}
  }

  Future<void> updatePlaybackStatus(bool isPlaying) async {
    if (!_isInitialized || _smtc == null) return;
    _smtc!.setPlaybackStatus(
        isPlaying ? PlaybackStatus.playing : PlaybackStatus.paused);

    // DYNAMIC BUTTON UPDATE
    await _setTaskbarButtons(isPlaying: isPlaying);
  }

  // CHAMELEON MODE (Progress Bar)
  Future<void> updateProgress(int currentMs, int totalMs) async {
    if (!Platform.isWindows) return;
    try {
      WindowsTaskbar.setProgress(currentMs, totalMs);
      WindowsTaskbar.setProgressMode(TaskbarProgressMode.normal);
    } catch (_) {}
  }

  void dispose() {
    _smtc?.dispose();
    _smtc = null;
    if (Platform.isWindows) {
      WindowsTaskbar.resetThumbnailToolbar();
    }
  }
}
