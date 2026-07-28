import 'dart:async';

import 'package:coppelia/ui/widgets/app_snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<BuildContext> pumpScaffold(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox())),
    );
    return tester.element(find.byType(Scaffold));
  }

  testWidgets('runWithSnack shows its success message after success', (
    tester,
  ) async {
    final context = await pumpScaffold(tester);

    await runWithSnack(
      context,
      () async => null,
      successMessage: 'Added "The Track" to "Favorites".',
    );
    await tester.pump();

    expect(
      find.text('Added "The Track" to "Favorites".'),
      findsOneWidget,
    );
  });

  testWidgets('runWithSnack prioritizes an error over its success message', (
    tester,
  ) async {
    final context = await pumpScaffold(tester);

    await runWithSnack(
      context,
      () async => 'Unable to add to playlist.',
      successMessage: 'Added "The Track" to "Favorites".',
    );
    await tester.pump();

    expect(find.text('Unable to add to playlist.'), findsOneWidget);
    expect(
      find.text('Added "The Track" to "Favorites".'),
      findsNothing,
    );
  });

  testWidgets('runWithSnack survives the source widget being removed', (
    tester,
  ) async {
    final action = Completer<String?>();
    var showSource = true;
    late BuildContext sourceContext;
    late StateSetter setSourceState;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setSourceState = setState;
              if (!showSource) {
                return const SizedBox();
              }
              return Builder(
                builder: (context) {
                  sourceContext = context;
                  return const SizedBox();
                },
              );
            },
          ),
        ),
      ),
    );

    final future = runWithSnack(
      sourceContext,
      () => action.future,
      successMessage: 'Added "The Track" to "Favorites".',
    );
    setSourceState(() => showSource = false);
    await tester.pump();
    action.complete(null);
    await future;
    await tester.pump();

    expect(
      find.text('Added "The Track" to "Favorites".'),
      findsOneWidget,
    );
  });
}
