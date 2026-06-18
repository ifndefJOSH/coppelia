import 'package:intl/intl.dart';

import '../models/artist.dart';
import '../models/media_item.dart';

/// Formats a duration to mm:ss.
String formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// Formats a track count with correct singular/plural wording.
String formatTrackCount(int count) {
  return '$count ${count == 1 ? 'track' : 'tracks'}';
}

/// Returns a collection duration only when every expected track has one.
Duration? totalTrackDuration(
  List<MediaItem> tracks, {
  int? expectedTrackCount,
}) {
  if (tracks.isEmpty) {
    return null;
  }
  if (expectedTrackCount != null && tracks.length != expectedTrackCount) {
    return null;
  }
  var total = Duration.zero;
  for (final track in tracks) {
    if (track.duration <= Duration.zero) {
      return null;
    }
    total += track.duration;
  }
  return total;
}

/// Formats "N tracks" and appends duration when it is known.
String formatTrackCountWithDuration(int count, Duration? duration) {
  final base = formatTrackCount(count);
  if (duration == null || duration <= Duration.zero) {
    return base;
  }
  return '$base • ${formatDuration(duration)}';
}

/// Formats a byte count into a human-readable string.
String formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  const units = ['KB', 'MB', 'GB', 'TB'];
  double value = bytes / 1024;
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  final formatted =
      value >= 100 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  return '$formatted ${units[unitIndex]}';
}

/// Formats a count with locale separators.
String formatCount(int value) {
  final formatter = NumberFormat.decimalPattern();
  return formatter.format(value);
}

/// Formats artist stats for UI, avoiding empty "0 tracks" labels.
String formatArtistSubtitle(
  Artist artist, {
  int? fallbackAlbumCount,
  int? fallbackTrackCount,
}) {
  final albumCount =
      artist.albumCount > 0 ? artist.albumCount : (fallbackAlbumCount ?? 0);
  final trackCount =
      artist.trackCount > 0 ? artist.trackCount : (fallbackTrackCount ?? 0);
  if (albumCount > 0 && trackCount > 0) {
    return '$albumCount albums • $trackCount tracks';
  }
  if (albumCount > 0) {
    return '$albumCount albums';
  }
  if (trackCount > 0) {
    return '$trackCount tracks';
  }
  return 'Artist';
}
