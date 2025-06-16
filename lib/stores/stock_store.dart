import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:orama_admin/main.dart';
import 'package:orama_admin/others/insumos.dart';
import 'package:orama_admin/routes/routes.dart';
import 'package:orama_admin/utils/offline_model.dart';
import 'package:orama_admin/utils/extensions.dart';

part 'stock_store.g.dart';

class StockStore = _StockStore with _$StockStore;

abstract class _StockStore with Store {
  final CollectionReference adminRelatorios = secondaryFirestore
      .collection('users')
      .doc('Db4XIYcNMhUgYXvF6JDJJxbc3h82')
      .collection('relatorio');

  _StockStore() {}

  @observable
  DateTime selectedDate = DateTime.now();

  @action
  void setSelectedDate(DateTime date) {
    selectedDate = date;
  }

  final box = GetStorage();
  final FirebaseFirestore firestore = secondaryFirestore;

  // Observable para relatórios
  @observable
  ObservableList<Map<String, dynamic>> reports =
      ObservableList<Map<String, dynamic>>();

// Relatórios específicos
  ObservableList<Map<String, dynamic>> specificReports =
      ObservableList<Map<String, dynamic>>();

  @observable
  Map<String, dynamic> quantityValues = {}; // Valores de quantidade
  @observable
  Map<String, TextEditingController> quantityControllers = {};

  @observable
  Map<String, TextEditingController> quantityControllersAdd = {};

  ObservableMap<String, Map<String, List<Map<String, dynamic>>>>
      reportInsumos2 = ObservableMap.of({});

  // OFFLINE--------------------------------------

  Future<bool> hasInternetConnection() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // Salva relatórios no cache local
  @action
  void saveReportsToCache(List<Map<String, dynamic>> reports) {
    box.write('cachedReports', reports);
    print("Relatórios salvos no cache local.");
  }

  // Carrega relatórios do cache local
  List<Map<String, dynamic>> loadCachedReports(String userId) {
    final cachedReports = box.read<List<dynamic>>('cachedReports') ?? [];
    return cachedReports
        .cast<Map<String, dynamic>>()
        .where((report) => report['UsuarioId'] == userId)
        .toList();
  }

  final String offlineKey = 'offline_queue';

  Future<void> addToOfflineQueue(OfflineData offlineData) async {
    final List storedList = box.read<List>(offlineKey) ?? [];
    // Salva na fila
    storedList.add(offlineData.toJson());
    await box.write(offlineKey, storedList);
    print('Adicionado à fila offline: ${offlineData.toJson()}');
  }

