import 'pdv_model.dart';
import 'venda_diaria_model.dart';
import 'mes_disponivel_model.dart';

class VendasData {
  final List<PDV> pdvs;
  final Map<String, List<VendaDiaria>> vendasPorMes;
  final List<MesDisponivel> mesesDisponiveis;
  final DateTime ultimaAtualizacao;

  VendasData({
    required this.pdvs,
    required this.vendasPorMes,
    required this.mesesDisponiveis,
    required this.ultimaAtualizacao,
  });

  Map<String, dynamic> toJson() => {
        'pdvs': pdvs.map((p) => p.toJson()).toList(),
        'vendasPorMes': vendasPorMes.map(
          (key, value) => MapEntry(key, value.map((v) => v.toJson()).toList()),
        ),
        'mesesDisponiveis': mesesDisponiveis.map((m) => m.toJson()).toList(),
        'ultimaAtualizacao': ultimaAtualizacao.toIso8601String(),
      };

  factory VendasData.fromJson(Map<String, dynamic> json) => VendasData(
        pdvs: (json['pdvs'] as List)
            .map((p) => PDV.fromJson(p as Map<String, dynamic>))
            .toList(),
        vendasPorMes: (json['vendasPorMes'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(
            key,
            (value as List)
                .map((v) => VendaDiaria.fromJson(v as Map<String, dynamic>))
                .toList(),
          ),
        ),
        mesesDisponiveis: (json['mesesDisponiveis'] as List)
            .map((m) => MesDisponivel.fromJson(m as Map<String, dynamic>))
            .toList(),
        ultimaAtualizacao: DateTime.parse(json['ultimaAtualizacao'] as String),
      );
}

class EstatisticasDia {
  final double totalVendido;
  final int pdvsComVenda;
  final double ticketMedio;
  final double? variacao;

  EstatisticasDia({
    required this.totalVendido,
    required this.pdvsComVenda,
    required this.ticketMedio,
    this.variacao,
  });

  factory EstatisticasDia.empty() => EstatisticasDia(
        totalVendido: 0,
        pdvsComVenda: 0,
        ticketMedio: 0,
      );
}

class VendaPDV {
  final String storeId;
  final String storeName;
  final double valor;
  final double totalMes;
  final double meta;
  final double percentualMeta;

  VendaPDV({
    required this.storeId,
    required this.storeName,
    required this.valor,
    required this.totalMes,
    required this.meta,
    required this.percentualMeta,
  });
}

class EvolucaoDia {
  final int dia;
  final double total;

  EvolucaoDia({required this.dia, required this.total});
}
