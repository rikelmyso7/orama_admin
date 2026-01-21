import 'package:mobx/mobx.dart';

import 'models/mes_disponivel_model.dart';
import 'models/vendas_data_model.dart';
import 'constants/pdv_constants.dart';
import 'vendas_repository.dart';
import 'vendas_cache.dart';

part 'vendas_store.g.dart';

class VendasStore = _VendasStore with _$VendasStore;

enum DirecaoNavegacao { anterior, proximo }

abstract class _VendasStore with Store {
  final VendasRepository _repository = VendasRepository();
  final VendasCache _cache = VendasCache();

  _VendasStore();

  // Observables
  @observable
  VendasData? data;

  @observable
  bool isLoading = false;

  @observable
  String? error;

  @observable
  MesDisponivel? mesSelecionado;

  @observable
  int diaSelecionado = 1;

  // Computed
  @computed
  List<int> get diasDisponiveis => mesSelecionado?.diasComVendas ?? [];

  @computed
  bool get hasPreviousDay {
    final index = diasDisponiveis.indexOf(diaSelecionado);
    return index > 0;
  }

  @computed
  bool get hasNextDay {
    final index = diasDisponiveis.indexOf(diaSelecionado);
    return index >= 0 && index < diasDisponiveis.length - 1;
  }

  @computed
  bool get hasPreviousMonth {
    if (mesSelecionado == null || data == null) return false;
    final mesesOrdenados = _getMesesOrdenados();
    final indexAtual = mesesOrdenados.indexWhere((m) => m.key == mesSelecionado!.key);
    return indexAtual > 0;
  }

  @computed
  bool get hasNextMonth {
    if (mesSelecionado == null || data == null) return false;
    final mesesOrdenados = _getMesesOrdenados();
    final indexAtual = mesesOrdenados.indexWhere((m) => m.key == mesSelecionado!.key);
    return indexAtual >= 0 && indexAtual < mesesOrdenados.length - 1;
  }

  @computed
  List<int> get anosDisponiveis {
    if (data == null) return [];
    final anos = data!.mesesDisponiveis.map((m) => m.year).toSet().toList()..sort();
    return anos.reversed.toList(); // Mais recente primeiro
  }

  @computed
  EstatisticasDia get estatisticasDia {
    if (mesSelecionado == null || data == null) {
      return EstatisticasDia.empty();
    }
    return _calcularEstatisticasDia(mesSelecionado!.key, diaSelecionado);
  }

  @computed
  List<VendaPDV> get vendasPorPDV {
    if (mesSelecionado == null || data == null) return [];
    return _getVendasPorPDVDia(mesSelecionado!.key, diaSelecionado);
  }

  @computed
  List<EvolucaoDia> get evolucaoMes {
    if (mesSelecionado == null || data == null) return [];
    return _getEvolucaoMes(mesSelecionado!.key);
  }

  @computed
  double get totalMes => evolucaoMes.fold(0.0, (sum, dia) => sum + dia.total);

  @computed
  Map<CategoriaPDV, List<VendaPDV>> get vendasPorCategoria {
    final Map<CategoriaPDV, List<VendaPDV>> resultado = {
      CategoriaPDV.loja: [],
      CategoriaPDV.turismo: [],
      CategoriaPDV.evento: [],
    };

    for (final venda in vendasPorPDV) {
      final categoria = getCategoria(venda.storeId);
      resultado[categoria]!.add(venda);
    }

    return resultado;
  }

  @computed
  double get totalDiaLojas {
    return vendasPorCategoria[CategoriaPDV.loja]!
        .fold(0.0, (sum, v) => sum + v.valor);
  }

  @computed
  double get totalDiaTurismo {
    return vendasPorCategoria[CategoriaPDV.turismo]!
        .fold(0.0, (sum, v) => sum + v.valor);
  }

  @computed
  double get totalDiaEventos {
    return vendasPorCategoria[CategoriaPDV.evento]!
        .fold(0.0, (sum, v) => sum + v.valor);
  }