  /// Obtém todas as operações pendentes
  List<OfflineData> getOfflineQueue() {
    final List storedList = box.read<List>(offlineKey) ?? [];
    return storedList
        .map((item) => OfflineData.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Limpa toda a fila offline
  Future<void> clearOfflineQueue() async {
    await box.remove(offlineKey);
    print('Fila offline limpa.');
  }

  bool _isSyncingAll = false;
  bool _isSyncingLocal = false;

  /// Tenta sincronizar todos os dados pendentes no Firestore
  @action
  Future<void> syncAllPendingData() async {
    if (_isSyncingAll) return;
    _isSyncingAll = true;

    try {
      final queue = getOfflineQueue();
      final failedQueue = [];

      for (var offlineData in queue) {
        try {
          final ref = firestore
              .doc('${offlineData.collectionPath}/${offlineData.docId}');
          if (offlineData.isUpdate) {
            await ref.set(offlineData.data, SetOptions(merge: true));
          } else {
            await ref.set(offlineData.data);
          }
          print('Sincronizado com sucesso: ${offlineData.toJson()}');
        } catch (e) {
          print('Erro ao sincronizar: $e');
          failedQueue.add(offlineData); // Adiciona à lista de falhas
        }
      }

      if (failedQueue.isEmpty) {
        await clearOfflineQueue();
      } else {
        await box.write(
            offlineKey, failedQueue.map((e) => e.toJson()).toList());
      }
    } finally {
      _isSyncingAll = false;
    }
  }

  @action
  Future<void> syncLocalOperations(
    String key, {
    required Future<void> Function(Map<String, dynamic> operation) onSync,
  }) async {
    if (_isSyncingLocal) return;
    _isSyncingLocal = true;

    try {
      final box = GetStorage();
      final List<Map<String, dynamic>> unsyncedOperations =
          (box.read(key) ?? []).cast<Map<String, dynamic>>();
      final failed = <Map<String, dynamic>>[];

      for (var operation in unsyncedOperations) {
        try {
          await onSync(operation);
        } catch (e) {
          print("Falha ao sincronizar operação: $e");
          failed.add(operation);
        }
      }

      if (failed.isEmpty) {
        await box.remove(key);
      } else {
        await box.write(key, failed);
      }
    } finally {
      _isSyncingLocal = false;
    }
  }

  void addItemToReport2({
    required String? reportId,
    required String category,
    required String name,
    required String quantity,
    required String type,
  }) {
    // Gera um ID temporário se o reportId for nulo
    final currentReportId =
        reportId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final newItem = {
      'nome': name,
      'quantidade': quantity,
      'tipo': type,
    };

    // Garante que o mapa para este relatório existe
    reportInsumos2.putIfAbsent(currentReportId, () => {});

    // Garante que a lista da categoria é mutável
    if (reportInsumos2[currentReportId]!.containsKey(category)) {
      reportInsumos2[currentReportId]![category] =
          List<Map<String, dynamic>>.from(
              reportInsumos2[currentReportId]![category]!);
    } else {
      reportInsumos2[currentReportId]![category] = [];
    }

    // Adiciona o novo item
    reportInsumos2[currentReportId]![category]!.add(newItem);

    // Atualiza os controladores
    final key = (category == 'BALDES' || category == 'POTES')
        ? '${category}_$name'
        : name;

    quantityControllersAdd[key] ??= TextEditingController(text: quantity);

    print(
        'Item adicionado: $newItem à categoria $category no relatório $currentReportId');
  }

  String getUserId() {
    return 'Db4XIYcNMhUgYXvF6JDJJxbc3h82';
  }

  // Função para inicializar os controladores
  @action
  void initControllers(String itemName) {
    if (!quantityControllers.containsKey(itemName)) {
      quantityControllers[itemName] = TextEditingController();
    }
  }

  @action
  void clearFields() {
    quantityValues.clear();
    quantityControllers.clear();
  }

  @action
  void updateQuantity(String itemName, String quantity) {
    if (_isValidNumber(quantity)) {
      quantityValues[itemName] = quantity;
      quantityControllers[itemName]?.text = quantity; // Atualiza o controlador
      box.write('quantityValues', quantityValues); // Salva localmente
    }
  }

  bool _isValidNumber(String value) {
    final num? number = num.tryParse(value);
    return number != null && number >= 0;
  }

  // Método para s
  @action
  Future<void> fetchReports() async {
    reports.clear();

    // 1. Adiciona relatórios offline pendentes da fila 'offline_queue'
    final queue = getOfflineQueue();
    final pendingReports = queue
        .where((q) => q.collectionPath.contains('reposicao'))
        .map((q) => {
              ...q.data,
              'ID': q.docId,
              'offline': true, // marcador opcional
            })
        .toList();
    reports.addAll(pendingReports);

    try {
      final querySnapshot = await firestore
          .collection('users')
          .doc('Db4XIYcNMhUgYXvF6JDJJxbc3h82')
          .collection('reposicao')
          .get();

      final loadedReports = querySnapshot.docs
          .map((doc) => {...doc.data(), 'ID': doc.id})
          .toList();

      // 2. Salva localmente para acesso offline futuro
      await box.write('localReports', loadedReports);

      reports.addAll(loadedReports);
      print("Relatórios carregados online e armazenados localmente.");
    } catch (e) {
      print("Erro ou sem conexão. Carregando relatórios offline...");
      final offlineReports = box.read<List>('localReports') ?? [];
      if (offlineReports.isNotEmpty) {
        reports.addAll(offlineReports.cast<Map<String, dynamic>>());
      }
    }
  }

  @action
  Future<void> deleteReport(String reportId) async {
    try {
      await secondaryFirestore
          .collection('users')
          .doc('Db4XIYcNMhUgYXvF6JDJJxbc3h82') // Substitua pelo ID correto
          .collection('relatorio')
          .doc(reportId)
          .delete();

      reports.removeWhere((report) => report['ID'] == reportId);
      print("Relatório excluído com sucesso.");
    } catch (e) {
      print("Erro ao excluir relatório: $e");
    }
  }

  // Função original para buscar relatórios do Firestore
  @action
  Future<void> fetchReportsUser(String excludedUserId) async {
    reports.clear(); // Lista observável para "relatorio"
    specificReports
        .clear(); // Nova lista observável para "relatorio_especifico"

    try {
      final querySnapshot = await secondaryFirestore.collection('users').get();

      for (var userDoc in querySnapshot.docs) {
        if (userDoc.id == excludedUserId) continue;

        final relatorioCollection =
            await userDoc.reference.collection('relatorio').get();
        for (var relatorioDoc in relatorioCollection.docs) {
          reports.add({
            ...relatorioDoc.data(),
            'ID': relatorioDoc.id,
            'UsuarioId': userDoc.id,
          });
        }

        final relatorioEspecificoCollection =
            await userDoc.reference.collection('relatorio_especifico').get();
        for (var relatorioEspecificoDoc in relatorioEspecificoCollection.docs) {
          specificReports.add({
            ...relatorioEspecificoDoc.data(),
            'ID': relatorioEspecificoDoc.id,
            'UsuarioId': userDoc.id,
          });
        }
      }

      // Salvar os relatórios carregados no cache local
      saveReportsToCache([...reports, ...specificReports]);
      print("Relatórios carregados e salvos no cache local.");
    } catch (e) {
      print("Erro ao buscar relatórios: $e");
    }
  }

  @action
  Future<void> saveDataToAdminRelatorios(
      String nome, String data, String city, String loja,
      {String? reportId}) async {
    final CollectionReference adminRelatorios = secondaryFirestore
        .collection('users')
        .doc('Db4XIYcNMhUgYXvF6JDJJxbc3h82')
        .collection('relatorio');

    final dataFormat = DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());
    final comandaId = '${dataFormat} - ${loja}';
    final uuid = reportId ?? comandaId;
    final DateTime now = DateTime.now().toUtc().add(const Duration(hours: -3));
    final String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final categorias = insumos.keys.map((categoria) {
      final items = insumos[categoria]!.map((item) {
        final itemName = item['nome'];
        final tipo = item['tipo'] ?? '';
        final key = generateKey(categoria, itemName);

        final quantidade = quantityValues[key]?.trim() ?? '';
        return {
          'Item': itemName,
          'Quantidade': quantidade,
          'Tipo': tipo,
        };
      }).toList();

      return {'Categoria': categoria, 'Itens': items};
    }).toList();

    final report = {
      'ID': uuid,
      'Nome do usuario': nome,
      'Data': formattedDate,
      'Cidade': city,
      'Loja': loja,
      'Categorias': categorias,
    };

    try {
      await adminRelatorios.doc(uuid).set(report, SetOptions(merge: true));
      print("Dados salvos online em adminRelatorios: $report");
    } catch (e) {
      print("Erro ou sem conexão. Salvando relatório offline...");
      final offlineDoc = OfflineData(
        data: report,
        collectionPath: 'users/Db4XIYcNMhUgYXvF6JDJJxbc3h82/relatorio',
        docId: uuid,
        isUpdate: false,
      );
      await addToOfflineQueue(offlineDoc);
    }
  }

  // Método para atualizar relatório
  @action
  Future<void> updateReport(String reportId, String nome, String city,
      String loja, String data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Usuário não autenticado.");
      return;
    }

    final userId = user.uid;

    final DateTime now = DateTime.now().toUtc().add(Duration(hours: -3));
    final String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    // Estrutura de dados para atualizar, incluindo o campo ID
    final Map<String, dynamic> updatedData = {
      'ID': reportId,
      'Nome do usuario': nome,
      'Data': formattedDate,
      'Cidade': city,
      'Loja': loja,
      'Categorias': []
    };

    // Lista de categorias disponíveis
    final categorias = ['SORVETES', 'INSUMOS', 'TAPIOCA', 'DESCARTÁVEIS'];

    // Itera sobre cada categoria e coleta os itens que possuem valores
    for (var categoria in categorias) {
      final items = <Map<String, dynamic>>[];

      for (var item in insumos[categoria] ?? []) {
        final quantidade = quantityValues[item] ??
            '0'; // Obtém a quantidade, padrão '0' se não houver

        // Só adiciona o item se peso ou quantidade tiverem valores diferentes dos padrões
        if (quantidade != '0') {
          items.add({
            'Item': item,
            'Quantidade': quantidade,
          });
        }
      }

      // Só adiciona a categoria ao 'updatedData' se houver itens preenchidos
      if (items.isNotEmpty) {
        updatedData['Categorias'].add({'Categoria': categoria, 'Itens': items});
      }
    }

    try {
      // Atualiza os dados no Firestore com `SetOptions(merge: true)` para mesclar
      await firestore
          .collection('users')
          .doc(userId)
          .collection('relatorio')
          .doc(reportId)
          .set(updatedData, SetOptions(merge: true));

      print("Relatório atualizado com sucesso: $updatedData");
    } catch (e) {
      print("Erro ao atualizar relatório: $e");
    }
  }

