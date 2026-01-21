class VendaDia {
  final String storeId;
  final String storeName;
  final double valor;

  VendaDia({
    required this.storeId,
    required this.storeName,
    required this.valor,
  });

  Map<String, dynamic> toJson() => {
        'storeId': storeId,
        'storeName': storeName,
        'valor': valor,
      };

  factory VendaDia.fromJson(Map<String, dynamic> json) => VendaDia(
        storeId: json['storeId'] as String,
        storeName: json['storeName'] as String,
        valor: (json['valor'] as num).toDouble(),
      );
}
