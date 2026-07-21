import 'package:coppelia/state/app_state.dart';
import 'package:coppelia/ui/widgets/header_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAppState extends Mock implements AppState {}

void main() {
  setUpAll(() {
    registerFallbackValue(() {});
  });

  testWidgets(
    'sidebar menu shows when content area is auto-collapsed',
    (tester) async {
      final state = _MockAppState();
      when(() => state.isSidebarCollapsed).thenReturn(false);
      when(() => state.isSidebarOverlayOpen).thenReturn(false);
      when(() => state.cornerRadiusScale).thenReturn(1);
      when(() => state.addListener(any())).thenAnswer((_) {});
      when(() => state.removeListener(any())).thenAnswer((_) {});

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: const MaterialApp(
            home: Scaffold(
              body: SidebarMenuScope(
                autoCollapsed: true,
                child: SidebarMenuButton(),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.menu), findsOneWidget);
    },
  );

  testWidgets(
    'sidebar menu hides when sidebar is visible',
    (tester) async {
      final state = _MockAppState();
      when(() => state.isSidebarCollapsed).thenReturn(false);
      when(() => state.isSidebarOverlayOpen).thenReturn(false);
      when(() => state.cornerRadiusScale).thenReturn(1);
      when(() => state.addListener(any())).thenAnswer((_) {});
      when(() => state.removeListener(any())).thenAnswer((_) {});

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: const MaterialApp(
            home: Scaffold(
              body: SidebarMenuScope(
                autoCollapsed: false,
                child: SidebarMenuButton(),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.menu), findsNothing);
    },
  );
}
