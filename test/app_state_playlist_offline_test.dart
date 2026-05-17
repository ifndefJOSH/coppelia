import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';

import 'package:coppelia/models/auth_session.dart';
import 'package:coppelia/models/album.dart';
import 'package:coppelia/models/artist.dart';
import 'package:coppelia/models/genre.dart';
import 'package:coppelia/models/library_stats.dart';
import 'package:coppelia/models/media_item.dart';
import 'package:coppelia/models/playlist.dart';
import 'package:coppelia/models/smart_list.dart';
import 'package:coppelia/models/cached_audio_entry.dart';
import 'package:coppelia/models/download_task.dart';
import 'package:coppelia/models/track_status_icon_state.dart';
import 'package:coppelia/services/cache_store.dart';
import 'package:coppelia/services/jellyfin_client.dart';
import 'package:coppelia/services/playback_controller.dart';
import 'package:coppelia/services/session_store.dart';
import 'package:coppelia/services/settings_store.dart';
import 'package:coppelia/state/app_state.dart';

class _MockCacheStore extends Mock implements CacheStore {}

class _MockJellyfinClient extends Mock implements JellyfinClient {}

class _MockPlaybackController extends Mock implements PlaybackController {}

class _MockSessionStore extends Mock implements SessionStore {}

class _MockSettingsStore extends Mock implements SettingsStore {}

MediaItem _track(String id, {String? title}) {
  return MediaItem(
    id: id,
    title: title ?? 'Track $id',
    album: 'Album',
    artists: const ['Artist'],
    duration: const Duration(minutes: 3),
    imageUrl: null,
    streamUrl: 'https://example.com/audio/$id.mp3',
  );
}

Album _album(String id) {
  return Album(
    id: id,
    name: 'Album $id',
    artistName: 'Artist',
    trackCount: 1,
    imageUrl: null,
  );
}

