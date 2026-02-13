
// SHIM: Placeholder for metadata_god package
// This file assumes the package 'metadata_god' is removed from pubspec.yaml
// and this file is imported instead.

class MetadataGod {
  static Future<Metadata?> getMetadata(String file) async {
    return null; // Always return null (no metadata)
  }
}

class Metadata {
  final String? title;
  final String? artist;
  final String? album;
  final String? genre;
  final int? year;
  final int? trackNumber;
  final int? trackTotal;
  final int? discNumber;
  final int? discTotal;
  final int? durationMs;
  final Picture? picture;

  Metadata({
    this.title,
    this.artist,
    this.album,
    this.genre,
    this.year,
    this.trackNumber,
    this.trackTotal,
    this.discNumber,
    this.discTotal,
    this.durationMs,
    this.picture,
  });
}

class Picture {
  final String? mimeType;
  final List<int>? data;

  Picture({this.mimeType, this.data});
}
