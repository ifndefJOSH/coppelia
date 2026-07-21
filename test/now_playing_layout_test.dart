import 'package:flutter_test/flutter_test.dart';
import 'package:coppelia/state/now_playing_layout.dart';

void main() {
  test('side panel preference falls back to bottom below wide breakpoint', () {
    expect(
      effectiveNowPlayingLayout(
        preferredLayout: NowPlayingLayout.side,
        maxWidth: nowPlayingSidePanelBreakpoint - 1,
      ),
      NowPlayingLayout.bottom,
    );
  });

  test('side panel preference is honored at wide breakpoint', () {
    expect(
      effectiveNowPlayingLayout(
        preferredLayout: NowPlayingLayout.side,
        maxWidth: nowPlayingSidePanelBreakpoint,
      ),
      NowPlayingLayout.side,
    );
  });

  test('bottom bar preference is always honored', () {
    expect(
      effectiveNowPlayingLayout(
        preferredLayout: NowPlayingLayout.bottom,
        maxWidth: nowPlayingSidePanelBreakpoint + 200,
      ),
      NowPlayingLayout.bottom,
    );
  });

  test('side panel label describes adaptive behavior', () {
    expect(NowPlayingLayout.side.label, 'Side panel on wide screens');
  });
}
