import 'package:flutter/material.dart';
import 'glass_empty_state.dart';

/// Empty state for offline sections.
class OfflineEmptyView extends StatelessWidget {
  /// Creates an offline empty view.
  const OfflineEmptyView({
    super.key,
    required this.subtitle,
  });

  /// Supporting subtitle.
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return GlassEmptyState(
      icon: Icons.download_done_rounded,
      title: 'Nothing downloaded yet.',
      subtitle: subtitle,
      footer: 'Pin music to make it available offline.',
    );
  }
}