  @computed
  DateTime get dataSelecionada {
    if (mesSelecionado == null) return DateTime.now();
    return DateTime(mesSelecionado!.year, mesSelecionado!.month, diaSelecionado);
  }

  // Actions
  @action
  Future<void> fetchData({bool forceRefresh = false}) async {
    isLoading = true;
    error = null;

    try {
      // Tentar carregar do cache primeiro (se não for refresh forçado)
      if (!forceRefresh && _cache.isCacheValid()) {
        final cachedData = _cache.loadVendasData();
        if (cachedData != null) {
          data = cachedData;
          _initializeMesEDia();
          isLoading = false;
          return;
        }
      }

      // Buscar do Firebase
      data = await _repository.fetchVendasData();
      await _cache.saveVendasData(data!);
      _initializeMesEDia();
    } catch (e) {
      error = e.toString();
      // Tentar carregar do cache como fallback
      final cachedData = _cache.loadVendasData();
      if (cachedData != null) {
        data = cachedData;
        _initializeMesEDia();
        error = 'Usando dados em cache. Erro: $e';
      }
    } finally {
      isLoading = false;
    }
  }

  @action
  void selecionarMes(MesDisponivel mes) {
    mesSelecionado = mes;
    diaSelecionado = _getDiaAtual(mes);
  }

  @action
  void navegarDia(DirecaoNavegacao direcao) {
    final indexAtual = diasDisponiveis.indexOf(diaSelecionado);
    if (direcao == DirecaoNavegacao.anterior && indexAtual > 0) {
      diaSelecionado = diasDisponiveis[indexAtual - 1];
    } else if (direcao == DirecaoNavegacao.proximo &&
        indexAtual < diasDisponiveis.length - 1) {
      diaSelecionado = diasDisponiveis[indexAtual + 1];
    }
  }

  @action
  void selecionarDia(int dia) {
    if (diasDisponiveis.contains(dia)) {
      diaSelecionado = dia;
    }
  }

  @action
  void navegarMes(DirecaoNavegacao direcao) {
    if (mesSelecionado == null || data == null) return;

    final mesesOrdenados = _getMesesOrdenados();
    final indexAtual = mesesOrdenados.indexWhere((m) => m.key == mesSelecionado!.key);

    if (direcao == DirecaoNavegacao.anterior && indexAtual > 0) {
      selecionarMes(mesesOrdenados[indexAtual - 1]);
    } else if (direcao == DirecaoNavegacao.proximo && indexAtual < mesesOrdenados.length - 1) {
      selecionarMes(mesesOrdenados[indexAtual + 1]);
    }
  }

  @action
  void selecionarData(DateTime novaData) {
    final mesKey = '${novaData.year}-${novaData.month.toString().padLeft(2, '0')}';

    // Procurar o mês correspondente
    final mes = data?.mesesDisponiveis.where((m) => m.key == mesKey).firstOrNull;

    if (mes != null) {
      mesSelecionado = mes;
      // Se o dia existe nos dias com vendas, usar ele; senão, usar o mais próximo
      if (mes.diasComVendas.contains(novaData.day)) {
        diaSelecionado = novaData.day;
      } else {
        // Encontrar o dia mais próximo disponível
        final diasOrdenados = mes.diasComVendas.toList()..sort();
        diaSelecionado = diasOrdenados.lastWhere(
          (d) => d <= novaData.day,
          orElse: () => diasOrdenados.first,
        );
      }
    }
  }

  // Private methods
  List<MesDisponivel> _getMesesOrdenados() {
    if (data == null) return [];
    return data!.mesesDisponiveis.toList()
      ..sort((a, b) => DateTime(a.year, a.month).compareTo(DateTime(b.year, b.month)));
  }

  void _initializeMesEDia() {
    final mesAtual = _getMesAtual();
    if (mesAtual != null) {
      mesSelecionado = mesAtual;
      diaSelecionado = _getDiaAtual(mesAtual);
    }
  }

