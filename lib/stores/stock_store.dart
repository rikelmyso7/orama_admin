import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobx/mobx.dart';
import 'package:orama_admin/others/insumos.dart';
import 'package:uuid/uuid.dart';

part 'stock_store.g.dart';

class StockStore = _StockStore with _$StockStore;

abstract class _StockStore with Store {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  // Construtor para inicializar com o banco de dados secundário
  _StockStore()
      : firestore =
            FirebaseFirestore.instanceFor(app: Firebase.app('SecondaryApp')),
        auth = FirebaseAuth.instanceFor(app: Firebase.app('SecondaryApp')) {
    fetchUserRole().then((_) => fetchReports());
  }

  final box = GetStorage();
  ObservableList<Map<String, dynamic>> reports =
      ObservableList<Map<String, dynamic>>();

  @observable
  Map<String, dynamic> kgValues = {};
  @observable
  Map<String, dynamic> quantityValues = {};

  @observable
  String? userRole; // Para armazenar o papel do usuário

  @observable
  Map<String, TextEditingController> kgControllers = {};
  @observable
  Map<String, TextEditingController> quantityControllers = {};

  Future<void> fetchUserRole() async {
    final user = auth.currentUser;
    if (user == null) {
      print("Usuário não autenticado.");
      return;
    }

    try {
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      userRole = userDoc.data()?['role'];
      print("Papel do usuário: $userRole");
    } catch (e) {
      print("Erro ao buscar o papel do usuário: $e");
    }
  }

  void initControllers(String itemName) {
    if (!kgControllers.containsKey(itemName)) {
      kgControllers[itemName] = TextEditingController();
      // Optionally, add listeners if needed
    }
  }

  // Método para garantir que os controladores estão inicializados
  void populateFieldsWithReport(Map<String, dynamic> reportData) {
    if (reportData['Categorias'] == null) return;

    for (var category in reportData['Categorias']) {
      for (var item in category['Itens']) {
        final itemName = item['Item'];
        kgValues[itemName] = item['Peso'] ?? '0.000';
        quantityValues[itemName] = item['Quantidade'] ?? '0';

        // Inicializa os controladores com valores e adiciona listeners
        kgControllers[itemName] =
            TextEditingController(text: kgValues[itemName]);
        quantityControllers[itemName] =
            TextEditingController(text: quantityValues[itemName]);

        kgControllers[itemName]!.addListener(() {
          updateKg(itemName, kgControllers[itemName]!.text);
        });

        quantityControllers[itemName]!.addListener(() {
          updateQuantity(itemName, quantityControllers[itemName]!.text);
        });
      }
    }
  }

  void clearFields() {
    kgValues.clear();
    quantityValues.clear();
  }

  // Funções para atualizar kg e quantidade reativamente
  @action
  void updateKg(String itemName, String kgValue) {
    if (_isValidNumber(kgValue)) {
      kgValues[itemName] = kgValue;
      box.write('kgValues', kgValues);
      print('Atualizado peso de $itemName para $kgValue');
      print('kgValues atualizados: $kgValues'); // Log adicional
    } else {
      print("Valor de peso inválido para $itemName.");
    }
  }

  @action
  void updateQuantity(String itemName, String quantity) {
    if (_isValidNumber(quantity)) {
      quantityValues[itemName] = quantity;
      box.write('quantityValues', quantityValues);
      print('Atualizado quantidade de $itemName para $quantity');
      print('quantityValues atualizados: $quantityValues'); // Log adicional
    } else {
      print("Valor de quantidade inválido para $itemName.");
    }
  }

  // Método para validar que o valor é um número positivo
  bool _isValidNumber(String value) {
    final num? number = num.tryParse(value);
    return number != null && number >= 0;
  }

