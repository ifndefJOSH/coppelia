/// Layout styles for media shelves on Home.
enum HomeShelfLayout {
  /// Horizontal scroller layout.
  whooshy,

  /// Compact grid layout.
  grid,
}

extension HomeShelfLayoutMeta on HomeShelfLayout {
  /// Display label for settings UI.
  String get label {
    switch (this) {
      case HomeShelfLayout.whooshy:
        return 'Whooshy';
      case HomeShelfLayout.grid:
        return 'Grid';
    }
  }
}
