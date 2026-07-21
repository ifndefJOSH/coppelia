import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../state/layout_density.dart';
import 'offline_empty_view.dart';
import 'page_header.dart';

/// Reusable loader + empty-state wrapper for offline sections.
class OfflineSectionLoader<T> extends StatelessWidget {
  const OfflineSectionLoader({
    super.key,
    required this.future,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.builder,
  });

  final Future<List<T>> future;
  final String emptyTitle;
  final String emptySubtitle;
  final Widget Function(BuildContext context, List<T> items) builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? <T>[];
        if (snapshot.connectionState == ConnectionState.waiting &&
            items.isEmpty) {
          return _OfflineSectionStatus(
            title: emptyTitle,
            subtitle: emptySubtitle,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (items.isEmpty) {
          return _OfflineSectionStatus(
            title: emptyTitle,
            subtitle: emptySubtitle,
            child: OfflineEmptyView(
              subtitle: emptySubtitle,
            ),
          );
        }
        return builder(context, items);
      },
    );
  }
}

class _OfflineSectionStatus extends StatelessWidget {
  const _OfflineSectionStatus({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final densityScale = context.watch<AppState>().layoutDensity.scaleDouble;
    final leftGutter = (32 * densityScale).clamp(16.0, 40.0).toDouble();
    final rightGutter = (24 * densityScale).clamp(12.0, 32.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(leftGutter, 0, rightGutter, 0),
          child: PageHeader(
            title: title,
            subtitle: subtitle,
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
