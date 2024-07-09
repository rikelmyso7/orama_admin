import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mobx/mobx.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

part 'comanda_store.g.dart';

//SaborStore.dart
class SaborStore = _SaborStore with _$SaborStore;

abstract class _SaborStore with Store {
  @observable
  ObservableList<Sabor> sabores = ObservableList<Sabor>();

  @action
  void addSabor(Sabor sabor) {
    sabores.add(sabor);
  }

  @action
  void removeSabor(Sabor sabor) {
    sabores.remove(sabor);
  }

  @action
  void updateSabor(int index, Sabor sabor) {
    sabores[index] = sabor;
  }

  // TabViewState
  @observable
  int currentIndex = 0;

  @observable
  ObservableMap<String, ObservableMap<String, Map<String, int>>>
      saboresSelecionados = ObservableMap();

  @observable
  ObservableMap<String, ObservableMap<String, bool>> expansionState =
      ObservableMap();

  @action
  void setCurrentIndex(int index) {
    currentIndex = index;
  }

  @action
  void updateSaborTabView(
      String categoria, String sabor, Map<String, int> quantidade) {
    if (!saboresSelecionados.containsKey(categoria)) {
      saboresSelecionados[categoria] = ObservableMap();
    }
    saboresSelecionados[categoria]![sabor] = quantidade;
  }

  @action
  void setExpansionState(String categoria, String sabor, bool isExpanded) {
    if (!expansionState.containsKey(categoria)) {
      expansionState[categoria] = ObservableMap();
    }
    expansionState[categoria]![sabor] = isExpanded;
  }

  @action
  void resetExpansionState() {
    expansionState.clear();
  }

  @action
  void resetSaborTabView() {
    saboresSelecionados.clear();
  }
}

//Sabor.dart
@JsonSerializable()
class Sabor {
  String nome;
  String categoria;
  int quantidade;

  Sabor(
      {required this.nome, required this.categoria, required this.quantidade});

  factory Sabor.fromJson(Map<String, dynamic> json) => _$SaborFromJson(json);
  Map<String, dynamic> toJson() => _$SaborToJson(this);
}

class Comanda {
  String name;
  String userId;
  String id;
  String pdv;
  Map<String, Map<String, Map<String, int>>> sabores;
  DateTime data;

  Comanda({
    required this.name,
    required this.id,
    required this.pdv,
    required this.userId,
    required this.sabores,
    required this.data,
  });

  factory Comanda.fromJson(Map<String, dynamic> json) {
    Map<String, Map<String, Map<String, int>>> saboresConvertidos = {};
    Map<String, dynamic> saboresJson = json['sabores'];

    saboresJson.forEach((categoria, saboresMap) {
      saboresConvertidos[categoria] = {};
      (saboresMap as Map<String, dynamic>).forEach((sabor, opcoesMap) {
        final opcoesCompletas = {
          '0': 0,
          '1/4': 0,
          '2/4': 0,
          '3/4': 0,
          '4/4': 0,
        };
        opcoesCompletas.addAll(Map<String, int>.from(opcoesMap));
        saboresConvertidos[categoria]![sabor] = opcoesCompletas;
      });
    });

    return Comanda(
      id: json['id'],
      pdv: json['pdv'],
      sabores: saboresConvertidos,
      data: DateTime.parse(json['data']),
      name: json['name'] ?? '',
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final filteredSabores = <String, Map<String, Map<String, int>>>{};

    sabores.forEach((categoria, saboresMap) {
      final filteredCategoria = <String, Map<String, int>>{};

      saboresMap.forEach((sabor, opcoesMap) {
        final filteredOpcoes = <String, int>{};

        opcoesMap.forEach((opcao, quantidade) {
          if (quantidade > 0) {
            filteredOpcoes[opcao] = quantidade;
          }
        });

        if (filteredOpcoes.isNotEmpty) {
          filteredCategoria[sabor] = filteredOpcoes;
        }
      });

      if (filteredCategoria.isNotEmpty) {
        filteredSabores[categoria] = filteredCategoria;
      }
    });

    return {
      'id': id,
      'pdv': pdv,
      'sabores': filteredSabores,
      'data': data.toIso8601String(),
      'name': name,
      'userId': userId,
    };
  }
}

class ComandaStore = _ComandaStoreBase with _$ComandaStore;

abstract class _ComandaStoreBase with Store {
  final GetStorage _storage = GetStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _comandasCollection = FirebaseFirestore.instance
      .collection('users')
      .doc('VFBwvWYLh8bnHQzMtgSKiBI4usE3')
      .collection('comandas');
  final Uuid _uuid = Uuid();

  _ComandaStoreBase() {
    _loadComandas();
    _syncWithFirebase();
  }

