class OfflineData {
  final Map<String, dynamic> data;
  final String collectionPath; // ex: 'users/Db4X.../reposicao'
  final String docId;          // ID do documento
  final bool isUpdate;         // True se for update, false se for create
  // Se quiser excluir documento offline, pode criar outro bool p/ delete

  OfflineData({
    required this.data,
    required this.collectionPath,
    required this.docId,
    required this.isUpdate,
  });

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'collectionPath': collectionPath,
      'docId': docId,
      'isUpdate': isUpdate,
    };
  }

  factory OfflineData.fromJson(Map<String, dynamic> json) {
    return OfflineData(
      data: json['data'],
      collectionPath: json['collectionPath'],
      docId: json['docId'],
      isUpdate: json['isUpdate'],
    );
  }
}
