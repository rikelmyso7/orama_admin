import 'dart:developer' as dev;
import 'package:app_installer/app_installer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:orama_admin/main.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final String latestVersion;
  final String apkUrl;
  final String title;
  final String message;
  final String version;

  UpdateInfo({
    required this.latestVersion,
    required this.apkUrl,
    required this.title,
    required this.message,
    required this.version,
  });

  @override
  String toString() =>
      'UpdateInfo(latest=$latestVersion, url=$apkUrl, title=$title)';
}

class UpdateService {
  static const _logName = 'UpdateService';

  static Future<UpdateInfo?> checkForUpdate() async {
    dev.log('🔍 Iniciando verificação de atualização…', name: _logName);

    try {
      // 1. Versão instalada
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      dev.log('Versão instalada: $currentVersion', name: _logName);

      // 2. Consulta ao Firestore
      final FirebaseFirestore _firestore = primaryFirestore;
      final doc = await _firestore
          .collection('app_updates')
          .doc('orama_admin')
          .get();

      final data = doc.data();
      dev.log('Docs recebidos: $data', name: _logName);

      if (data == null || data['version'] == null || data['apk_url'] == null) {
        dev.log('❌ Documento incompleto ou inexistente — sem atualização.',
            name: _logName);
        return null;
      }

      final latestVersion = data['version'].toString();
      if (latestVersion == currentVersion) {
        dev.log('✅ App já está na última versão ($currentVersion).',
            name: _logName);
        return null;
      }

      // 3. Nova atualização disponível
      final info = UpdateInfo(
        latestVersion: latestVersion,
        apkUrl: data['apk_url'].toString(),
        title: data['title']?.toString() ?? 'Nova versão disponível',
        message: data['message']?.toString() ??
            'Há uma nova versão do app disponível.',
        version: data['version']?.toString() ?? '',
      );

      dev.log('🚀 Atualização encontrada: $info', name: _logName);
      return info;
    } catch (e, s) {
      dev.log('⚠️ Erro ao checar atualização: $e',
          name: _logName, error: e, stackTrace: s);
      return null;
    }
  }

  Future<void> openApk(String url) async {
    final canLaunch = await canLaunchUrl(Uri.parse(url));
    print('Pode abrir? $canLaunch');

    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      debugPrint('❌ Não foi possível abrir $url');
    }
  }

  Future<void> downloadAndInstall(String url) async {
    final tempPath = '${(await getTemporaryDirectory()).path}/app-release.apk';
    debugPrint(tempPath);
    // 1. Baixar (exibe progresso se quiser)
    debugPrint('Baixando..');
    await Dio().download(url, tempPath);

    // 2. Chamar instalador nativo (abre diálogo)
    debugPrint('Instalando..');
    await AppInstaller.installApk(tempPath);
  }
}