  MesDisponivel? _getMesAtual() {
    if (data?.mesesDisponiveis.isEmpty ?? true) return null;

    final hoje = DateTime.now();
    final mesAtualKey = '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}';

    try {
      return data!.mesesDisponiveis.firstWhere(
        (m) => m.key == mesAtualKey,
      );
    } catch (e) {
      return data!.mesesDisponiveis.first;
    }
  }

  int _getDiaAtual(MesDisponivel mes) {
    final hoje = DateTime.now();
    final mesAtualKey = '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}';

    if (mes.key == mesAtualKey) {
      final diasAteHoje =
          mes.diasComVendas.where((d) => d <= hoje.day).toList();
      return diasAteHoje.isNotEmpty ? diasAteHoje.last : mes.diasComVendas.last;
    }
    return mes.diasComVendas.last;
  }

  EstatisticasDia _calcularEstatisticasDia(String mesKey, int dia) {
    final vendasMes = data?.vendasPorMes[mesKey];
    if (vendasMes == null) return EstatisticasDia.empty();

    final vendaDia = vendasMes.where((v) => v.day == dia).firstOrNull;
    if (vendaDia == null) return EstatisticasDia.empty();

    final totalVendido = vendaDia.total;
    final pdvsComVenda = vendaDia.sales.length;
    final ticketMedio = pdvsComVenda > 0 ? totalVendido / pdvsComVenda : 0.0;

    // Calcular variação em relação ao dia anterior
    double? variacao;
    final diaAnteriorIndex = diasDisponiveis.indexOf(dia) - 1;
    if (diaAnteriorIndex >= 0) {
      final diaAnterior = diasDisponiveis[diaAnteriorIndex];
      final vendaDiaAnterior =
          vendasMes.where((v) => v.day == diaAnterior).firstOrNull;
      if (vendaDiaAnterior != null && vendaDiaAnterior.total > 0) {
        variacao =
            ((totalVendido - vendaDiaAnterior.total) / vendaDiaAnterior.total) *
                100;
      }
    }

    return EstatisticasDia(
      totalVendido: totalVendido,
      pdvsComVenda: pdvsComVenda,
      ticketMedio: ticketMedio,
      variacao: variacao,
    );
  }

  List<VendaPDV> _getVendasPorPDVDia(String mesKey, int dia) {
    final vendasMes = data?.vendasPorMes[mesKey];
    if (vendasMes == null) return [];

    final vendaDia = vendasMes.where((v) => v.day == dia).firstOrNull;
    if (vendaDia == null) return [];

    // Calcular totais do mês por PDV
    final Map<String, double> totaisMes = {};
    for (final venda in vendasMes) {
      for (final sale in venda.sales) {
        totaisMes[sale.storeId] = (totaisMes[sale.storeId] ?? 0) + sale.valor;
      }
    }

    return vendaDia.sales.map((sale) {
      final totalMes = totaisMes[sale.storeId] ?? 0;
      final meta = getMetaMensal(sale.storeId);
      final percentual = meta > 0 ? (totalMes / meta) * 100 : 0.0;

      return VendaPDV(
        storeId: sale.storeId,
        storeName: sale.storeName,
        valor: sale.valor,
        totalMes: totalMes,
        meta: meta,
        percentualMeta: percentual,
      );
    }).toList()
      ..sort((a, b) => b.valor.compareTo(a.valor));
  }

  List<EvolucaoDia> _getEvolucaoMes(String mesKey) {
    final vendasMes = data?.vendasPorMes[mesKey];
    if (vendasMes == null) return [];

    return vendasMes
        .map((v) => EvolucaoDia(dia: v.day, total: v.total))
        .toList()
      ..sort((a, b) => a.dia.compareTo(b.dia));
  }

  String formatarValor(double valor) {
    final partes = valor.toStringAsFixed(2).split('.');
    final inteiro = partes[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    final decimal = partes[1];
    return 'R\$ $inteiro,$decimal';
  }

  String formatarValorCompleto(double valor) {
    return formatarValor(valor);
  }
}