  @action
  Future<Map<String, dynamic>?> getReport(String reportId) async {
    try {
      final doc = await firestore
          .collection('users')
          .doc(getUserId())
          .collection('relatorio')
          .doc(reportId)
          .get();

      if (doc.exists) {
        return doc.data();
      } else {
        print("Relatório com ID $reportId não encontrado.");
        return null;
      }
    } catch (e) {
      print("Erro ao buscar relatório: $e");
      return null;
    }
  }

  String formatReportForWhatsApp(Map<String, dynamic> report) {
    final buffer = StringBuffer();

    buffer.writeln("Relatório de Reposição");
    buffer.writeln("Loja: ${report['Loja']}");
    buffer.writeln("Cidade: ${report['Cidade']}");
    buffer.writeln("Data: ${report['Data']}");
    buffer.writeln("Responsável: ${report['Nome do usuario']} \n");

    for (final category in report['Categorias']) {
      buffer.writeln("${category['Categoria']}:");
      for (final item in category['Itens']) {
        final itemName = item['Item'];
        final peso = item['Peso'] != null ? "Peso: ${item['Peso']}kg" : "";
        final quantidade = item['Quantidade'] != null
            ? "Quantidade: ${item['Quantidade']}"
            : "";
        buffer.writeln("  • $itemName $peso $quantidade".trim());
      }
      buffer.writeln("");
    }

    return buffer.toString();
  }

  @observable
  bool isLoading = false;

  final box2 = GetStorage();
  final FirebaseFirestore firestore2 = FirebaseFirestore.instance;

// Relatórios gerais
  @observable
  ObservableList<Map<String, dynamic>> reports2 =
      ObservableList<Map<String, dynamic>>();

  @observable
  ObservableMap<String, String> quantityValues2 =
      ObservableMap<String, String>();
  @observable
  ObservableMap<String, String> minValues = ObservableMap<String, String>();

  @observable
  Map<String, TextEditingController> quantityControllers2 = {};
  @observable
  Map<String, TextEditingController> minControllers = {};

