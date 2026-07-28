import 'package:flutter/material.dart';

/// Shows a standard snack bar message.
void showAppSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

/// Runs an async action and shows an error or optional success message.
Future<void> runWithSnack(
  BuildContext context,
  Future<String?> Function() action, {
  String? successMessage,
}) async {
  final error = await action();
  if (!context.mounted) {
    return;
  }
  if (error != null) {
    showAppSnack(context, error);
  } else if (successMessage != null) {
    showAppSnack(context, successMessage);
  }
}
