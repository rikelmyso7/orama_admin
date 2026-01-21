class MesDisponivel {
  final String key; // "2025-01"
  final int year;
  final int month;
  final List<int> diasComVendas;

  MesDisponivel({
    required this.key,
    required this.year,
    required this.month,
    required this.diasComVendas,
  });

  String get formattedMonth {
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return '${meses[month - 1]} $year';
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'year': year,
        'month': month,
        'diasComVendas': diasComVendas,
      };

  factory MesDisponivel.fromJson(Map<String, dynamic> json) => MesDisponivel(
        key: json['key'] as String,
        year: json['year'] as int,
        month: json['month'] as int,
        diasComVendas: (json['diasComVendas'] as List).cast<int>(),
      );
}
