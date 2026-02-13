import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/song_model.dart';
import '../../models/song_metadata.dart';
import '../../providers/player_provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/search_bridge_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/youtube_downloader_service.dart';
import '../../services/flac_downloader_service.dart'; // 🚀 IMPORT FLAC
import '../../services/spotify_service.dart';
import '../../models/download_progress.dart';
import '../../services/notification_service.dart';
import 'music_notification.dart';

enum SongAction {
  playNext,
  addToQueue,
  addToPlaylist,
  addToFavorites,
  goToArtist,
  download
}

class SongContextMenuRegion extends ConsumerWidget {
  final SongModel song;
  final List<SongModel> currentQueue;
  final Widget child;

  const SongContextMenuRegion({
    super.key,
    required this.song,
    required this.currentQueue,
    required this.child,
  });

  static Future<void> handleAction(BuildContext context, WidgetRef ref,
      SongAction action, SongModel song) async {
    final notifier = ref.read(playerProvider.notifier);

    switch (action) {
      case SongAction.playNext:
        notifier.insertSongNext(song);
        showCenterNotification(context,
            label: "QUEUE UPDATED",
            title: "Playing Next",
            subtitle: song.title,
            // Use artPath instead of artBytes
            artPath: song.filePath,
            onlineArtUrl: song.onlineArtUrl);
        break;

      case SongAction.addToQueue:
        notifier.addToQueue(song);
        showCenterNotification(context,
            label: "QUEUE UPDATED",
            title: "Added to Queue",
            subtitle: song.title,
            // Use artPath instead of artBytes
            artPath: song.filePath,
            onlineArtUrl: song.onlineArtUrl);
        break;

      case SongAction.addToPlaylist:
        final playlists = ref.read(playlistProvider);
        final playlistNotifier = ref.read(playlistProvider.notifier);

        if (playlists.isEmpty) {
          showCenterNotification(context,
              label: "ERROR",
              title: "No Playlists Found",
              backgroundColor: Colors.orangeAccent.withOpacity(0.9));
          return;
        }

        showDialog(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text("Add to Playlist"),
            backgroundColor: Theme.of(context).cardColor,
            children: playlists
                .map((p) => SimpleDialogOption(
                      onPressed: () {
                        // Check duplicate
                        final exists =
                            p.entries.any((e) => e.path == song.filePath);

                        if (exists) {
                          Navigator.pop(context);
                          // 🔴 GLASS RED ERROR
                          showCenterNotification(context,
                              label: "ERROR",
                              title: "Song Already in Playlist",
                              subtitle: p.name,
                              // Use artPath instead of artBytes
                              artPath: song.filePath,
                              backgroundColor:
                                  Colors.redAccent.withOpacity(0.85),
                              onlineArtUrl: song.onlineArtUrl);
                        } else {
                          playlistNotifier.addSongToPlaylist(p.id, song);
                          Navigator.pop(context);
                          // 🟢 SUCCESS
                          showCenterNotification(context,
                              label: "ADDED TO PLAYLIST",
                              title: p.name,
                              subtitle: song.title,
                              // Use artPath instead of artBytes
                              artPath: song.filePath,
                              onlineArtUrl: song.onlineArtUrl);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(p.name),
                      ),
                    ))
                .toList(),
          ),
        );
        break;

      case SongAction.addToFavorites:
        final playlists = ref.read(playlistProvider);
        final playlistNotifier = ref.read(playlistProvider.notifier);

        // 🚀 CHECK IF ALREADY IN LIKED SONGS
        final likedPlaylist = playlists.firstWhere(
          (p) => p.name == "Liked Songs",
          orElse: () => playlists.first, // Won't match if no playlists
        );

        final alreadyExists = likedPlaylist.name == "Liked Songs" &&
            likedPlaylist.entries
                .any((e) => e.title == song.title && e.artist == song.artist);

        if (alreadyExists) {
          // 🔴 ALREADY EXISTS - Show Error
          showCenterNotification(context,
              label: "ALREADY IN LIKED SONGS",
              title: song.title,
              subtitle: "This song is already in your favorites",
              artPath: song.filePath,
              onlineArtUrl: song.onlineArtUrl,
              icon: Icons.favorite_rounded,
              backgroundColor: Colors.orangeAccent.withOpacity(0.85));
        } else {
          // ✅ ADD TO LIKED SONGS
          playlistNotifier.addToLikedSongs(song);
          showCenterNotification(context,
              label: "LIKED SONGS",
              title: "Added to Liked Songs",
              subtitle: song.title,
              artPath: song.filePath,
              onlineArtUrl: song.onlineArtUrl,
              icon: Icons.favorite_rounded,
              backgroundColor: Colors.pinkAccent.withOpacity(0.85));
        }
        break;

      case SongAction.goToArtist:
        final librarySongs = ref.read(libraryProvider).songs;
        final artistSongs =
            librarySongs.where((s) => s.artist == song.artist).toList();

        // FIX: Use Provider Navigation instead of manual Push
        // This ensures MainShell switches the view correctly
        ref.read(navigationStackProvider.notifier).push(
              NavigationItem(
                type: NavigationType.artist,
                data: ArtistSelection(
                  artistName: song.artist,
                  songs: artistSongs,
                ),
              ),
            );
        break;
      case SongAction.download:
        // Download song with settings format (like search_page flow)
        final ytService = YoutubeDownloaderService();
        final flacService = FlacDownloaderService();

        final settings = ref.read(settingsProvider);
        final preferredFormat = settings.audioFormat; // mp3, m4a, flac
        final isFlacRequested = preferredFormat == 'flac';

        // 🚀 INIT NOTIFICATIONS
        final notif = NotificationService();
        await notif.init();
        final notifId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        try {
          // 🔍 STEP 0: Search Spotify FIRST to get metadata + album art
          String? spotifyArtUrl = song.onlineArtUrl;
          String? spotifyId;
          String? isrc = song.isrc;

          debugPrint("🔍 Searching Spotify for metadata...");
          showCenterNotification(context,
              label: "PREPARING DOWNLOAD",
              title: song.title,
              subtitle: "Fetching metadata from Spotify...",
              artPath: song.onlineArtUrl,
              onlineArtUrl: song.onlineArtUrl,
              icon: song.onlineArtUrl == null ? Icons.search_rounded : null);

          // Notify Start
          notif.showProgress(
              id: notifId,
              progress: 0,
              max: 100,
              title: "Preparing Download",
              body: song.title);

          final spotifyResults = await SpotifyService.searchMetadata(
            "${song.artist} ${song.title}",
          );

          if (spotifyResults.isNotEmpty) {
            final firstResult = spotifyResults.first;
            spotifyId = firstResult['spotify_id'] as String?;
            spotifyArtUrl =
                firstResult['image_url'] as String? ?? spotifyArtUrl;
            isrc = (firstResult['isrc'] as String?) ?? isrc;
            debugPrint(
                "✓ Found Spotify metadata: ID=$spotifyId, Art=$spotifyArtUrl");
          }

          // Build metadata with Spotify data
          final meta = SongMetadata(
            title: song.title,
            artist: song.artist,
            album: song.album,
            albumArtUrl: spotifyArtUrl ?? '',
            durationSeconds: song.duration.toInt(),
            year: song.year ?? '',
            genre: song.genre ?? '',
            isrc: isrc,
            spotifyId: spotifyId,
          );

          showCenterNotification(context,
              label: "DOWNLOAD STARTED",
              title: song.title,
              subtitle: "Preparing download ($preferredFormat)...",
              artPath: spotifyArtUrl,
              onlineArtUrl: spotifyArtUrl);

          // 🚀 UPDATE SIDEBAR PROGRESS (Global)
          YoutubeDownloaderService.songDownloadProgress.value =
              DownloadProgress(
            receivedMB: 0,
            totalMB: 0,
            progress: 0.0,
            status: "Downloading: ${song.title}",
            details: "Searching...",
          );

          // 1. Get YouTube URL (use existing sourceUrl or search)
          String? youtubeUrl = song.sourceUrl;
          if (youtubeUrl == null || youtubeUrl.isEmpty) {
            showCenterNotification(context,
                label: "SEARCHING",
                title: song.title,
                subtitle: "Finding best match on YouTube...",
                artPath: spotifyArtUrl,
                onlineArtUrl: spotifyArtUrl);

            // Simple search via YoutubeDownloaderService
            final searchResults =
                await ytService.searchVideo("${song.artist} - ${song.title}");
            if (searchResults.isNotEmpty) {
              youtubeUrl = searchResults.first.url;
            }
          }

          // 2. FLAC path (if requested and spotifyId available)
          if (isFlacRequested &&
              (meta.spotifyId != null ||
                  (meta.isrc != null && meta.isrc!.isNotEmpty))) {
            try {
              showCenterNotification(context,
                  label: "DOWNLOADING FLAC",
                  title: song.title,
                  subtitle: "Fetching lossless audio...",
                  artPath: spotifyArtUrl,
                  onlineArtUrl: spotifyArtUrl);

              notif.showProgress(
                  id: notifId,
                  progress: 0,
                  max: 100,
                  title: "Downloading FLAC",
                  body: song.title);

              final finalTitle =
                  "${meta.artist} - ${meta.title}".replaceAll("/", "_");
              final outputPath = await ytService.getDownloadPath(finalTitle,
                  ext: 'flac'); // Assume FLAC extension

              if (outputPath == null)
                throw Exception("Could not get output path");

              final flacResult = await flacService.downloadFlac(
                spotifyTrackId: meta.spotifyId ?? "",
                outputPath: outputPath,
                isrc: meta.isrc,
                trackName: meta.title,
                artistName: meta.artist,
                albumName: meta.album,
                onProgress: (p) {
                  // 🚀 UPDATE SIDEBAR PROGRESS FOR FLAC
                  YoutubeDownloaderService.songDownloadProgress.value =
                      DownloadProgress(
                    receivedMB: p * 30, // FLAC is larger
                    totalMB: 30,
                    progress: p,
                    status: "Downloading: ${song.title}",
                    details: "${(p * 100).toInt()}% - FLAC",
                  );
                  // 🚀 NOTIF
                  notif.showProgress(
                      id: notifId,
                      progress: (p * 100).toInt(),
                      max: 100,
                      title: "Downloading FLAC",
                      body: song.title);
                },
              );

              if (flacResult.isSuccess) {
                // 🚀 CLEAR SIDEBAR PROGRESS
                YoutubeDownloaderService.songDownloadProgress.value = null;

                showCenterNotification(context,
                    label: "DOWNLOAD COMPLETE",
                    title: song.title,
                    subtitle: "FLAC saved to Downloads",
                    artPath: flacResult.file?.path,
                    onlineArtUrl: spotifyArtUrl,
                    backgroundColor: Colors.green.withOpacity(0.85));

                notif.showComplete(
                    id: notifId,
                    title: "Download Complete",
                    body: "${song.title} (FLAC)");
                return; // SUCCESS!
              }

              // 🚀 FLAC UNAVAILABLE - Notify user instead of crashing
              // Fallback to YouTube
              debugPrint("FLAC Failed: ${flacResult.error}. Falling back...");
            } catch (e) {
              // FLAC specific error
              debugPrint("FLAC Error: $e");
              // Fallback to YouTube
            }
          }

          if (youtubeUrl == null || youtubeUrl.isEmpty) {
            throw Exception("No YouTube match found");
          }

          // 3. YouTube download path (MP3/M4A or FLAC fallback)
          final actualFormat = isFlacRequested ? 'mp3' : preferredFormat;
          final finalTitle =
              "${meta.artist} - ${meta.title}".replaceAll("/", "_");
          final outputPath =
              await ytService.getDownloadPath(finalTitle, ext: actualFormat);

          if (outputPath == null) {
            throw Exception("Storage permission denied or path error");
          }

          showCenterNotification(context,
              label: "DOWNLOADING",
              title: song.title,
              subtitle: "Downloading $actualFormat...",
              artPath: spotifyArtUrl,
              onlineArtUrl: spotifyArtUrl);

          notif.showProgress(
              id: notifId,
              progress: 0,
              max: 100,
              title: "Downloading $actualFormat",
              body: song.title);

          await ytService.startDownloadFromUrl(
            youtubeUrl: youtubeUrl,
            outputFilePath: outputPath,
            audioFormat: actualFormat,
            onProgress: (p) {
              // 🚀 UPDATE SIDEBAR PROGRESS
              YoutubeDownloaderService.songDownloadProgress.value =
                  DownloadProgress(
                receivedMB: p * 10, // Estimated
                totalMB: 10,
                progress: p,
                status: "Downloading: ${song.title}",
                details: "${(p * 100).toInt()}% - $actualFormat",
              );
              // 🚀 NOTIF
              notif.showProgress(
                  id: notifId,
                  progress: (p * 100).toInt(),
                  max: 100,
                  title: "Downloading Audio",
                  body: song.title);
            },
            onComplete: (success) async {
              YoutubeDownloaderService.songDownloadProgress.value = null;

              if (success) {
                // Tagging (Simplified - skipping detailed tagging if SmartService gone, or reimplement)
                // For now, assume just download is enough for simplified app.
                // Or use MetadataGod if available.

                showCenterNotification(context,
                    label: "DOWNLOAD COMPLETE",
                    title: song.title,
                    subtitle: "Saved as $actualFormat",
                    artPath: outputPath,
                    onlineArtUrl: spotifyArtUrl,
                    backgroundColor: Colors.green.withOpacity(0.85));

                notif.showComplete(
                    id: notifId,
                    title: "Download Complete",
                    body: "${song.title} ($actualFormat)");
              } else {
                showCenterNotification(context,
                    label: "DOWNLOAD FAILED",
                    title: song.title,
                    subtitle: "Download error",
                    artPath: spotifyArtUrl,
                    onlineArtUrl: spotifyArtUrl,
                    backgroundColor: Colors.red.withOpacity(0.85));
                notif.cancel(notifId);
              }
            },
          );
        } catch (e) {
          debugPrint("❌ Download Error: $e");
          YoutubeDownloaderService.songDownloadProgress.value = null;

          showCenterNotification(context,
              label: "DOWNLOAD FAILED",
              title: song.title,
              subtitle: e.toString().replaceAll("Exception:", "").trim(),
              onlineArtUrl: song.onlineArtUrl,
              icon: Icons.error_rounded,
              backgroundColor: Colors.red.withOpacity(0.85));

          notif.showComplete(
              id: notifId,
              title: "Download Failed",
              body:
                  "${song.title} - ${e.toString().replaceAll("Exception:", "").trim()}");
        }
        break;
    }
  }

