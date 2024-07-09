import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
class CheckUpdates {
  final String currentVersion = 'v1.0.0';

  Future<bool> checkForUpdate(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse('https://api.github.com/repos/rikelmyso7/orama_admin/releases/latest'));

      if (response.statusCode == 200) {
        final latestRelease = jsonDecode(response.body);
        final latestVersion = latestRelease['tag_name'];
        final apkUrl = latestRelease['assets'][0]['browser_download_url'];

        if (latestVersion != currentVersion) {
          return await _showUpdateDialog(context, apkUrl);
        }
      } else {
        print('Failed to fetch latest release: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error fetching latest release: $error');
    }
    return true; // No update needed, allow navigation
  }

  Future<bool> _showUpdateDialog(BuildContext context, String apkUrl) async {
    bool updateCompleted = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Nova Versão Disponível'),
          content: Text('Uma nova versão do aplicativo está disponível. Deseja atualizar?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Atualizar'),
              onPressed: () async {
                Navigator.of(context).pop(); // Fechar o diálogo
                updateCompleted = await _downloadAndUpdate(apkUrl);
              },
            ),
          ],
        );
      },
    );

    return updateCompleted;
  }

  Future<bool> _downloadAndUpdate(String apkUrl) async {
    final dio = Dio();
    final dir = await getExternalStorageDirectory();
    final filePath = '${dir!.path}/orama_admin.apk';

    await _requestInstallPermission();

    try {
      print('Iniciando download do APK...');
      await dio.download(apkUrl, filePath);
      print('Download concluído: $filePath');

      await _installApk(filePath);
      return false; // Prevent navigation to home screen immediately
    } catch (e) {
      print('Erro ao baixar o arquivo: $e');
      return true; // Allow navigation to home screen if there's an error
    }
  }

  Future<void> _requestInstallPermission() async {
    if (await Permission.requestInstallPackages.isGranted) {
      print("Permissão para instalar pacotes concedida");
    } else {
      bool isOpened = await openAppSettings();
      if (isOpened) {
        await _waitForPermission();
      } else {
        print("Permissão para instalar pacotes negada");
      }
    }
  }

  Future<void> _waitForPermission() async {
    while (true) {
      await Future.delayed(Duration(seconds: 1));
      if (await Permission.requestInstallPackages.isGranted) {
        break;
      }
    }
  }

  Future<void> _installApk(String filePath) async {
    try {
      //final installer = FlutterAppInstaller();
      //await installer.installApk(filePath: filePath);
    } catch (e) {
      print('Erro ao instalar o APK: $e');
    }
  }
}
