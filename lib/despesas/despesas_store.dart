import 'package:flutter/material.dart';

import 'despesas_cache.dart';
import 'despesas_repository.dart';
import 'models/despesa_lancamento.dart';

class DespesasStore extends ChangeNotifier {
  final DespesasRepository _repository = DespesasRepository();
  final DespesasCache _cache = DespesasCache();

  List<DespesaLancamento> _todos = [];
  bool isLoading = false;
  String? error;
  String? _mesSelecionado; // YYYY-MM
  int? _diaSelecionado; // null = visão mensal, int = drill-down dia

  bool get isEmpty => _todos.isEmpty;

  // ── Meses disponíveis ────────────────────────────────────────────────────

  List<String> get mesesDisponiveis {
    final set = <String>{};
    for (final l in _todos) {
      set.add(l.mesKey);
    }
    return (set.toList()..sort()).reversed.toList();
  }

  String get mesSelecionado =>
      _mesSelecionado ?? _mesAtualOuUltimo();

  bool get hasPreviousMes {
    final idx = mesesDisponiveis.indexOf(mesSelecionado);
    return idx < mesesDisponiveis.length - 1;
  }

  bool get hasNextMes {
    final idx = mesesDisponiveis.indexOf(mesSelecionado);
    return idx > 0;
  }

  String get mesNome => _nomeDoMes(mesSelecionado);

  // ── Drill-down por dia ───────────────────────────────────────────────────

  int? get diaSelecionado => _diaSelecionado;

  List<int> get diasComDespesasNoMes {
    final set = <int>{};
    for (final l in _todos) {
      if (l.mesKey == mesSelecionado) set.add(l.dia);
    }
    return (set.toList()..sort());
  }

  void selecionarDia(int dia) {
    _diaSelecionado = dia;
    notifyListeners();
  }

  void limparDia() {
    _diaSelecionado = null;
    notifyListeners();
  }

  // ── Lançamentos filtrados ────────────────────────────────────────────────

  List<DespesaLancamento> get lancamentosMesSelecionado =>
      _todos.where((l) => l.mesKey == mesSelecionado).toList();

  List<DespesaLancamento> get lancamentosDiaSelecionado {
    if (_diaSelecionado == null) return [];
    return _todos
        .where((l) =>
            l.mesKey == mesSelecionado && l.dia == _diaSelecionado)
        .toList();
  }

  // ── Stats do mês selecionado ─────────────────────────────────────────────

  double get totalMesSelecionado =>
      lancamentosMesSelecionado.fold(0.0, (s, l) => s + l.valor);

  double get totalMesAnterior {
    final anterior = _mesAnteriorKey(mesSelecionado);
    if (anterior == null) return 0.0;
    return _todos
        .where((l) => l.mesKey == anterior)
        .fold(0.0, (s, l) => s + l.valor);
  }

  double? get variacaoVsMesAnterior {
    final ant = totalMesAnterior;
    if (ant == 0) return null;
    return ((totalMesSelecionado - ant) / ant) * 100;
  }

  double get mediaHistorica {
    if (mesesDisponiveis.isEmpty) return 0.0;
    final total =
        _todos.fold(0.0, (s, l) => s + l.valor);
    return total / mesesDisponiveis.length;
  }

  /// Retorna o mes key com maior total de despesas
  String? get mesComMaiorGastoKey {
    if (mesesDisponiveis.isEmpty) return null;
    String? melhor;
    double maior = 0;
    for (final mes in mesesDisponiveis) {
      final total =
          _todos.where((l) => l.mesKey == mes).fold(0.0, (s, l) => s + l.valor);
      if (total > maior) {
        maior = total;
        melhor = mes;
      }
    }
    return melhor;
  }

  double get totalMesComMaiorGasto {
    final key = mesComMaiorGastoKey;
    if (key == null) return 0.0;
    return _todos
        .where((l) => l.mesKey == key)
        .fold(0.0, (s, l) => s + l.valor);
  }

  // ── Evolução mensal (últimos 6 meses + selecionado) ─────────────────────

  List<DespesaEvolucaoMes> get evolucaoMensal {
    // Pega até 6 meses mais recentes
    final meses = mesesDisponiveis.take(6).toList().reversed.toList();
    return meses.map((mesKey) {
      final total = _todos
          .where((l) => l.mesKey == mesKey)
          .fold(0.0, (s, l) => s + l.valor);
      return DespesaEvolucaoMes(mesKey: mesKey, total: total);
    }).toList();
  }

  // ── Evolução diária do mês selecionado ──────────────────────────────────

  List<DespesaEvolucaoDia> get evolucaoDiariaMes {
    final Map<int, double> porDia = {};
    for (final l in lancamentosMesSelecionado) {
      porDia[l.dia] = (porDia[l.dia] ?? 0.0) + l.valor;
    }
    return porDia.entries
        .map((e) => DespesaEvolucaoDia(dia: e.key, total: e.value))
        .toList()
      ..sort((a, b) => a.dia.compareTo(b.dia));
  }