  // Método para salvar os dados no Firebase no formato JSON
  Future<void> saveData(String nome, String data, String city, String loja,
      {String? reportId}) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("Usuário não autenticado.");
      return;
    }

    final userId = user.uid;
    final uuid = reportId ?? Uuid().v4(); // Use o ID fornecido ou crie um novo

    // Estrutura de dados para salvar, incluindo o campo ID
    final Map<String, dynamic> dataToSave = {
      'ID': uuid, // Adiciona o campo ID
      'Nome do usuario': nome,
      'Data': data,
      'Cidade': city,
      'Loja': loja,
      'Categorias': []
    };

    final categorias = ['SORVETES', 'INSUMOS', 'TAPIOCA', 'DESCARTÁVEIS'];
    for (var categoria in categorias) {
      // Gather all items in this category with their respective weights and quantities
      final items = insumos[categoria]!
          .where(
              (item) => kgValues[item] != null || quantityValues[item] != null)
          .map((item) => {
                'Item': item,
                'Peso': kgValues[item] ?? '0.000',
                'Quantidade': quantityValues[item] ?? '0',
              })
          .toList();

      if (items.isNotEmpty) {
        dataToSave['Categorias'].add({'Categoria': categoria, 'Itens': items});
      }
    }

    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('relatorio')
          .doc(uuid)
          .set(dataToSave);

      print("Data saved successfully: $dataToSave");

      // Clear local data after saving
      box.remove('kgValues');
      box.remove('quantityValues');
    } catch (e) {
      print("Error saving data: $e");
      box.write('unsavedData', dataToSave);
      print("Data stored locally due to network error.");
    }
  }

  Future<void> updateReport(
      String reportId, String nome, String city, String data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    final Map<String, dynamic> updatedData = {
      'Nome do usuario': nome,
      'Data': data,
      'Cidade': city,
      'Categorias': []
    };

    // Atualiza os valores dos campos com base no Map
    final categorias = ['SORVETES', 'INSUMOS', 'TAPIOCA', 'DESCARTÁVEIS'];
    for (var categoria in categorias) {
      final items = insumos[categoria]!
          .map((item) => {
                'Item': item,
                'Peso': kgValues[item] ?? '0.000',
                'Quantidade': quantityValues[item] ?? '0',
              })
          .toList();
      if (items.isNotEmpty) {
        updatedData['Categorias'].add({'Categoria': categoria, 'Itens': items});
      }
    }

    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('relatorio')
          .doc(reportId)
          .set(updatedData, SetOptions(merge: true));

      print("Relatório atualizado com sucesso!");
    } catch (e) {
      print("Erro ao atualizar relatório: $e");
    }
  }

  // Função auxiliar para determinar a categoria com base no nome do item
  String getCategoryFromItem(String itemName) {
    if (insumos['SORVETES']!.contains(itemName)) {
      return 'SORVETES';
    } else if (insumos['INSUMOS']!.contains(itemName)) {
      return 'INSUMOS';
    } else if (insumos['TAPIOCA']!.contains(itemName)) {
      return 'TAPIOCA';
    } else if (insumos['DESCARTÁVEIS']!.contains(itemName)) {
      return 'DESCARTÁVEIS';
    } else {
      return 'OUTROS';
    }
  }

  @observable
  String selectedCity = 'Jundiaí'; // Cidade padrão ao carregar a página

  @action
  Future<void> fetchReports({String? city}) async {
    reports.clear();
    final targetCity = city ?? selectedCity;

    try {
      // Buscar todos os usuários com `role = "user"`
      final userQuerySnapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'user')
          .get();

      // Para cada usuário encontrado, buscar os relatórios na subcoleção `relatorio`
      for (var userDoc in userQuerySnapshot.docs) {
        final userId = userDoc.id;
        final reportsSnapshot = await firestore
            .collection('users')
            .doc(userId)
            .collection('relatorio')
            .where('Cidade', isEqualTo: targetCity) // Filtrar pela cidade
            .get();

        for (var reportDoc in reportsSnapshot.docs) {
          final data = reportDoc.data();
          data['id'] = reportDoc.id;
          data['userId'] = userId; // Armazena o userId para referência futura
          reports.add(data);
        }
      }

      print(
          "Total de relatórios carregados para $targetCity: ${reports.length}");
    } catch (e) {
      print("Erro ao buscar relatórios para $targetCity: $e");
    }
  }

  @action
  void setCity(String city) {
    selectedCity = city;
    fetchReports(city: city);
  }

  // Função para excluir um relatório específico
  Future<void> deleteReport(String userId, String reportId) async {
    try {
      await firestore
          .collection('users')
          .doc(userId) // Usa o userId do proprietário do relatório
          .collection('relatorio')
          .doc(reportId)
          .delete();

      reports.removeWhere(
          (report) => report['id'] == reportId && report['userId'] == userId);

      print("Relatório excluído com sucesso.");
    } catch (e) {
      print("Erro ao excluir relatório: $e");
    }
  }
}
