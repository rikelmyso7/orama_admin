import 'venda_dia_model.dart';

class VendaDiaria {
  final String date;
  final int year;
  final int month;
  final int day;
  final List<VendaDia> sales;
  final double total;

  VendaDiaria({
    required this.date,
    required this.year,
    required this.month,
    required this.day,
    required this.sales,
    required this.total,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'year': year,
        'month': month,
        'day': day,
        'sales': sales.map((s) => s.toJson()).toList(),
        'total': total,
      };

  factory VendaDiaria.fromJson(Map<String, dynamic> json) => VendaDiaria(
        date: json['date'] as String,
        year: json['year'] as int,
        month: json['month'] as int,
        day: json['day'] as int,
        sales: (json['sales'] as List)
            .map((s) => VendaDia.fromJson(s as Map<String, dynamic>))
            .toList(),
        total: (json['total'] as num).toDouble(),
      );
}