  void populateFieldsWithReport2(Map<String, dynamic> reportData) {
    print("Dados do relatório: $reportData"); // Depuração
    if (reportData['Categorias'] == null) return;

    for (var category in reportData['Categorias']) {
      final categoryName = category['Categoria'];
      for (var item in category['Itens']) {
        final itemName = item['Item'];
        final tipo =
            item['tipo'] ?? 'Indefinido'; // Garante que o tipo seja capturado.

        // Garantia de chave única para BALDES e POTES
        final key = (categoryName == 'BALDES' || categoryName == 'POTES')
            ? '${categoryName}_$itemName'
            : itemName;

        final quantidade = item['Quantidade']?.toString() ?? '';
        final minimo = item['Qtd Minima']?.toString() ?? '';

        // Atualiza os observables
        quantityValues[key] = quantidade;
        minValues[key] = minimo;

        // Inicializa os controladores com os valores do relatório
        quantityControllers[key] ??= TextEditingController(text: quantidade);
        minControllers[key] ??= TextEditingController(text: minimo);

        // Atualiza o texto nos controladores existentes
        quantityControllers[key]!.text = quantidade;
        minControllers[key]!.text = minimo;

        print(
            "Carregado: $key -> quantidade=$quantidade, minimo=$minimo, tipo=$tipo");
      }
    }
  }

  @action
  void initItemValues(String category, String itemName, String minimoPadrao,
      {String? tipo}) {
    final key = (category == 'BALDES' || category == 'POTES')
        ? '${category}_$itemName'
        : itemName;

    if (!minValues.containsKey(key)) minValues[key] = minimoPadrao;
    if (!quantityValues.containsKey(key)) quantityValues[key] = '';

    // Remove "/4" ao inicializar o controlador
    final rawQuantity = quantityValues[key]?.split('/').first ?? '';

    minControllers[key] ??= TextEditingController(text: minValues[key]);
    quantityControllers[key] ??= TextEditingController(text: rawQuantity);

    minControllers[key]!.addListener(() {
      updateMinValue(key, minControllers[key]!.text);
    });
    quantityControllers[key]!.addListener(() {
      updateQuantity(key, quantityControllers[key]!.text);
    });

    print(
        "Inicializado: $key -> tipo=$tipo, minimo=$minimoPadrao, quantidade=$rawQuantity");
  }

  @action
  void updateMinValue(String key, String minValue) {
    minValues[key] = minValue; // Atualiza o valor no mapa
  }

  @action
  void updateQuantity2(String key, String quantity) {
    if (_isValidNumber(quantity)) {
      // Formata a quantidade no formato "{valor}/4"
      quantityValues[key] = '$quantity/4';
      box.write('quantityValues', quantityValues);
    }
  }

  @action
  void clearFields2() {
    minValues.clear();
    quantityControllers.clear();
    minControllers.clear();
    quantityValues.clear();
    box.erase();
    print('Campos limpos');
  }

  bool _isValidNumber2(String value) {
    final num? number = num.tryParse(value);
    return number != null && number >= 0;
  }

  @action
  Future<void> saveData2(String nome, String data, String city, String loja,
      {String? reportId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Erro: Usuário não autenticado.");
      return;
    }

    final userId = user.uid;
    final dataFormat = DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());
    final comandaId = '${dataFormat} - ${loja}';
    final uuid = reportId ?? comandaId;
    final DateTime now = DateTime.now().toUtc().add(Duration(hours: -3));
    final String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    // Construção das categorias e itens diretamente a partir do mapa `insumos`
    final categorias = insumos.keys.map((categoria) {
      final items = insumos[categoria]!.map((item) {
        final itemName = item['nome'];
        final tipo = item['tipo'] ?? ''; // Tipo diretamente do insumo.
        final key = (categoria == 'BALDES' || categoria == 'POTES')
            ? '${categoria}_$itemName'
            : itemName;

        // Recupera valores de quantidade e mínimo
        final quantidade = quantityValues[key]?.split('/').first ?? '0';
        final minimo = minValues[key] ?? item['minimo'];

        // Verifica se a quantidade mínima é uma fração
        final isFraction = minimo.contains('/');

        // Formata a quantidade apenas se a quantidade mínima for uma fração
        final formattedQuantidade = isFraction ? '$quantidade/4' : quantidade;

        return {
          'Item': itemName,
          'Quantidade': formattedQuantidade,
          'Qtd Minima': minimo,
          'Tipo': tipo, // Inclui o campo tipo diretamente.
        };
      }).toList();

      return {'Categoria': categoria, 'Itens': items};
    }).toList();

    // Estrutura completa do relatório
    final report = {
      'ID': uuid,
      'Nome do usuario': nome,
      'Data': formattedDate,
      'Cidade': city,
      'Loja': loja,
      'Categorias': categorias,
    };

    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('relatorio')
          .doc(uuid)
          .set(report, SetOptions(merge: true));

