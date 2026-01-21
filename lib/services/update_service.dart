import 'dart:developer' as dev;
import 'package:app_installer/app_installer.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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

  /// Compara duas versões no formato semântico (ex: "2.7.6")
  /// Retorna: -1 se v1 < v2, 0 se v1 == v2, 1 se v1 > v2
  static int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLength = parts1.length > parts2.length ? parts1.length : parts2.length;

    for (int i = 0; i < maxLength; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;

      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }

    return 0;
  }

  static Future<UpdateInfo?> checkForUpdate() async {
    dev.log('🔍 Iniciando verificação de atualização…', name: _logName);

    try {
      // 1. Versão instalada
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      dev.log('Versão instalada: $currentVersion', name: _logName);

      // 2. Consulta à API do GitHub
      const owner = 'rikelmyso7';
      const repo = 'orama_admin';
      final url = 'https://api.github.com/repos/$owner/$repo/releases/latest';

      dev.log('🌐 Consultando GitHub: $url', name: _logName);
      final response = await Dio().get(url);

      if (response.statusCode != 200 || response.data == null) {
        dev.log('❌ Falha ao consultar GitHub API', name: _logName);
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      final tagName = data['tag_name']?.toString();

      if (tagName == null) {
        dev.log('❌ Release sem tag_name', name: _logName);
        return null;
      }

      // Remover 'v' do início se existir (ex: "v2.7.6" -> "2.7.6")
      final latestVersion = tagName.startsWith('v')
          ? tagName.substring(1)
          : tagName;

      dev.log('Versão mais recente no GitHub: $latestVersion', name: _logName);

      // 3. Comparar versões
      final comparison = _compareVersions(currentVersion, latestVersion);

      if (comparison >= 0) {
        dev.log('✅ App já está na última versão ou mais novo ($currentVersion >= $latestVersion).',
            name: _logName);
        return null;
      }

      // 4. Encontrar o APK nos assets
      final assets = data['assets'] as List<dynamic>?;
      if (assets == null || assets.isEmpty) {
        dev.log('❌ Release sem assets/APK', name: _logName);
        return null;
      }

      // Procurar por arquivo .apk
      final apkAsset = assets.firstWhere(
        (asset) => asset['name']?.toString().endsWith('.apk') ?? false,
        orElse: () => null,
      );

      if (apkAsset == null) {
        dev.log('❌ Nenhum APK encontrado nos assets', name: _logName);
        return null;
      }

      final apkUrl = apkAsset['browser_download_url']?.toString();
      if (apkUrl == null) {
        dev.log('❌ APK sem URL de download', name: _logName);
        return null;
      }

      // 5. Nova atualização disponível
      final info = UpdateInfo(
        latestVersion: latestVersion,
        apkUrl: apkUrl,
        title: 'Atualização disponível',
        message: data['body']?.toString() ?? 'Uma nova versão do aplicativo está disponível. Atualize agora!',
        version: latestVersion,
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

  Future<void> downloadAndInstall(
    String url, {
    Function(double progress, String downloaded, String total)? onDownloadProgress,
    Function(String status)? onStatusUpdate,
  }) async {
    final tempPath = '${(await getTemporaryDirectory()).path}/app-release.apk';
    dev.log('Caminho temporário: $tempPath', name: _logName);

    try {
      // 1. Baixar com progresso
      onStatusUpdate?.call('Iniciando download...');
      dev.log('🔽 Iniciando download do APK...', name: _logName);

      await Dio().download(
        url,
        tempPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            final downloadedMB = (received / 1024 / 1024).toStringAsFixed(1);
            final totalMB = (total / 1024 / 1024).toStringAsFixed(1);

            onDownloadProgress?.call(progress, downloadedMB, totalMB);
            dev.log('📈 Progresso download: ${(progress * 100).toStringAsFixed(1)}% ($downloadedMB/$totalMB MB)',
                name: _logName);
          }
        },
      );

      onStatusUpdate?.call('Download concluído. Preparando instalação...');
      dev.log('✅ Download concluído', name: _logName);

      // 2. Chamar instalador nativo
      onStatusUpdate?.call('Iniciando instalação...');
      dev.log('📱 Iniciando instalação do APK...', name: _logName);

      await AppInstaller.installApk(tempPath);

      onStatusUpdate?.call('Instalação iniciada');
      dev.log('🎉 Instalação iniciada com sucesso', name: _logName);

    } catch (e, s) {
      dev.log('❌ Erro durante download/instalação: $e',
          name: _logName, error: e, stackTrace: s);
      onStatusUpdate?.call('Erro: $e');
      rethrow;
    }
  }
}
