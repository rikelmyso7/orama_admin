// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$StockStore on _StockStore, Store {
  late final _$selectedDateAtom =
      Atom(name: '_StockStore.selectedDate', context: context);

  @override
  DateTime get selectedDate {
    _$selectedDateAtom.reportRead();
    return super.selectedDate;
  }

  @override
  set selectedDate(DateTime value) {
    _$selectedDateAtom.reportWrite(value, super.selectedDate, () {
      super.selectedDate = value;
    });
  }

  late final _$reportsAtom =
      Atom(name: '_StockStore.reports', context: context);

  @override
  ObservableList<Map<String, dynamic>> get reports {
    _$reportsAtom.reportRead();
    return super.reports;
  }

  @override
  set reports(ObservableList<Map<String, dynamic>> value) {
    _$reportsAtom.reportWrite(value, super.reports, () {
      super.reports = value;
    });
  }

  late final _$categoriasAtom =
      Atom(name: '_StockStore.categorias', context: context);

  @override
  ObservableList<String> get categorias {
    _$categoriasAtom.reportRead();
    return super.categorias;
  }

  @override
  set categorias(ObservableList<String> value) {
    _$categoriasAtom.reportWrite(value, super.categorias, () {
      super.categorias = value;
    });
  }

  late final _$quantityValuesAtom =
      Atom(name: '_StockStore.quantityValues', context: context);

  @override
  Map<String, dynamic> get quantityValues {
    _$quantityValuesAtom.reportRead();
    return super.quantityValues;
  }

  @override
  set quantityValues(Map<String, dynamic> value) {
    _$quantityValuesAtom.reportWrite(value, super.quantityValues, () {
      super.quantityValues = value;
    });
  }

  late final _$quantityControllersAtom =
      Atom(name: '_StockStore.quantityControllers', context: context);

  @override
  Map<String, TextEditingController> get quantityControllers {
    _$quantityControllersAtom.reportRead();
    return super.quantityControllers;
  }

  @override
  set quantityControllers(Map<String, TextEditingController> value) {
    _$quantityControllersAtom.reportWrite(value, super.quantityControllers, () {
      super.quantityControllers = value;
    });
  }

  late final _$quantityControllersAddAtom =
      Atom(name: '_StockStore.quantityControllersAdd', context: context);

  @override
  Map<String, TextEditingController> get quantityControllersAdd {
    _$quantityControllersAddAtom.reportRead();
    return super.quantityControllersAdd;
  }

  @override
  set quantityControllersAdd(Map<String, TextEditingController> value) {
    _$quantityControllersAddAtom
        .reportWrite(value, super.quantityControllersAdd, () {
      super.quantityControllersAdd = value;
    });
  }

  late final _$isLoadingAtom =
      Atom(name: '_StockStore.isLoading', context: context);

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$reports2Atom =
      Atom(name: '_StockStore.reports2', context: context);

  @override
  ObservableList<Map<String, dynamic>> get reports2 {
    _$reports2Atom.reportRead();
    return super.reports2;
  }

  @override
  set reports2(ObservableList<Map<String, dynamic>> value) {
    _$reports2Atom.reportWrite(value, super.reports2, () {
      super.reports2 = value;
    });
  }

  late final _$quantityValues2Atom =
      Atom(name: '_StockStore.quantityValues2', context: context);

  @override
  ObservableMap<String, String> get quantityValues2 {
    _$quantityValues2Atom.reportRead();
    return super.quantityValues2;
  }

  @override
  set quantityValues2(ObservableMap<String, String> value) {
    _$quantityValues2Atom.reportWrite(value, super.quantityValues2, () {
      super.quantityValues2 = value;
    });
  }

  late final _$minValuesAtom =
      Atom(name: '_StockStore.minValues', context: context);

  @override
  ObservableMap<String, String> get minValues {
    _$minValuesAtom.reportRead();
    return super.minValues;
  }

  @override
  set minValues(ObservableMap<String, String> value) {
    _$minValuesAtom.reportWrite(value, super.minValues, () {
      super.minValues = value;
    });
  }

  late final _$quantityControllers2Atom =
      Atom(name: '_StockStore.quantityControllers2', context: context);

  @override
  Map<String, TextEditingController> get quantityControllers2 {
    _$quantityControllers2Atom.reportRead();
    return super.quantityControllers2;
  }

  @override
  set quantityControllers2(Map<String, TextEditingController> value) {
    _$quantityControllers2Atom.reportWrite(value, super.quantityControllers2,
        () {
      super.quantityControllers2 = value;
    });
  }

  late final _$minControllersAtom =
      Atom(name: '_StockStore.minControllers', context: context);

  @override
  Map<String, TextEditingController> get minControllers {
    _$minControllersAtom.reportRead();
    return super.minControllers;
  }

  @override
  set minControllers(Map<String, TextEditingController> value) {
    _$minControllersAtom.reportWrite(value, super.minControllers, () {
      super.minControllers = value;
    });
  }

  late final _$quantityValuesRepoAtom =
      Atom(name: '_StockStore.quantityValuesRepo', context: context);

  @override
  Map<String, dynamic> get quantityValuesRepo {
    _$quantityValuesRepoAtom.reportRead();
    return super.quantityValuesRepo;
  }

  @override
  set quantityValuesRepo(Map<String, dynamic> value) {
    _$quantityValuesRepoAtom.reportWrite(value, super.quantityValuesRepo, () {
      super.quantityValuesRepo = value;
    });
  }

  late final _$quantityValuesEditRepoAtom =
      Atom(name: '_StockStore.quantityValuesEditRepo', context: context);

  @override
  Map<String, dynamic> get quantityValuesEditRepo {
    _$quantityValuesEditRepoAtom.reportRead();
    return super.quantityValuesEditRepo;
  }

  @override
  set quantityValuesEditRepo(Map<String, dynamic> value) {
    _$quantityValuesEditRepoAtom
        .reportWrite(value, super.quantityValuesEditRepo, () {
      super.quantityValuesEditRepo = value;
    });
  }

  late final _$pesoValuesRepoAtom =
      Atom(name: '_StockStore.pesoValuesRepo', context: context);

  @override
  Map<String, dynamic> get pesoValuesRepo {
    _$pesoValuesRepoAtom.reportRead();
    return super.pesoValuesRepo;
  }

  @override
  set pesoValuesRepo(Map<String, dynamic> value) {
    _$pesoValuesRepoAtom.reportWrite(value, super.pesoValuesRepo, () {
      super.pesoValuesRepo = value;
    });
  }

  late final _$syncAllPendingDataAsyncAction =
      AsyncAction('_StockStore.syncAllPendingData', context: context);

  @override
  Future<void> syncAllPendingData() {
    return _$syncAllPendingDataAsyncAction
        .run(() => super.syncAllPendingData());
  }

  late final _$syncLocalOperationsAsyncAction =
      AsyncAction('_StockStore.syncLocalOperations', context: context);

  @override
  Future<void> syncLocalOperations(String key,
      {required Future<void> Function(Map<String, dynamic>) onSync}) {
    return _$syncLocalOperationsAsyncAction
        .run(() => super.syncLocalOperations(key, onSync: onSync));
  }

  late final _$fetchReportsAsyncAction =
      AsyncAction('_StockStore.fetchReports', context: context);

  @override
  Future<void> fetchReports() {
    return _$fetchReportsAsyncAction.run(() => super.fetchReports());
  }

  late final _$deleteReportAsyncAction =
      AsyncAction('_StockStore.deleteReport', context: context);

  @override
  Future<void> deleteReport(String reportId) {
    return _$deleteReportAsyncAction.run(() => super.deleteReport(reportId));
  }

  late final _$fetchReportsUserAsyncAction =
      AsyncAction('_StockStore.fetchReportsUser', context: context);

  @override
  Future<void> fetchReportsUser(String excludedUserId) {
    return _$fetchReportsUserAsyncAction
        .run(() => super.fetchReportsUser(excludedUserId));
  }

  late final _$saveDataToAdminRelatoriosAsyncAction =
      AsyncAction('_StockStore.saveDataToAdminRelatorios', context: context);

  @override
  Future<void> saveDataToAdminRelatorios(
      String nome, String data, String city, String loja,
      {String? reportId}) {
    return _$saveDataToAdminRelatoriosAsyncAction.run(() => super
        .saveDataToAdminRelatorios(nome, data, city, loja, reportId: reportId));
  }

  late final _$updateReportAsyncAction =
      AsyncAction('_StockStore.updateReport', context: context);

  @override
  Future<void> updateReport(
      String reportId, String nome, String city, String loja, String data) {
    return _$updateReportAsyncAction
        .run(() => super.updateReport(reportId, nome, city, loja, data));
  }

  late final _$getReportAsyncAction =
      AsyncAction('_StockStore.getReport', context: context);

  @override
  Future<Map<String, dynamic>?> getReport(String reportId) {
    return _$getReportAsyncAction.run(() => super.getReport(reportId));
  }

  late final _$saveData2AsyncAction =
      AsyncAction('_StockStore.saveData2', context: context);

  @override
  Future<void> saveData2(String nome, String data, String city, String loja,
      {String? reportId}) {
    return _$saveData2AsyncAction
        .run(() => super.saveData2(nome, data, city, loja, reportId: reportId));
  }

  late final _$fetchReports2AsyncAction =
      AsyncAction('_StockStore.fetchReports2', context: context);

  @override
  Future<void> fetchReports2() {
    return _$fetchReports2AsyncAction.run(() => super.fetchReports2());
  }

  late final _$fetchReportsEspecificoAsyncAction =
      AsyncAction('_StockStore.fetchReportsEspecifico', context: context);

  @override
  Future<void> fetchReportsEspecifico() {
    return _$fetchReportsEspecificoAsyncAction
        .run(() => super.fetchReportsEspecifico());
  }

  late final _$updateReposicaoAsyncAction =
      AsyncAction('_StockStore.updateReposicao', context: context);

  @override
  Future<void> updateReposicao(String reportId, String nome, String city,
      String loja, String data, Map<String, dynamic> reportData) {
    return _$updateReposicaoAsyncAction.run(() =>
        super.updateReposicao(reportId, nome, city, loja, data, reportData));
  }

  late final _$copyReportToReposicaoAsyncAction =
      AsyncAction('_StockStore.copyReportToReposicao', context: context);

  @override
  Future<String> copyReportToReposicao(
      Map<String, dynamic> report, String newName) {
    return _$copyReportToReposicaoAsyncAction
        .run(() => super.copyReportToReposicao(report, newName));
  }

  late final _$updateEditReposicaoAsyncAction =
      AsyncAction('_StockStore.updateEditReposicao', context: context);

  @override
  Future<void> updateEditReposicao(
      String reportId, String nome, String city, String loja, String data) {
    return _$updateEditReposicaoAsyncAction
        .run(() => super.updateEditReposicao(reportId, nome, city, loja, data));
  }

  late final _$fetchCategoriasAsyncAction =
      AsyncAction('_StockStore.fetchCategorias', context: context);

  @override
  Future<void> fetchCategorias() {
    return _$fetchCategoriasAsyncAction.run(() => super.fetchCategorias());
  }

  late final _$addCategoriaAsyncAction =
      AsyncAction('_StockStore.addCategoria', context: context);

  @override
  Future<void> addCategoria(String nomeCategoria) {
    return _$addCategoriaAsyncAction
        .run(() => super.addCategoria(nomeCategoria));
  }

  late final _$removeCategoriaAsyncAction =
      AsyncAction('_StockStore.removeCategoria', context: context);

  @override
  Future<void> removeCategoria(String nomeCategoria) {
    return _$removeCategoriaAsyncAction
        .run(() => super.removeCategoria(nomeCategoria));
  }

  late final _$_StockStoreActionController =
      ActionController(name: '_StockStore', context: context);

  @override
  void setSelectedDate(DateTime date) {
    final _$actionInfo = _$_StockStoreActionController.startAction(
        name: '_StockStore.setSelectedDate');
    try {
      return super.setSelectedDate(date);
    } finally {
      _$_StockStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void saveReportsToCache(List<Map<String, dynamic>> reports) {
    final _$actionInfo = _$_StockStoreActionController.startAction(
        name: '_StockStore.saveReportsToCache');
    try {
      return super.saveReportsToCache(reports);
    } finally {
      _$_StockStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void initControllers(String itemName) {
    final _$actionInfo = _$_StockStoreActionController.startAction(
        name: '_StockStore.initControllers');
    try {
      return super.initControllers(itemName);
    } finally {
      _$_StockStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearFields() {
    final _$actionInfo = _$_StockStoreActionController.startAction(
        name: '_StockStore.clearFields');
    try {
      return super.clearFields();
    } finally {
      _$_StockStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateQuantity(String itemName, String quantity) {
    final _$actionInfo = _$_StockStoreActionController.startAction(
        name: '_StockStore.updateQuantity');
    try {
      return super.updateQuantity(itemName, quantity);
    } finally {
      _$_StockStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void initItemValues(String category, String itemName, String minimoPadrao,
      {String? tipo}) {
    final _$actionInfo = _$_StockStoreActionController.startAction(
        name: '_StockStore.initItemValues');
    try {
      return super.initItemValues(category, itemName, minimoPadrao, tipo: tipo);
    } finally {
      _$_StockStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateMinValue(String key, String minValue) {
    final _$actionInfo = _$_StockStoreActionController.startAction(
        name: '_StockStore.updateMinValue');
    try {
      return super.updateMinValue(key, minValue);
    } finally {
      _$_StockStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateQuantity2(String key, String quantity) {
    final _$actionInfo = _$_StockStoreActionController.startAction(
        name: '_StockStore.updateQuantity2');
    try {
      return super.updateQuantity2(key, quantity);
    } finally {
      _$_StockStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearFields2() {
    final _$actionInfo = _$_StockStoreActionController.startAction(
        name: '_StockStore.clearFields2');
    try {
      return super.clearFields2();
    } finally {
      _$_StockStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void removeItemFromReport(
      {required String reportId,
      required String category,
      required String name}) {
    final _$actionInfo = _$_StockStoreActionController.startAction(
        name: '_StockStore.removeItemFromReport');
    try {
      return super.removeItemFromReport(
          reportId: reportId, category: category, name: name);
    } finally {
      _$_StockStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateQuantityEdit(String itemName, String quantity) {
    final _$actionInfo = _$_StockStoreActionController.startAction(
        name: '_StockStore.updateQuantityEdit');
    try {
      return super.updateQuantityEdit(itemName, quantity);
    } finally {
      _$_StockStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateQuantityReposicao(String itemName, String quantity) {
    final _$actionInfo = _$_StockStoreActionController.startAction(
        name: '_StockStore.updateQuantityReposicao');
    try {
      return super.updateQuantityReposicao(itemName, quantity);
    } finally {
      _$_StockStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updatePesoReposicao(String itemName, String peso) {
    final _$actionInfo = _$_StockStoreActionController.startAction(
        name: '_StockStore.updatePesoReposicao');
    try {
      return super.updatePesoReposicao(itemName, peso);
    } finally {
      _$_StockStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearRepoFields() {
    final _$actionInfo = _$_StockStoreActionController.startAction(
        name: '_StockStore.clearRepoFields');
    try {
      return super.clearRepoFields();
    } finally {
      _$_StockStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
selectedDate: ${selectedDate},
reports: ${reports},
categorias: ${categorias},
quantityValues: ${quantityValues},
quantityControllers: ${quantityControllers},
quantityControllersAdd: ${quantityControllersAdd},
isLoading: ${isLoading},
reports2: ${reports2},
quantityValues2: ${quantityValues2},
minValues: ${minValues},
quantityControllers2: ${quantityControllers2},
minControllers: ${minControllers},
quantityValuesRepo: ${quantityValuesRepo},
quantityValuesEditRepo: ${quantityValuesEditRepo},
pesoValuesRepo: ${pesoValuesRepo}
    ''';
  }
}
