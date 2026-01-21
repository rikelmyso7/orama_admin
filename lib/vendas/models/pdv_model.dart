class PDV {
  final String id;
  final String name;
  final bool active;

  PDV({
    required this.id,
    required this.name,
    this.active = true,
  });

  factory PDV.fromMap(String id, Map<dynamic, dynamic> map) {
    return PDV(
      id: id,
      name: map['name']?.toString() ?? id,
      active: map['active'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'active': active,
      };

  factory PDV.fromJson(Map<String, dynamic> json) => PDV(
        id: json['id'] as String,
        name: json['name'] as String,
        active: json['active'] as bool? ?? true,
      );
}