  static Future<void> showSongMenu(BuildContext context, Offset offset,
      WidgetRef ref, SongModel song) async {
    final selected = await showMenu<SongAction>(
      context: context,
      position:
          RelativeRect.fromLTRB(offset.dx, offset.dy, offset.dx, offset.dy),
      items: [
        const PopupMenuItem(
            value: SongAction.playNext,
            child: Row(children: [
              Icon(Icons.playlist_play),
              SizedBox(width: 12),
              Text('Play Next')
            ])),
        const PopupMenuItem(
            value: SongAction.addToQueue,
            child: Row(children: [
              Icon(Icons.queue_music),
              SizedBox(width: 12),
              Text('Add to Queue')
            ])),
        const PopupMenuItem(
            value: SongAction.addToPlaylist,
            child: Row(children: [
              Icon(Icons.playlist_add),
              SizedBox(width: 12),
              Text('Add to Playlist')
            ])),
        const PopupMenuItem(
            value: SongAction.addToFavorites,
            child: Row(children: [
              Icon(Icons.favorite_border),
              SizedBox(width: 12),
              Text('Add to Favorites')
            ])),
        const PopupMenuItem(
            value: SongAction.goToArtist,
            child: Row(children: [
              Icon(Icons.person_search),
              SizedBox(width: 12),
              Text('Go to Artist')
            ])),
        const PopupMenuItem(
            value: SongAction.download,
            child: Row(children: [
              Icon(Icons.download_rounded),
              SizedBox(width: 12),
              Text('Download')
            ])),
      ],
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).cardColor,
    );

    if (selected != null) {
      handleAction(context, ref, selected, song);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onSecondaryTapDown: (details) {
          showSongMenu(context, details.globalPosition, ref, song);
        },
        onLongPressStart: (details) {
          // Mobile Long Press
          if (Platform.isAndroid || Platform.isIOS) {
            showSongMenu(context, details.globalPosition, ref, song);
          }
        },
        child: child,
      ),
    );
  }
}
