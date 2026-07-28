import 'package:flutter/material.dart';

/// Shows a standard snack bar message.
void showAppSnack(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) {
    return;
  }
  _showSnack(messenger, message);
}

void _showSnack(ScaffoldMessengerState messenger, String message) {
  messenger.showSnackBar(
    SnackBar(content: Text(message)),
  );
}

/// Runs an async action and shows an error or optional success message.
Future<void> runWithSnack(
  BuildContext context,
  Future<String?> Function() action, {
  String? successMessage,
}) async {
  // Keep the messenger alive if the initiating widget rebuilds or is removed
  // while the request is in flight.
  final messenger = ScaffoldMessenger.maybeOf(context);
  final error = await action();
  if (messenger == null || !messenger.mounted) {
    return;
  }
  if (error != null) {
    _showSnack(messenger, error);
  } else if (successMessage != null) {
    _showSnack(messenger, successMessage);
  }
}
