/// Layout modes for the now playing surface.
enum NowPlayingLayout {
  /// Docked on the right side.
  side,

  /// Docked along the bottom edge.
  bottom,
}

/// Minimum available width before the side panel layout is usable.
const double nowPlayingSidePanelBreakpoint = 720;

/// Resolves the user's preferred layout against available screen width.
NowPlayingLayout effectiveNowPlayingLayout({
  required NowPlayingLayout preferredLayout,
  required double maxWidth,
}) {
  if (preferredLayout == NowPlayingLayout.side &&
      maxWidth < nowPlayingSidePanelBreakpoint) {
    return NowPlayingLayout.bottom;
  }
  return preferredLayout;
}

/// Human-friendly labels for layouts.
extension NowPlayingLayoutLabel on NowPlayingLayout {
  /// Label for UI controls.
  String get label {
    switch (this) {
      case NowPlayingLayout.side:
        return 'Side panel on wide screens';
      case NowPlayingLayout.bottom:
        return 'Bottom bar';
    }
  }
}