  // ── Top categorias do mês ────────────────────────────────────────────────

  List<MapEntry<String, double>> get topCategoriasMes {
    final Map<String, double> map = {};
    for (final l in lancamentosMesSelecionado) {
      map[l.categoria] = (map[l.categoria] ?? 0.0) + l.valor;
    }
    final list = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(8).toList();
  }

  // ── Despesas por unidade no mês ──────────────────────────────────────────

  List<MapEntry<String, double>> get despesasPorUnidadeMes {
    final Map<String, double> map = {};
    for (final l in lancamentosMesSelecionado) {
      map[l.unidade] = (map[l.unidade] ?? 0.0) + l.valor;
    }
    final list = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  // ── Gastos futuros ───────────────────────────────────────────────────────

  List<DespesaLancamento> get gastosFuturos {
    final hoje = DateTime.now();
    return _todos.where((l) {
      if (l.data.isEmpty) return false;
      try {
        final data = DateTime.parse(l.data);
        return data.isAfter(hoje);
      } catch (_) {
        return false;
      }
    }).toList()
      ..sort((a, b) => a.data.compareTo(b.data));
  }

  double get totalGastosFuturos =>
      gastosFuturos.fold(0.0, (s, l) => s + l.valor);

  // ── Categorias e unidades do dia (drill-down) ────────────────────────────

  Map<String, double> get despesasPorCategoriaDia {
    final Map<String, double> map = {};
    for (final l in lancamentosDiaSelecionado) {
      map[l.categoria] = (map[l.categoria] ?? 0.0) + l.valor;
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  double get totalDiaSelecionado =>
      lancamentosDiaSelecionado.fold(0.0, (s, l) => s + l.valor);

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> fetchData({bool forceRefresh = false}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Carregar do cache primeiro (se válido e não for refresh forçado)
      if (!forceRefresh && _cache.isCacheValid()) {
        final cached = _cache.loadDespesas();
        if (cached != null) {
          _todos = cached;
          _mesSelecionado = _mesAtualOuUltimo();
          _diaSelecionado = null;
          isLoading = false;
          notifyListeners();
          return;
        }
      }

      // Buscar do Firebase
      final resultado = await _repository.fetchDespesas();
      _todos = resultado;
      await _cache.saveDespesas(_todos);
      _mesSelecionado = _mesAtualOuUltimo();
      _diaSelecionado = null;
    } catch (e) {
      error = e.toString();
      // Fallback para cache mesmo expirado
      final cached = _cache.loadDespesas();
      if (cached != null) {
        _todos = cached;
        _mesSelecionado = _mesAtualOuUltimo();
        _diaSelecionado = null;
        error = 'Usando dados em cache. Erro: $e';
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void navegarMes(bool anterior) {
    final idx = mesesDisponiveis.indexOf(mesSelecionado);
    if (anterior && idx < mesesDisponiveis.length - 1) {
      _mesSelecionado = mesesDisponiveis[idx + 1];
      _diaSelecionado = null;
      notifyListeners();
    } else if (!anterior && idx > 0) {
      _mesSelecionado = mesesDisponiveis[idx - 1];
      _diaSelecionado = null;
      notifyListeners();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String formatarValor(double valor) {
    final partes = valor.toStringAsFixed(2).split('.');
    final inteiro = partes[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'R\$ $inteiro,${partes[1]}';
  }

  String _mesAtualOuUltimo() {
    if (mesesDisponiveis.isEmpty) return '';
    final hoje = DateTime.now();
    final hojeKey =
        '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}';
    return mesesDisponiveis.contains(hojeKey)
        ? hojeKey
        : mesesDisponiveis.first;
  }

  String? _mesAnteriorKey(String mesKey) {
    final idx = mesesDisponiveis.indexOf(mesKey);
    if (idx < 0 || idx >= mesesDisponiveis.length - 1) return null;
    return mesesDisponiveis[idx + 1];
  }

  String _nomeDoMes(String mesKey) {
    if (mesKey.isEmpty) return '';
    final parts = mesKey.split('-');
    if (parts.length != 2) return mesKey;
    const nomes = [
      '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];
    final mes = int.tryParse(parts[1]) ?? 0;
    final ano = parts[0];
    return '${nomes[mes]} $ano';
  }

  String nomeDoMesKey(String mesKey) => _nomeDoMes(mesKey);
}

// ── Modelos de evolução ──────────────────────────────────────────────────────

class DespesaEvolucaoDia {
  final int dia;
  final double total;
  DespesaEvolucaoDia({required this.dia, required this.total});
}

class DespesaEvolucaoMes {
  final String mesKey;
  final double total;
  DespesaEvolucaoMes({required this.mesKey, required this.total});
}