      print("Dados salvos com sucesso: $report");
      clearFields();
    } catch (e) {
      print("Erro ao salvar dados: $e");
      box.write('unsavedData', report); // Salva localmente como fallback.
    }
  }

  @action
  Future<void> fetchReports2() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    reports.clear();
    isLoading = true;

    try {
      final querySnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('relatorio')
          .get();

      final loadedReports = querySnapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();

      // Salvar localmente
      await box.write('localReports2', loadedReports);

      reports.addAll(loadedReports);
      print("Relatórios carregados online e armazenados localmente.");
    } catch (e) {
      print("Erro ao buscar relatórios. Carregando localmente.");
      final offlineReports = box.read<List>('localReports2') ?? [];
      reports.addAll(offlineReports.cast<Map<String, dynamic>>());
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> fetchReportsEspecifico() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    if (isLoading) return;

    isLoading = true;
    specificReports.clear();

    try {
      final querySnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('relatorio_especifico')
          .get();

      final loadedReports = querySnapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();

      // Salvar localmente
      await box.write('localSpecificReports', loadedReports);

      specificReports.addAll(loadedReports);
      print("Relatórios específicos carregados e armazenados localmente.");
    } catch (e) {
      print("Erro ao buscar relatórios específicos. Carregando localmente.");
      final offlineReports = box.read<List>('localSpecificReports') ?? [];
      specificReports.addAll(offlineReports.cast<Map<String, dynamic>>());
    } finally {
      isLoading = false;
    }
  }

  Map<String, List<Map<String, dynamic>>> getItemsForReport(String reportId) {
    // Recupera itens dinâmicos
    final dynamicItems = reportInsumos[reportId] ?? {};

    // Cria uma cópia do modelo base para evitar alterações diretas
    final mergedItems = Map<String, List<Map<String, dynamic>>>.fromEntries(
      insumos.entries
          .map((entry) => MapEntry(entry.key, List.from(entry.value))),
    );

    // Mescla os itens dinâmicos com os itens base
    dynamicItems.forEach((category, items) {
      if (mergedItems.containsKey(category)) {
        mergedItems[category]!.addAll(items);
      } else {
        mergedItems[category] = items;
      }
    });

    return mergedItems;
  }

  @action
  void removeItemFromReport({
    required String reportId,
    required String category,
    required String name,
  }) {
    // Verifica se existem itens dinâmicos para o relatório e categoria
    if (reportInsumos[reportId] != null &&
        reportInsumos[reportId]![category] != null) {
      // Remove o item pelo nome
      reportInsumos[reportId]![category]!
          .removeWhere((item) => item['nome'] == name);

      // Remove a categoria se não houver mais itens
      if (reportInsumos[reportId]![category]!.isEmpty) {
        reportInsumos[reportId]!.remove(category);
      }

      // Remove o relatório se não houver mais categorias
      if (reportInsumos[reportId]!.isEmpty) {
        reportInsumos.remove(reportId);
      }

      print(
          'Item "$name" removido da categoria "$category" no relatório "$reportId".');
    } else {
      print('Nenhum item encontrado para remover.');
    }
  }

  ObservableMap<String, Map<String, List<Map<String, dynamic>>>> reportInsumos =
      ObservableMap.of({});

  // Adicionar novo item ao relatório específico
  void addItemToReport({
    required String reportId,
    required String category,
    required String name,
    required String min,
    required String quantity,
    required String type,
  }) {
    final newItem = {
      'nome': name,
      'minimo': min,
      'quantidade': quantity,
      'tipo': type,
    };

    // Garante que o mapa para este relatório existe
    reportInsumos.putIfAbsent(reportId, () => {});

    // Garante que a lista da categoria é mutável
    if (reportInsumos[reportId]!.containsKey(category)) {
      reportInsumos[reportId]![category] =
          List<Map<String, dynamic>>.from(reportInsumos[reportId]![category]!);
    } else {
      reportInsumos[reportId]![category] = [];
    }

    // Adiciona o novo item
    reportInsumos[reportId]![category]!.add(newItem);

    // Atualiza os controladores
    final key = (category == 'BALDES' || category == 'POTES')
        ? '${category}_$name'
        : name;

    minControllers[key] ??= TextEditingController(text: min);
    quantityControllers[key] ??= TextEditingController(text: quantity);

    print(
        'Item adicionado: $newItem à categoria $category no relatório $reportId');
  }

  Future<void> updateReport2(String reportId, String nome, String city,
      String loja, String data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Usuário não autenticado.");
      return;
    }

    final userId = user.uid;
    final DateTime now = DateTime.now().toUtc().add(Duration(hours: -3));
    final String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final categorias = insumos.keys.map((categoria) {
      final baseItems = List<Map<String, dynamic>>.from(insumos[categoria]!);
      final dynamicItems = reportInsumos[reportId]?[categoria] ?? [];
      final allItems = [...baseItems, ...dynamicItems];

      return {
        'Categoria': categoria,
        'Itens': allItems.map((item) {
          final itemName = item['nome'];
          final tipo = item['tipo'] ?? '';
          final key = (categoria == 'BALDES' || categoria == 'POTES')
              ? '${categoria}_$itemName'
              : itemName;

          var quantidade = quantityValues[key]?.split('/').first ?? '0';
          final minimo = minValues[key] ?? item['minimo'];

          if (quantidade.isEmpty) {
            quantidade = '0';
          }

          final isFraction = minimo.contains('/');
          final formattedQuantidade = isFraction ? '$quantidade/4' : quantidade;

          return {
            'Item': itemName,
            'Quantidade': formattedQuantidade,
            'Qtd Minima': minimo,
            'Tipo': tipo,
          };
        }).toList(),
      };
    }).toList();

    final updatedData = {
      'ID': reportId,
      'Nome do usuario': nome,
      'Data': formattedDate,
      'Cidade': city,
      'Loja': loja,
      'Categorias': categorias,
    };

    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('relatorio')
          .doc(reportId)
          .set(updatedData, SetOptions(merge: true));
      print("Relatório atualizado com sucesso: $updatedData");
    } catch (e) {
      print("Erro ao atualizar online. Salvando localmente...");
      final offlineDoc = OfflineData(
        data: updatedData,
        collectionPath: 'users/$userId/relatorio',
        docId: reportId,
        isUpdate: true,
      );
      await addToOfflineQueue(offlineDoc);
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

  // Função para excluir um relatório específico
  Future<void> deleteReport2(String reportId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("Usuário não autenticado.");
      return;
    }

    final userId = user.uid;

    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('relatorio')
          .doc(reportId)
          .delete();

      reports.removeWhere((report) => report['id'] == reportId);

      print("Relatório excluído com sucesso.");
    } catch (e) {
      print("Erro ao excluir relatório: $e");
    }
  }

  String formatReportForWhatsAppRepo(Map<String, dynamic> report) {
    final buffer = StringBuffer();

    buffer.writeln("*Relatório de Reposição*");
    buffer.writeln("Loja: *${report['Loja']}*");
    buffer.writeln("Cidade: *${report['Cidade']}*");
    buffer.writeln("Data: ${report['Data']}");
    buffer.writeln("Responsável: *${report['Nome do usuario']}*\n");

    for (final category in report['Categorias']) {
      buffer.writeln("> ${category['Categoria']}:");
      for (final item in category['Itens']) {
        final itemName = item['Item'];
        final tipo = item['Tipo'] ?? "";
        final quantidade = item['Quantidade'] != null
            ? "Quantidade: *_${item['Quantidade']} ${tipo}_*\n"
            : "";
        buffer.writeln("  • *$itemName*\n  - $quantidade".trim());
        buffer.writeln();
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  String formatRelatorioForWhatsApp(Map<String, dynamic> report) {
    final buffer = StringBuffer();

    buffer.writeln("*Relatório de Estoque*");
    buffer.writeln("Loja: *${report['Loja']}*");
    buffer.writeln("Cidade: *${report['Cidade']}*");
    buffer.writeln("Data: ${report['Data']}");
    buffer.writeln("Responsável: *${report['Nome do usuario']}*\n");

    for (final category in report['Categorias']) {
      buffer.writeln("> ${category['Categoria']}:");
      for (final item in category['Itens']) {
        final itemName = item['Item'];
        final tipo = item['Tipo'] ?? "";
        final min = item['Qtd Minima'] != null
            ? "Mínimo: *_${item['Qtd Minima']} ${tipo}_*"
            : "";
        final quantidade = item['Quantidade'] != null
            ? "Quantidade Atual: *_${item['Quantidade']} ${tipo}_*\n"
            : "";
        buffer.writeln("  • *$itemName*\n  - $quantidade  - $min".trim());
        buffer.writeln();
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  // RELATÓRIOS -----------------------------------------------------------------

  // FÁBRICA---------------------------------------------------------------------

  final Map<String, int> stockValues = {}; // Armazena os valores de estoque
  final Map<String, int> originalQuantities =
      {}; // Armazena as quantidades originais dos itens

  // Recupera o estoque atual
  int getStockValueFabrica(String itemName) {
    return stockValues[itemName] ?? 999; // Retorna 999 por padrão
  }

  // Atualiza o estoque após subtração ou ajuste
  void updateStockValueFabrica(
    String itemKey,
    int newQuantity, {
    bool isEditing = false,
  }) {
    if (stockValues.containsKey(itemKey)) {
      if (isEditing) {
        // Pega a quantidade original que salvamos
        final originalQuantity = originalQuantities[itemKey] ?? 0;
        // Calcula a diferença
        final difference = newQuantity - originalQuantity;

        stockValues[itemKey] = (stockValues[itemKey]! - difference)
            .clamp(0, double.infinity)
            .toInt();

        // Atualiza a "quantidade original" para esta nova, pois agora ela passa a ser a quantidade "oficial"
        originalQuantities[itemKey] = newQuantity;
      } else {
        // Caso seja uma "nova reposição" (não é edição), apenas subtrai o valor inteiro
        stockValues[itemKey] = (stockValues[itemKey]! - newQuantity)
            .clamp(0, double.infinity)
            .toInt();
      }
    }
  }

  // Inicializa o estoque com valor padrão (999) e armazena a quantidade original
  void initItemValuesFabrica(String category, String itemName,
      {int? initialQuantity}) {
    if (!stockValues.containsKey(itemName)) {
      stockValues[itemName] = 999; // Define o estoque inicial como 999
    }
    if (initialQuantity != null && !originalQuantities.containsKey(itemName)) {
      originalQuantities[itemName] = initialQuantity;
    }
  }

// REPOSIÇÃO ---------------------------------------------

  @observable
  Map<String, dynamic> quantityValuesRepo = {}; // Valores de quantidade

  @observable
  Map<String, dynamic> quantityValuesEditRepo =
      {}; // Valores de quantidade para edição

  @observable
  Map<String, dynamic> pesoValuesRepo =
      {}; // Novo mapa para armazenar valores de peso

  List<Map<String, dynamic>> allStores = [];

  Future<void> fetchAllStores() async {
    try {
      // Carrega relatórios da nuvem
      await fetchReportsUser('Db4XIYcNMhUgYXvF6JDJJxbc3h82');

      // Filtra relatórios (excluindo o do ID fixo)
      final allReports = [
        ...reports.where(
            (report) => report['UsuarioId'] != 'Db4XIYcNMhUgYXvF6JDJJxbc3h82'),
        ...specificReports.where(
            (report) => report['UsuarioId'] != 'Db4XIYcNMhUgYXvF6JDJJxbc3h82'),
      ];

      // Agrupa lojas únicas com cidade
      final storeSet = <String, String>{};
      for (var report in allReports) {
        final loja = report['Loja'];
        final cidade = report['Cidade'] ?? 'Indefinida';
        if (loja != null) storeSet[loja] = cidade;
      }

      allStores = storeSet.entries
          .map((e) => {'nome': e.key, 'cidade': e.value})
          .toList();

      // Salva em cache
      saveStoresToCache(allStores);
    } catch (e) {
      print('Erro ao buscar relatórios e gerar lista de lojas: $e');

      // fallback para cache local
      allStores = loadCachedStores();
    }
  }

  void saveStoresToCache(List<Map<String, dynamic>> stores) {
    final box = GetStorage();
    box.write('cached_stores', stores);
  }

  List<Map<String, dynamic>> loadCachedStores() {
    final box = GetStorage();
    final cached = box.read('cached_stores');

    if (cached is List) {
      return cached.cast<Map<String, dynamic>>();
    } else {
      return [];
    }
  }

  @action
  void updateQuantityEdit(String itemName, String quantity) {
    if (_isValidNumber(quantity) && quantity.isNotEmpty) {
      quantityValuesEditRepo[itemName] = quantity;
      box.write('quantityValuesEditRepo', quantityValuesEditRepo);
    }
  }

  @action
  void updateQuantityReposicao(String itemName, String quantity) {
    if (_isValidNumber(quantity)) {
      quantityValuesRepo[itemName] = quantity;
      box.write('quantityValuesRepo', quantityValuesRepo);
    }
  }

  @action
  void updatePesoReposicao(String itemName, String peso) {
    if (_isValidNumber(peso)) {
      pesoValuesRepo[itemName] = peso;
      box.write('pesoValuesRepo', pesoValuesRepo);
    }
  }

  @action
  Future<void> updateReposicao(
    String reportId,
    String nome,
    String city,
    String loja,
    String data,
    Map<String, dynamic> reportData,
  ) async {
    final DateTime now = DateTime.now().toUtc().add(const Duration(hours: -3));
    final String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final categorias = (reportData['Categorias'] as List<dynamic>?)
        ?.map((categoria) {
          final categoryName = categoria['Categoria'];
          final items = (categoria['Itens'] as List<dynamic>)
              .map((item) {
                final itemName = item['Item'];
                final key = generateKey(categoryName, itemName);
                final quantidadeAtual =
                    quantityValuesEditRepo[key]?.trim() ?? '';
                final pesoAtual = pesoValuesRepo[key]?.trim() ?? '';

                return {
                  'Item': itemName,
                  'Quantidade': quantidadeAtual.isNotEmpty
                      ? quantidadeAtual
                      : item['Quantidade'],
                  'Qtd Anterior': item['Quantidade'] ?? '0',
                  'Qtd Minima': item['Qtd Minima'] ?? '',
                  'Peso': pesoAtual,
                  'Tipo': item['Tipo'] ?? '',
                };
              })
              .where((item) => item['Quantidade'] != '')
              .toList();

          return items.isNotEmpty
              ? {'Categoria': categoryName, 'Itens': items}
              : null;
        })
        .where((categoria) => categoria != null)
        .toList();

    final updatedData = {
      'ID': reportId,
      'Nome do usuario': nome,
      'Data': formattedDate,
      'Cidade': city,
      'Loja': loja,
      'Categorias': categorias ?? [],
    };

    final collectionPath = 'users/Db4XIYcNMhUgYXvF6JDJJxbc3h82/reposicao';

    if (!await hasInternetConnection()) {
      final offlineDoc = OfflineData(
        data: updatedData,
        collectionPath: collectionPath,
        docId: reportId,
        isUpdate: true,
      );
      await addToOfflineQueue(offlineDoc);
      clearRepoFields();
      return;
    }

    try {
      await firestore
          .collection('users')
          .doc('Db4XIYcNMhUgYXvF6JDJJxbc3h82')
          .collection('reposicao')
          .doc(reportId)
          .set(updatedData, SetOptions(merge: true));

      print("Reposição atualizada online: $updatedData");
    } catch (e) {
      print("Erro ou sem conexão. Salvando atualização offline...");
      final offlineDoc = OfflineData(
        data: updatedData,
        collectionPath: 'users/Db4XIYcNMhUgYXvF6JDJJxbc3h82/reposicao',
        docId: reportId,
        isUpdate: true,
      );
      await addToOfflineQueue(offlineDoc);
    }
  }

  @action
  Future<String> copyReportToReposicao(
      Map<String, dynamic> report, String newName) async {
    try {
      final categorias = report['Categorias'] as List<dynamic>? ?? [];
      final reposicaoCategorias = categorias.map((categoria) {
        final items = (categoria['Itens'] as List<dynamic>).map((item) {
          return {
            'Item': item['Item'],
            'Quantidade': '',
            'Qtd Anterior': item['Quantidade'] ?? '',
            'Qtd Minima': item['Qtd Minima'],
            'Peso': item['Peso'] ?? '',
            'Tipo': item['Tipo'],
          };
        }).toList();

        return {
          'Categoria': categoria['Categoria'],
          'Itens': items,
        };
      }).toList();

      final reposicaoData = {
        'Nome do usuario': newName,
        'Data': DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
        'Cidade': report['Cidade'] ?? '',
        'Loja': report['Loja'] ?? '',
        'Categorias': reposicaoCategorias,
      };

      final dataFormat = DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());
      final comandaId = '${dataFormat} - ${report['Loja']}';
      final uuid = comandaId;

      try {
        await secondaryFirestore
            .collection('users')
            .doc('Db4XIYcNMhUgYXvF6JDJJxbc3h82')
            .collection('reposicao')
            .doc(uuid)
            .set(reposicaoData, SetOptions(merge: true));
        return uuid;
      } catch (e) {
        print("Erro ao salvar online. Salvando localmente...");
        final offlineDoc = OfflineData(
          data: reposicaoData,
          collectionPath: 'users/Db4XIYcNMhUgYXvF6JDJJxbc3h82/reposicao',
          docId: uuid,
          isUpdate: false,
        );
        await addToOfflineQueue(offlineDoc);
        return uuid;
      }
    } catch (e) {
      throw Exception("Erro ao copiar relatório: $e");
    }
  }

  @action
  Future<void> updateEditReposicao(
    String reportId,
    String nome,
    String city,
    String loja,
    String data,
  ) async {
    final DateTime now = DateTime.now().toUtc().add(const Duration(hours: -3));
    final String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final categorias = insumos.keys
        .map((category) {
          final items = <Map<String, dynamic>>[];
          for (var item in insumos[category] ?? []) {
            final itemName = item['nome'];
            final tipo = item['tipo'] ?? '';
            final key = generateKey(category, itemName);
            final quantidade = quantityValuesEditRepo[key]?.trim() ?? '';
            final peso = pesoValuesRepo[key]?.trim() ?? '';

            if (quantidade.isNotEmpty) {
              items.add({
                'Item': itemName,
                'Quantidade': quantidade,
                'Qtd Anterior': quantityValuesEditRepo[key] ?? '0',
                'Peso': peso,
                'Tipo': tipo,
              });
            }
          }
          return items.isNotEmpty
              ? {'Categoria': category, 'Itens': items}
              : null;
        })
        .where((categoria) => categoria != null)
        .cast<Map<String, dynamic>>()
        .toList();

    final updatedData = {
      'ID': reportId,
      'Nome do usuario': nome,
      'Data': formattedDate,
      'Cidade': city,
      'Loja': loja,
      'Categorias': categorias,
    };

    try {
      await firestore
          .collection('users')
          .doc('Db4XIYcNMhUgYXvF6JDJJxbc3h82')
          .collection('reposicao')
          .doc(reportId)
          .set(updatedData, SetOptions(merge: true));
      clearRepoFields();
      await fetchReports();
    } catch (e) {
      final offlineDoc = OfflineData(
        data: updatedData,
        collectionPath: 'users/Db4XIYcNMhUgYXvF6JDJJxbc3h82/reposicao',
        docId: reportId,
        isUpdate: true,
      );
      await addToOfflineQueue(offlineDoc);
    }
  }

  Future<void> deleteReposicao(String reportId) async {
    try {
      await secondaryFirestore
          .collection('users')
          .doc('Db4XIYcNMhUgYXvF6JDJJxbc3h82')
          .collection('reposicao')
          .doc(reportId)
          .delete();

      reports.removeWhere((report) => report['ID'] == reportId);
      print("Relatório excluído com sucesso.");
    } catch (e) {
      print("Erro ao excluir relatório: $e");
    }
  }

  @action
  void clearRepoFields() {
    quantityValuesRepo.clear();
    quantityValuesEditRepo.clear();
    pesoValuesRepo.clear();
  }

  String generateKey(String category, String itemName) {
    return (category == 'BALDES' || category == 'POTES')
        ? '${category}_$itemName'
        : itemName;
  }

  void populateFieldsWithEditRepo(Map<String, dynamic> reportData) {
    final categorias = reportData['Categorias'] as List<dynamic>?;

    categorias?.forEach((categoria) {
      final categoryName = categoria['Categoria'];
      final itens = categoria['Itens'] as List<dynamic>;

      for (final item in itens) {
        final itemName = item['Item'];
        final key = generateKey(categoryName, itemName);
        final quantidade = item['Quantidade']?.toString() ?? '0';
        final peso = item['Peso']?.toString() ?? '';

        quantityValuesEditRepo[key] = quantidade;
        pesoValuesRepo[key] = peso;
      }
    });
  }

  void populateFieldsWithRepo(Map<String, dynamic> reportData) {
    final categorias = reportData['Categorias'] as List<dynamic>?;

    categorias?.forEach((categoria) {
      final categoryName = categoria['Categoria'];
      final itens = categoria['Itens'] as List<dynamic>;

      for (final item in itens) {
        final itemName = item['Item'];
        final key = generateKey(categoryName, itemName);
        final quantidadeAnterior = item['Quantidade'] ?? '';
        final peso = item['Peso'] ?? '';

        quantityValuesRepo[key] = ''; // Quantidade inicial vazia
        pesoValuesRepo[key] = peso;
      }
    });
  }
}
