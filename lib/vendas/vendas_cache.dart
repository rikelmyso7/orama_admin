import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'models/vendas_data_model.dart';

class VendasCache {
  static const _storageKey = 'vendas_cache';
  static const _timestampKey = 'vendas_cache_timestamp';

  final GetStorage _storage = GetStorage();

  Future<void> saveVendasData(VendasData data) async {
    await _storage.write(_storageKey, jsonEncode(data.toJson()));
    await _storage.write(_timestampKey, DateTime.now().toIso8601String());
  }

  VendasData? loadVendasData() {
    final jsonStr = _storage.read<String>(_storageKey);
    if (jsonStr == null) return null;

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return VendasData.fromJson(json);
    } catch (e) {
      print('Erro ao carregar cache de vendas: $e');
      return null;
    }
  }

  bool isCacheValid({Duration maxAge = const Duration(minutes: 30)}) {
    final timestamp = _storage.read<String>(_timestampKey);
    if (timestamp == null) return false;

    try {
      final cacheTime = DateTime.parse(timestamp);
      return DateTime.now().difference(cacheTime) < maxAge;
    } catch (e) {
      return false;
    }
  }

  DateTime? getCacheTimestamp() {
    final timestamp = _storage.read<String>(_timestampKey);
    if (timestamp == null) return null;

    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearCache() async {
    await _storage.remove(_storageKey);
    await _storage.remove(_timestampKey);
  }
}
