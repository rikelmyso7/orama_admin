// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$StockStore on _StockStore, Store {
  late final _$kgValuesAtom =
      Atom(name: '_StockStore.kgValues', context: context);

  @override
  Map<String, dynamic> get kgValues {
    _$kgValuesAtom.reportRead();
    return super.kgValues;
  }

  @override
  set kgValues(Map<String, dynamic> value) {
    _$kgValuesAtom.reportWrite(value, super.kgValues, () {
      super.kgValues = value;
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

  late final _$userRoleAtom =
      Atom(name: '_StockStore.userRole', context: context);

  @override
  String? get userRole {
    _$userRoleAtom.reportRead();
    return super.userRole;
  }

  @override
  set userRole(String? value) {
    _$userRoleAtom.reportWrite(value, super.userRole, () {
      super.userRole = value;
    });
  }

  late final _$kgControllersAtom =
      Atom(name: '_StockStore.kgControllers', context: context);

  @override
  Map<String, TextEditingController> get kgControllers {
    _$kgControllersAtom.reportRead();
    return super.kgControllers;
  }

  @override
  set kgControllers(Map<String, TextEditingController> value) {
    _$kgControllersAtom.reportWrite(value, super.kgControllers, () {
      super.kgControllers = value;
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

  late final _$selectedCityAtom =
      Atom(name: '_StockStore.selectedCity', context: context);

  @override
  String get selectedCity {
    _$selectedCityAtom.reportRead();
    return super.selectedCity;
  }

  @override
  set selectedCity(String value) {
    _$selectedCityAtom.reportWrite(value, super.selectedCity, () {
      super.selectedCity = value;
    });
  }

  late final _$fetchReportsAsyncAction =
      AsyncAction('_StockStore.fetchReports', context: context);

  @override
  Future<void> fetchReports({String? city}) {
    return _$fetchReportsAsyncAction.run(() => super.fetchReports(city: city));
  }

  late final _$_StockStoreActionController =
      ActionController(name: '_StockStore', context: context);

  @override
  void updateKg(String itemName, String kgValue) {
    final _$actionInfo =
        _$_StockStoreActionController.startAction(name: '_StockStore.updateKg');
    try {
      return super.updateKg(itemName, kgValue);
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
  void setCity(String city) {
    final _$actionInfo =
        _$_StockStoreActionController.startAction(name: '_StockStore.setCity');
    try {
      return super.setCity(city);
    } finally {
      _$_StockStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
kgValues: ${kgValues},
quantityValues: ${quantityValues},
userRole: ${userRole},
kgControllers: ${kgControllers},
quantityControllers: ${quantityControllers},
selectedCity: ${selectedCity}
    ''';
  }
}
