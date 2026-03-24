import 'dart:convert';
import 'package:get_storage/get_storage.dart';

import 'models/despesa_lancamento.dart';

class DespesasCache {
  static const _storageKey = 'despesas_cache';
  static const _timestampKey = 'despesas_cache_timestamp';

  final GetStorage _storage = GetStorage();

  Future<void> saveDespesas(List<DespesaLancamento> lancamentos) async {
    final json = lancamentos
        .map((l) => {
              'dia': l.dia,
              'data': l.data,
              'categoria': l.categoria,
              'tipo': l.tipo,
              'metodo': l.metodo,
              'valor': l.valor,
              'pdv': l.pdv,
              'unidade': l.unidade,
              'mesKey': l.mesKey,
            })
        .toList();
    await _storage.write(_storageKey, jsonEncode(json));
    await _storage.write(_timestampKey, DateTime.now().toIso8601String());
  }

  List<DespesaLancamento>? loadDespesas() {
    final jsonStr = _storage.read<String>(_storageKey);
    if (jsonStr == null) return null;

    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((item) => DespesaLancamento.fromJson(
              Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      print('Erro ao carregar cache de despesas: $e');
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