  @observable
  ObservableList<Comanda> comandas = ObservableList<Comanda>();

  @observable
  DateTime selectedDate = DateTime.now();

  @observable
  ObservableMap<String, bool> expansionState = ObservableMap<String, bool>();

  @action
  void setExpansionState(String comandaId, bool isExpanded) {
    expansionState[comandaId] = isExpanded;
  }

  @action
  bool getExpansionState(String comandaId) {
    return expansionState[comandaId] ?? false;
  }

  @action
  void addOrUpdateCard(Comanda comanda) {
    final filteredSabores = _filterSabores(comanda.sabores);
    comanda.sabores = filteredSabores;

    final index = comandas.indexWhere((c) => c.id == comanda.id);
    if (index == -1) {
      comanda.id = _uuid.v4(); // Gerar UUID para novas comandas
      comandas.add(comanda);
    } else {
      comandas[index] = comanda;
    }
    _saveComandas();
    _saveToFirebase(comanda);
  }

  @action
  void removeComanda(int index) {
    final comanda = comandas[index];
    comandas.removeAt(index);
    _saveComandas();
    _removeFromFirebase(comanda);
  }

  @action
  void setSelectedDate(DateTime date) {
    selectedDate = date;
  }

  @action
  List<Comanda> getComandasForSelectedDay(DateTime date) {
    return comandas
        .where((comanda) =>
            comanda.data.year == date.year &&
            comanda.data.month == date.month &&
            comanda.data.day == date.day)
        .toList();
  }

  Future<void> _loadComandas() async {
    final data = await _storage.read('comandas') as List<dynamic>?;

    if (data != null) {
      comandas = ObservableList<Comanda>.of(
        data.map((json) => Comanda.fromJson(json as Map<String, dynamic>)),
      );
    }
  }

  Future<void> _saveComandas() async {
    await _storage.write('comandas', comandas.map((c) => c.toJson()).toList());
  }

  Future<void> _saveToFirebase(Comanda comanda) async {
    try {
      await _comandasCollection.doc(comanda.id).set(comanda.toJson());
    } catch (e) {
      print('Failed to save comanda to Firebase: $e');
    }
  }

  Future<void> _removeFromFirebase(Comanda comanda) async {
    try {
      await _comandasCollection.doc(comanda.id).delete();
    } catch (e) {
      print('Failed to remove comanda from Firebase: $e');
    }
  }

  Future<void> _syncWithFirebase() async {
    try {
      final querySnapshot = await _comandasCollection.get();
      final firebaseComandas = querySnapshot.docs
          .map((doc) => Comanda.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      comandas = ObservableList<Comanda>.of(firebaseComandas);
      _saveComandas();
    } catch (e) {
      print('Failed to sync comandas with Firebase: $e');
    }
  }

  Map<String, Map<String, Map<String, int>>> _filterSabores(
      Map<String, Map<String, Map<String, int>>> saboresSelecionados) {
    final filteredSabores = <String, Map<String, Map<String, int>>>{};

    saboresSelecionados.forEach((categoria, sabores) {
      final filteredCategoria = <String, Map<String, int>>{};

      sabores.forEach((sabor, opcoes) {
        final filteredOpcoes = <String, int>{};

        opcoes.forEach((opcao, quantidade) {
          if (quantidade > 0) {
            filteredOpcoes[opcao] = quantidade;
          }
        });

        if (filteredOpcoes.isNotEmpty) {
          filteredCategoria[sabor] = filteredOpcoes;
        }
      });

      if (filteredCategoria.isNotEmpty) {
        filteredSabores[categoria] = filteredCategoria;
      }
    });

    return filteredSabores;
  }

  @action
  Future<void> syncWithFirebaseChanges() async {
    try {
      final querySnapshot = await _comandasCollection.get();
      final firebaseComandas = querySnapshot.docs
          .map((doc) => Comanda.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Verifica se há diferenças entre os dados locais e do Firebase
      final localIds = comandas.map((c) => c.id).toSet();
      final firebaseIds = firebaseComandas.map((c) => c.id).toSet();

      // Remove comandas locais que não estão mais no Firebase
      final removedComandas = comandas.where((c) => !firebaseIds.contains(c.id)).toList();
      removedComandas.forEach((c) => comandas.remove(c));

      // Adiciona ou atualiza comandas do Firebase localmente
      firebaseComandas.forEach((firebaseComanda) {
        final index = comandas.indexWhere((c) => c.id == firebaseComanda.id);
        if (index == -1) {
          comandas.add(firebaseComanda);
        } else {
          comandas[index] = firebaseComanda;
        }
      });

      // Salva os dados atualizados localmente
      await _saveComandas();
    } catch (e) {
      print('Failed to sync comandas with Firebase: $e');
    }
  }
}
