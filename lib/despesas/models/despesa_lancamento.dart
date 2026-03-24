class DespesaLancamento {
  final int dia;
  final String data;
  final String categoria;
  final String tipo; // "pagamento" ou "recebimento"
  final String metodo; // "cartao", "dinheiro", "outro"
  final double valor;
  final String? pdv;
  final String unidade;
  final String mesKey; // YYYY-MM

  DespesaLancamento({
    required this.dia,
    required this.data,
    required this.categoria,
    required this.tipo,
    required this.metodo,
    required this.valor,
    this.pdv,
    required this.unidade,
    required this.mesKey,
  });

  factory DespesaLancamento.fromMap(
    Map<dynamic, dynamic> map,
    String unidade,
    String mesKey,
  ) {
    return DespesaLancamento(
      dia: (map['dia'] as num?)?.toInt() ?? 0,
      data: map['data']?.toString() ?? '',
      categoria: map['categoria']?.toString() ?? '',
      tipo: map['tipo']?.toString() ?? '',
      metodo: map['metodo']?.toString() ?? '',
      valor: (map['valor'] as num?)?.toDouble() ?? 0.0,
      pdv: map['pdv']?.toString(),
      unidade: unidade,
      mesKey: mesKey,
    );
  }

  factory DespesaLancamento.fromJson(Map<String, dynamic> json) =>
      DespesaLancamento(
        dia: json['dia'] as int,
        data: json['data'] as String,
        categoria: json['categoria'] as String,
        tipo: json['tipo'] as String,
        metodo: json['metodo'] as String,
        valor: (json['valor'] as num).toDouble(),
        pdv: json['pdv'] as String?,
        unidade: json['unidade'] as String,
        mesKey: json['mesKey'] as String,
      );
}
