import 'package:flutter/material.dart';
import 'package:orama_admin/services/update_service.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog {
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    required String apkUrl,
    required Color color,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mais tarde'),
          ),
          TextButton(
            onPressed: () => UpdateService().downloadAndInstall(apkUrl),
            child: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }
}
