import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import '../main.dart';
import 'models/pdv_model.dart';
import 'models/venda_dia_model.dart';
import 'models/venda_diaria_model.dart';
import 'models/mes_disponivel_model.dart';
import 'models/vendas_data_model.dart';

class VendasRepository {
  static const _invalidKeys = ['data', 'total_de_vendas_ate_o_dia_15_do_mes'];

  Future<VendasData> fetchVendasData() async {
    // Usa a instância global do Realtime Database
    final snapshot = await salesDatabase.ref('/').get();

    if (!snapshot.exists) {
      throw Exception('Nenhum dado encontrado no Firebase');
    }

    final rawData = snapshot.value;
    if (rawData == null) {
      throw Exception('Nenhum dado encontrado no Firebase');
    }

    // Converte para Map<String, dynamic>
    final data = Map<String, dynamic>.from(rawData as Map);

    // Processar stores
    final rawStoresMap = data['stores'];
    final storesMap = rawStoresMap != null
        ? Map<String, dynamic>.from(rawStoresMap as Map)
        : <String, dynamic>{};
    final pdvs = _processStores(storesMap);

    // Processar vendas diárias
    final rawDailySalesMap = data['dailySales'];
    final dailySalesMap = rawDailySalesMap != null
        ? Map<String, dynamic>.from(rawDailySalesMap as Map)
        : <String, dynamic>{};
    final vendasDiarias = _processDailySales(dailySalesMap, storesMap);

    // Agrupar por mês
    final vendasPorMes = _groupByMonth(vendasDiarias);

    // Obter meses disponíveis
    final mesesDisponiveis = _getAvailableMonths(vendasPorMes);

    return VendasData(
      pdvs: pdvs,
      vendasPorMes: vendasPorMes,
      mesesDisponiveis: mesesDisponiveis,
      ultimaAtualizacao: DateTime.now(),
    );
  }

  List<PDV> _processStores(Map<String, dynamic> storesMap) {
    return storesMap.entries
        .where((e) => !_invalidKeys.contains(e.key))
        .where((e) {
          final value = e.value;
          if (value is Map) {
            return value['active'] == true;
          }
          return false;
        })
        .map((e) => PDV.fromMap(
              e.key,
              Map<dynamic, dynamic>.from(e.value as Map),
            ))
        .toList();
  }

  List<VendaDiaria> _processDailySales(
    Map<String, dynamic> dailySalesMap,
    Map<String, dynamic> storesMap,
  ) {
    final List<VendaDiaria> vendas = [];

    for (final entry in dailySalesMap.entries) {
      final dateStr = entry.key;
      final salesData = entry.value;

      if (salesData == null) continue;

      // Parse date (YYYY-MM-DD)
      final parts = dateStr.split('-');
      if (parts.length != 3) continue;

      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);

      if (year == null || month == null || day == null) continue;

      final List<VendaDia> sales = [];
      double total = 0;

      // Converte salesData para Map<String, dynamic>
      final salesMap = salesData is Map
          ? Map<String, dynamic>.from(salesData as Map)
          : <String, dynamic>{};

      for (final saleEntry in salesMap.entries) {
        final storeId = saleEntry.key;
        final valor = saleEntry.value;

        if (_invalidKeys.contains(storeId)) continue;

        // Verificar se o store está ativo
        final storeData = storesMap[storeId];
        if (storeData != null && storeData is Map) {
          final storeMap = Map<String, dynamic>.from(storeData as Map);
          if (storeMap['active'] != true) continue;

          final valorDouble = valor is num ? valor.toDouble() : 0.0;
          if (valorDouble <= 0) continue;

          final storeName = storeMap['name']?.toString() ?? storeId;

          sales.add(VendaDia(
            storeId: storeId,
            storeName: storeName,
            valor: valorDouble,
          ));
          total += valorDouble;
        }
      }

      if (sales.isNotEmpty) {
        vendas.add(VendaDiaria(
          date: dateStr,
          year: year,
          month: month,
          day: day,
          sales: sales,
          total: total,
        ));
      }
    }

    // Ordenar por data
    vendas.sort((a, b) => a.date.compareTo(b.date));
    return vendas;
  }

  Map<String, List<VendaDiaria>> _groupByMonth(List<VendaDiaria> vendas) {
    final Map<String, List<VendaDiaria>> grouped = {};

    for (final venda in vendas) {
      final mesKey =
          '${venda.year}-${venda.month.toString().padLeft(2, '0')}';

      grouped.putIfAbsent(mesKey, () => []);
      grouped[mesKey]!.add(venda);
    }

    return grouped;
  }

  List<MesDisponivel> _getAvailableMonths(
      Map<String, List<VendaDiaria>> vendasPorMes) {
    final List<MesDisponivel> meses = [];

    for (final entry in vendasPorMes.entries) {
      final parts = entry.key.split('-');
      if (parts.length != 2) continue;

      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);

      if (year == null || month == null) continue;

      final diasComVendas = entry.value.map((v) => v.day).toList()..sort();

      meses.add(MesDisponivel(
        key: entry.key,
        year: year,
        month: month,
        diasComVendas: diasComVendas,
      ));
    }

    // Ordenar por data (mais recente primeiro)
    meses.sort((a, b) => b.key.compareTo(a.key));
    return meses;
  }
}
