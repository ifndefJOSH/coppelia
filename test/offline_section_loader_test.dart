import 'package:coppelia/state/app_state.dart';
import 'package:coppelia/state/layout_density.dart';
import 'package:coppelia/ui/widgets/header_controls.dart';
import 'package:coppelia/ui/widgets/offline_section_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAppState extends Mock implements AppState {}

void main() {
  setUpAll(() {
    registerFallbackValue(() {});
  });

  testWidgets('empty offline section keeps menu and back controls', (
    tester,
  ) async {
    final state = _MockAppState();
    when(() => state.layoutDensity).thenReturn(LayoutDensity.comfortable);
    when(() => state.cornerRadiusScale).thenReturn(1);
    when(() => state.canGoBack).thenReturn(true);
    when(() => state.isSidebarCollapsed).thenReturn(false);
    when(() => state.isSidebarOverlayOpen).thenReturn(false);
    when(() => state.addListener(any())).thenAnswer((_) {});
    when(() => state.removeListener(any())).thenAnswer((_) {});

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
          home: Scaffold(
            body: SidebarMenuScope(
              autoCollapsed: true,
              child: OfflineSectionLoader<String>(
                future: Future.value(const []),
                emptyTitle: 'Offline Tracks',
                emptySubtitle: 'Tracks you have pinned for offline listening.',
                builder: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    expect(find.text('Offline Tracks'), findsWidgets);
    expect(find.text('Nothing downloaded yet.'), findsOneWidget);
  });
}
