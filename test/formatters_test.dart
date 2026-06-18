import 'package:flutter_test/flutter_test.dart';

import 'package:coppelia/core/formatters.dart';
import 'package:coppelia/models/media_item.dart';

MediaItem _track(String id, Duration duration) {
  return MediaItem(
    id: id,
    title: 'Track $id',
    album: 'Album',
    artists: const ['Artist'],
    duration: duration,
    imageUrl: null,
    streamUrl: 'https://example.com/audio/$id.mp3',
  );
}

void main() {
  group('track collection formatting', () {
    test('formats count and known duration', () {
      final duration = totalTrackDuration(
        [
          _track('1', const Duration(minutes: 3, seconds: 4)),
          _track('2', const Duration(minutes: 55, seconds: 59)),
        ],
        expectedTrackCount: 2,
      );

      expect(
        formatTrackCountWithDuration(2, duration),
        '2 tracks • 59:03',
      );
    });

    test('omits duration when any track duration is missing', () {
      final duration = totalTrackDuration(
        [
          _track('1', const Duration(minutes: 3)),
          _track('2', Duration.zero),
        ],
        expectedTrackCount: 2,
      );

      expect(duration, isNull);
      expect(formatTrackCountWithDuration(2, duration), '2 tracks');
    });

    test('omits duration until every expected track is loaded', () {
      final duration = totalTrackDuration(
        [_track('1', const Duration(minutes: 3))],
        expectedTrackCount: 2,
      );

      expect(duration, isNull);
      expect(formatTrackCountWithDuration(2, duration), '2 tracks');
    });
  });
}