SmartList _titleContainsSmartList(String value) {
  return SmartList(
    id: 'smart-$value',
    name: 'Smart $value',
    scope: SmartListScope.tracks,
    group: SmartListGroup(
      mode: SmartListGroupMode.all,
      children: [
        SmartListRuleNode(
          rule: SmartListRule(
            field: SmartListField.title,
            operatorType: SmartListOperator.contains,
            value: value,
          ),
        ),
      ],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_track('fallback'));
    registerFallbackValue(<String>{});
    registerFallbackValue(<String, String>{});
    registerFallbackValue(<MediaItem>[]);
    registerFallbackValue(<Album>[]);
    registerFallbackValue(<Artist>[]);
    registerFallbackValue(<Genre>[]);
    registerFallbackValue(<Playlist>[]);
    registerFallbackValue(
      const LibraryStats(
        trackCount: 0,
        albumCount: 0,
        artistCount: 0,
        playlistCount: 0,
      ),
    );
  });

  AppState buildState({
    required _MockCacheStore cacheStore,
    required _MockJellyfinClient client,
    required _MockPlaybackController playback,
    required _MockSessionStore sessionStore,
    required _MockSettingsStore settingsStore,
  }) {
    when(
      () => playback.positionStream,
    ).thenAnswer((_) => const Stream<Duration>.empty());
    when(
      () => playback.durationStream,
    ).thenAnswer((_) => const Stream<Duration?>.empty());
    when(
      () => playback.playerStateStream,
    ).thenAnswer((_) => const Stream<PlayerState>.empty());
    when(
      () => playback.currentIndexStream,
    ).thenAnswer((_) => const Stream<int?>.empty());
    when(() => playback.position).thenReturn(Duration.zero);
    when(() => playback.duration).thenReturn(Duration.zero);
    when(() => playback.currentIndex).thenReturn(null);
    when(() => playback.dispose()).thenAnswer((_) async {});

    when(() => cacheStore.getMediaCacheBytes()).thenAnswer((_) async => 0);
    when(
      () => cacheStore.getPinnedMediaBytes(any()),
    ).thenAnswer((_) async => 0);
    when(
      () => cacheStore.loadCachedAudioEntries(),
    ).thenAnswer((_) async => const <CachedAudioEntry>[]);
    when(
      () => cacheStore.setPinnedAudio(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => cacheStore.setPinnedAudioItem(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => cacheStore.savePinnedAudio(any()),
    ).thenAnswer((_) async {});
    when(
      () => cacheStore.loadPinnedAudioItems(),
    ).thenAnswer((_) async => const <MediaItem>[]);
    when(
      () => cacheStore.isAudioCached(any()),
    ).thenAnswer((_) async => true);
    when(
      () => cacheStore.touchCachedAudio(any()),
    ).thenAnswer((_) async {});
    when(
      () => cacheStore.savePlaylistTracks(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => cacheStore.loadLibraryTracks(),
    ).thenAnswer((_) async => const <MediaItem>[]);
    when(
      () => cacheStore.saveLibraryTracks(any()),
    ).thenAnswer((_) async {});
    when(
      () => cacheStore.downloadAudioWithProgress(
        any(),
        headers: any(named: 'headers'),
      ),
    ).thenAnswer((_) => const Stream<FileResponse>.empty());
    when(() => settingsStore.saveDownloadsPaused(any()))
        .thenAnswer((_) async {});

    return AppState(
      cacheStore: cacheStore,
      client: client,
      playback: playback,
      sessionStore: sessionStore,
      settingsStore: settingsStore,
    );
  }

  void stubSignedInRefresh({
    required _MockCacheStore cacheStore,
    required _MockJellyfinClient client,
    required _MockSessionStore sessionStore,
  }) {
    const session = AuthSession(
      accessToken: 'token',
      serverUrl: 'https://example.com',
      userId: 'user',
      userName: 'User',
    );
    when(
      () => client.authenticate(
        serverUrl: 'https://example.com',
        username: 'user',
        password: 'password',
      ),
    ).thenAnswer((_) async => session);
    when(() => sessionStore.saveSession(session)).thenAnswer((_) async {});
    when(() => client.fetchPlaylists())
        .thenAnswer((_) async => const <Playlist>[]);
    when(() => cacheStore.savePlaylists(any())).thenAnswer((_) async {});
    when(() => client.fetchLibraryStats()).thenAnswer(
      (_) async => const LibraryStats(
        trackCount: 0,
        albumCount: 0,
        artistCount: 0,
        playlistCount: 0,
      ),
    );
    when(() => cacheStore.saveLibraryStats(any())).thenAnswer((_) async {});
    when(() => client.fetchRecentlyPlayedTracks())
        .thenAnswer((_) async => const <MediaItem>[]);
    when(() => client.fetchRecentTracks())
        .thenAnswer((_) async => const <MediaItem>[]);
    when(() => cacheStore.saveRecentTracks(any())).thenAnswer((_) async {});
    when(() => cacheStore.saveFeaturedTracks(any())).thenAnswer((_) async {});
    when(() => client.fetchAlbums()).thenAnswer((_) async => const <Album>[]);
    when(() => cacheStore.saveAlbums(any())).thenAnswer((_) async {});
    when(() => client.fetchArtists()).thenAnswer((_) async => const <Artist>[]);
    when(() => cacheStore.saveArtists(any())).thenAnswer((_) async {});
    when(() => client.fetchGenres()).thenAnswer((_) async => const <Genre>[]);
    when(() => cacheStore.saveGenres(any())).thenAnswer((_) async {});
    when(() => client.fetchFavoriteAlbums())
        .thenAnswer((_) async => const <Album>[]);
    when(() => cacheStore.saveFavoriteAlbums(any())).thenAnswer((_) async {});
    when(() => client.fetchFavoriteArtists())
        .thenAnswer((_) async => const <Artist>[]);
    when(() => cacheStore.saveFavoriteArtists(any())).thenAnswer((_) async {});
    when(() => client.fetchFavoriteTracks())
        .thenAnswer((_) async => const <MediaItem>[]);
    when(() => cacheStore.saveFavoriteTracks(any())).thenAnswer((_) async {});
  }

  group('AppState playlist offline', () {
    test('makePlaylistAvailableOffline pins cached playlist tracks', () async {
      final cacheStore = _MockCacheStore();
      final client = _MockJellyfinClient();
      final playback = _MockPlaybackController();
      final sessionStore = _MockSessionStore();
      final settingsStore = _MockSettingsStore();
      final state = buildState(
        cacheStore: cacheStore,
        client: client,
        playback: playback,
        sessionStore: sessionStore,
        settingsStore: settingsStore,
      );
      addTearDown(state.dispose);

      const playlist = Playlist(
        id: 'playlist-1',
        name: 'Playlist',
        trackCount: 2,
        imageUrl: null,
      );
      final tracks = [_track('1'), _track('2')];

      when(
        () => cacheStore.loadPlaylistTracks(playlist.id),
      ).thenAnswer((_) async => tracks);

      await state.makePlaylistAvailableOffline(playlist);

      expect(state.pinnedAudio, containsAll(tracks.map((t) => t.streamUrl)));
      expect(state.downloadQueue, isEmpty);
      verifyNever(() => client.fetchPlaylistTracks(any()));
      for (final track in tracks) {
        verify(() => cacheStore.setPinnedAudioItem(track, true)).called(1);
        verify(() => cacheStore.isAudioCached(track)).called(1);
        verify(() => cacheStore.touchCachedAudio(track)).called(1);
      }
    });

    test('makePlaylistAvailableOffline fetches and caches when tracks missing',
        () async {
      final cacheStore = _MockCacheStore();
      final client = _MockJellyfinClient();
      final playback = _MockPlaybackController();
      final sessionStore = _MockSessionStore();
      final settingsStore = _MockSettingsStore();
      final state = buildState(
        cacheStore: cacheStore,
        client: client,
        playback: playback,
        sessionStore: sessionStore,
        settingsStore: settingsStore,
      );
      addTearDown(state.dispose);

      const playlist = Playlist(
        id: 'playlist-2',
        name: 'Playlist 2',
        trackCount: 1,
        imageUrl: null,
      );
      final tracks = [_track('3')];

      when(
        () => cacheStore.loadPlaylistTracks(playlist.id),
      ).thenAnswer((_) async => const []);
      when(
        () => client.fetchPlaylistTracks(playlist.id),
      ).thenAnswer((_) async => tracks);

      await state.makePlaylistAvailableOffline(playlist);

      verify(() => client.fetchPlaylistTracks(playlist.id)).called(1);
      verify(() => cacheStore.savePlaylistTracks(playlist.id, tracks))
          .called(1);
      verify(() => cacheStore.setPinnedAudioItem(tracks.first, true)).called(1);
      expect(state.pinnedAudio, contains(tracks.first.streamUrl));
    });

    test('unpinPlaylistOffline clears pinned playlist tracks', () async {
      final cacheStore = _MockCacheStore();
      final client = _MockJellyfinClient();
      final playback = _MockPlaybackController();
      final sessionStore = _MockSessionStore();
      final settingsStore = _MockSettingsStore();
      final state = buildState(
        cacheStore: cacheStore,
        client: client,
        playback: playback,
        sessionStore: sessionStore,
        settingsStore: settingsStore,
      );
      addTearDown(state.dispose);

      const playlist = Playlist(
        id: 'playlist-3',
        name: 'Playlist 3',
        trackCount: 2,
        imageUrl: null,
      );
      final tracks = [_track('4'), _track('5')];

      when(
        () => cacheStore.loadPlaylistTracks(playlist.id),
      ).thenAnswer((_) async => tracks);

      await state.makePlaylistAvailableOffline(playlist);
      expect(state.pinnedAudio, containsAll(tracks.map((t) => t.streamUrl)));

      await state.unpinPlaylistOffline(playlist);

      expect(state.pinnedAudio, isEmpty);
      for (final track in tracks) {
        verify(() => cacheStore.setPinnedAudio(track.streamUrl, false))
            .called(1);
      }
    });
  });

  group('AppState detail selection', () {
    test('selectAlbum clears playlist detail state', () async {
      final cacheStore = _MockCacheStore();
      final client = _MockJellyfinClient();
      final playback = _MockPlaybackController();
      final sessionStore = _MockSessionStore();
      final settingsStore = _MockSettingsStore();
      final state = buildState(
        cacheStore: cacheStore,
        client: client,
        playback: playback,
        sessionStore: sessionStore,
        settingsStore: settingsStore,
      );
      addTearDown(state.dispose);

      const playlist = Playlist(
        id: 'playlist-detail',
        name: 'Playlist',
        trackCount: 1,
        imageUrl: null,
      );
      final playlistTracks = [_track('playlist-track')];
      final album = _album('target');
      final albumTracks = [_track('album-track')];

      when(
        () => cacheStore.loadPlaylistTracks(playlist.id),
      ).thenAnswer((_) async => playlistTracks);
      when(
        () => client.fetchPlaylistTracks(playlist.id),
      ).thenAnswer((_) async => playlistTracks);
      when(
        () => cacheStore.loadAlbumTracks(album.id),
      ).thenAnswer((_) async => const <MediaItem>[]);
      when(
        () => client.fetchAlbumTracks(album.id),
      ).thenAnswer((_) async => albumTracks);
      when(
        () => cacheStore.saveAlbumTracks(album.id, albumTracks),
      ).thenAnswer((_) async {});

      await state.selectPlaylist(playlist);
      expect(state.selectedPlaylist, playlist);
      expect(state.playlistTracks, playlistTracks);

      await state.selectAlbum(album);

      expect(state.selectedPlaylist, isNull);
      expect(state.playlistTracks, isEmpty);
      expect(state.selectedAlbum, album);
      expect(state.albumTracks, albumTracks);
    });

    test('late album fetch cannot overwrite newer album selection', () async {
      final cacheStore = _MockCacheStore();
      final client = _MockJellyfinClient();
      final playback = _MockPlaybackController();
      final sessionStore = _MockSessionStore();
      final settingsStore = _MockSettingsStore();
      final state = buildState(
        cacheStore: cacheStore,
        client: client,
        playback: playback,
        sessionStore: sessionStore,
        settingsStore: settingsStore,
      );
      addTearDown(state.dispose);

      final firstAlbum = _album('first');
      final secondAlbum = _album('second');
      final firstTracks = [_track('first-track')];
      final secondTracks = [_track('second-track')];
      final firstFetch = Completer<List<MediaItem>>();
      final secondFetch = Completer<List<MediaItem>>();

      when(
        () => cacheStore.loadAlbumTracks(firstAlbum.id),
      ).thenAnswer((_) async => const <MediaItem>[]);
      when(
        () => cacheStore.loadAlbumTracks(secondAlbum.id),
      ).thenAnswer((_) async => const <MediaItem>[]);
      when(
        () => client.fetchAlbumTracks(firstAlbum.id),
      ).thenAnswer((_) => firstFetch.future);
      when(
        () => client.fetchAlbumTracks(secondAlbum.id),
      ).thenAnswer((_) => secondFetch.future);
      when(
        () => cacheStore.saveAlbumTracks(secondAlbum.id, secondTracks),
      ).thenAnswer((_) async {});

      final firstSelection = state.selectAlbum(firstAlbum);
      await Future<void>.delayed(Duration.zero);

      final secondSelection = state.selectAlbum(secondAlbum);
      secondFetch.complete(secondTracks);
      await secondSelection;

      firstFetch.complete(firstTracks);
      await firstSelection;

      expect(state.selectedAlbum, secondAlbum);
      expect(state.albumTracks, secondTracks);
    });
  });

  group('AppState smart lists', () {
    test('selectSmartList evaluates tracks beyond the first library page',
        () async {
      final cacheStore = _MockCacheStore();
      final client = _MockJellyfinClient();
      final playback = _MockPlaybackController();
      final sessionStore = _MockSessionStore();
      final settingsStore = _MockSettingsStore();
      final state = buildState(
        cacheStore: cacheStore,
        client: client,
        playback: playback,
        sessionStore: sessionStore,
        settingsStore: settingsStore,
      );
      addTearDown(state.dispose);
      stubSignedInRefresh(
        cacheStore: cacheStore,
        client: client,
        sessionStore: sessionStore,
      );

      final firstPage = List.generate(
        100,
        (index) => _track('page-1-$index'),
      );
      final match = _track('target', title: 'Needle Track');
      final secondPage = [match];
      final smartList = _titleContainsSmartList('Needle');

      when(
        () => client.fetchLibraryTracks(startIndex: 0, limit: 100),
      ).thenAnswer((_) async => firstPage);
      when(
        () => client.fetchLibraryTracks(startIndex: 100, limit: 100),
      ).thenAnswer((_) async => secondPage);

      await state.signIn(
        serverUrl: 'https://example.com',
        username: 'user',
        password: 'password',
      );

      await state.selectSmartList(smartList);

      expect(state.smartListTracks, [match]);
      final captured = verify(
        () => cacheStore.saveLibraryTracks(captureAny()),
      ).captured.single as List<MediaItem>;
      expect(captured, [...firstPage, ...secondPage]);
    });

    test('selectSmartList can build from cached library snapshot', () async {
      final cacheStore = _MockCacheStore();
      final client = _MockJellyfinClient();
      final playback = _MockPlaybackController();
      final sessionStore = _MockSessionStore();
      final settingsStore = _MockSettingsStore();
      final state = buildState(
        cacheStore: cacheStore,
        client: client,
        playback: playback,
        sessionStore: sessionStore,
        settingsStore: settingsStore,
      );
      addTearDown(state.dispose);

      final match = _track('cached-target', title: 'Cached Needle');
      final smartList = _titleContainsSmartList('Needle');
      when(
        () => cacheStore.loadLibraryTracks(),
      ).thenAnswer((_) async => [match]);

      await state.selectSmartList(smartList);

      expect(state.smartListTracks, [match]);
      verifyNever(
        () => client.fetchLibraryTracks(
          startIndex: any(named: 'startIndex'),
          limit: any(named: 'limit'),
        ),
      );
    });
  });

  group('AppState track status icons', () {
    test('returns downloaded for pinned tracks with no queue entry', () async {
      final cacheStore = _MockCacheStore();
      final client = _MockJellyfinClient();
      final playback = _MockPlaybackController();
      final sessionStore = _MockSessionStore();
      final settingsStore = _MockSettingsStore();
      final state = buildState(
        cacheStore: cacheStore,
        client: client,
        playback: playback,
        sessionStore: sessionStore,
        settingsStore: settingsStore,
      );
      addTearDown(state.dispose);

      final track = _track('status-downloaded');
      when(() => cacheStore.isAudioCached(track)).thenAnswer((_) async => true);

      await state.makeTrackAvailableOffline(track);

      expect(
        state.trackStatusForStreamUrl(track.streamUrl),
        TrackStatusIconState.downloaded,
      );
    });

    test('returns inQueue while download is queued', () async {
      final cacheStore = _MockCacheStore();
      final client = _MockJellyfinClient();
      final playback = _MockPlaybackController();
      final sessionStore = _MockSessionStore();
      final settingsStore = _MockSettingsStore();
      final state = buildState(
        cacheStore: cacheStore,
        client: client,
        playback: playback,
        sessionStore: sessionStore,
        settingsStore: settingsStore,
      );
      addTearDown(state.dispose);

      final track = _track('status-queued');
      when(() => cacheStore.isAudioCached(track))
          .thenAnswer((_) async => false);
      await state.setDownloadsPaused(true);
      await state.makeTrackAvailableOffline(track);

      expect(
        state.trackStatusForStreamUrl(track.streamUrl),
        TrackStatusIconState.inQueue,
      );
      expect(state.downloadQueue, hasLength(1));
      expect(state.downloadQueue.single.status, DownloadStatus.queued);
    });

    test('returns none when latest queue status is failed', () async {
      final cacheStore = _MockCacheStore();
      final client = _MockJellyfinClient();
      final playback = _MockPlaybackController();
      final sessionStore = _MockSessionStore();
      final settingsStore = _MockSettingsStore();
      final state = buildState(
        cacheStore: cacheStore,
        client: client,
        playback: playback,
        sessionStore: sessionStore,
        settingsStore: settingsStore,
      );
      addTearDown(state.dispose);

      final track = _track('status-failed');
      when(() => cacheStore.isAudioCached(track))
          .thenAnswer((_) async => false);
      when(
        () => cacheStore.downloadAudioWithProgress(
          track,
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
          (_) => Stream<FileResponse>.error(Exception('download failed')));

      await state.makeTrackAvailableOffline(track);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(state.downloadQueue, hasLength(1));
      expect(state.downloadQueue.single.status, DownloadStatus.failed);
      expect(
        state.trackStatusForStreamUrl(track.streamUrl),
        TrackStatusIconState.none,
      );
    });
  });
}
