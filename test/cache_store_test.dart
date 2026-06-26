import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:coppelia/models/media_item.dart';
import 'package:coppelia/models/playback_resume_state.dart';
import 'package:coppelia/models/playlist.dart';
import 'package:coppelia/services/cache_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = _FakePathProvider();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('cache store saves and restores playlists', () async {
    SharedPreferences.setMockInitialValues({});
    final cacheStore = CacheStore();
    final playlists = [
      const Playlist(
        id: 'playlist-1',
        name: 'Late Night',
        trackCount: 8,
        imageUrl: null,
      ),
    ];

    await cacheStore.savePlaylists(playlists);
    final restored = await cacheStore.loadPlaylists();

    expect(restored, hasLength(1));
    expect(restored.first.name, 'Late Night');
  });

  test('cache store saves playlist tracks', () async {
    SharedPreferences.setMockInitialValues({});
    final cacheStore = CacheStore();
    final tracks = [
      const MediaItem(
        id: 'track-1',
        title: 'Evergreen',
        album: 'Solstice',
        artists: ['Studio Band'],
        duration: Duration(minutes: 3, seconds: 12),
        imageUrl: null,
        streamUrl: 'https://demo.jellyfin.org/Audio/track-1/stream',
      ),
    ];

    await cacheStore.savePlaylistTracks('playlist-1', tracks);
    final restored = await cacheStore.loadPlaylistTracks('playlist-1');

    expect(restored, hasLength(1));
    expect(restored.first.title, 'Evergreen');
  });

  test('media item cache migration strips legacy api key from stream URL', () {
    final item = MediaItem.fromJson({
      'id': 'track-legacy',
      'title': 'Legacy',
      'album': 'Old Cache',
      'artists': ['Studio Band'],
      'durationMs': 120000,
      'imageUrl': null,
      'streamUrl':
          'https://demo.jellyfin.org/Audio/track-legacy/universal?UserId=user&api_key=secret&DeviceId=device',
    });

    final uri = Uri.parse(item.streamUrl);
    expect(uri.queryParameters, isNot(contains('api_key')));
    expect(uri.queryParameters['UserId'], 'user');
    expect(uri.queryParameters['DeviceId'], 'device');
  });

  test('cache store normalizes legacy playback resume stream URL', () async {
    SharedPreferences.setMockInitialValues({});
    final cacheStore = CacheStore();
    const track = MediaItem(
      id: 'track-resume',
      title: 'Resume',
      album: 'Old Cache',
      artists: ['Studio Band'],
      duration: Duration(minutes: 2),
      imageUrl: null,
      streamUrl:
          'https://demo.jellyfin.org/Audio/track-resume/universal?UserId=user&api_key=secret',
    );

    await cacheStore.savePlaybackResumeState(
      const PlaybackResumeState(
        track: track,
        position: Duration(seconds: 30),
      ),
    );
    final restored = await cacheStore.loadPlaybackResumeState();

    expect(restored, isNotNull);
    expect(
      Uri.parse(restored!.track.streamUrl).queryParameters,
      isNot(contains('api_key')),
    );
  });

  test('cache store saves whole-library offline pins', () async {
    SharedPreferences.setMockInitialValues({});
    final cacheStore = CacheStore();

    await cacheStore.saveWholeLibraryPinnedAudio({
      'https://demo.jellyfin.org/Audio/track-1/stream',
      'https://demo.jellyfin.org/Audio/track-2/stream',
    });

    final restored = await cacheStore.loadWholeLibraryPinnedAudio();

    expect(
      restored,
      containsAll([
        'https://demo.jellyfin.org/Audio/track-1/stream',
        'https://demo.jellyfin.org/Audio/track-2/stream',
      ]),
    );
  });

  test('cache store saves and forgets pinned audio metadata in bulk', () async {
    SharedPreferences.setMockInitialValues({});
    final cacheStore = CacheStore();
    const track = MediaItem(
      id: 'track-9',
      title: 'Northbound',
      album: 'Transit',
      artists: ['Demo Artist'],
      duration: Duration(minutes: 4),
      imageUrl: null,
      streamUrl: 'https://demo.jellyfin.org/Audio/track-9/stream',
    );

    await cacheStore.savePinnedAudioItems([track]);
    await cacheStore.savePinnedAudio({track.streamUrl});
    var restored = await cacheStore.loadPinnedAudioItems();
    expect(restored.map((item) => item.streamUrl), contains(track.streamUrl));

    await cacheStore.forgetPinnedAudioItems([track.streamUrl]);
    restored = await cacheStore.loadPinnedAudioItems();
    expect(restored, isEmpty);
  });

  test('clearOfflineAudioState clears offline pin metadata', () async {
    SharedPreferences.setMockInitialValues({});
    final cacheStore = CacheStore();
    const track = MediaItem(
      id: 'track-clear',
      title: 'Clear Me',
      album: 'Offline',
      artists: ['Studio Band'],
      duration: Duration(minutes: 4),
      imageUrl: null,
      streamUrl: 'https://demo.jellyfin.org/Audio/track-clear/stream',
    );

    await cacheStore.savePinnedAudio({track.streamUrl});
    await cacheStore.savePinnedAudioItems([track]);
    await cacheStore.saveWholeLibraryPinnedAudio({track.streamUrl});

    await cacheStore.clearOfflineAudioState();

    expect(await cacheStore.loadPinnedAudio(), isEmpty);
    expect(await cacheStore.loadPinnedAudioItems(), isEmpty);
    expect(await cacheStore.loadWholeLibraryPinnedAudio(), isEmpty);
  });
}

class _FakePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;

  @override
  Future<String?> getApplicationSupportPath() async =>
      Directory.systemTemp.path;
}
