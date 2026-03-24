import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:orama_admin/firebase_options.dart';
import 'package:orama_admin/routes/routes.dart';
import 'package:orama_admin/stores/comanda_store.dart';
import 'package:orama_admin/stores/stock_store.dart';
import 'package:orama_admin/despesas/despesas_store.dart';
import 'package:orama_admin/vendas/vendas_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

// Variáveis globais para os bancos de dados
late FirebaseFirestore primaryFirestore;
late FirebaseFirestore secondaryFirestore;
late FirebaseDatabase salesDatabase;

Future<void> initializeFirebase() async {
  try {
    final FirebaseApp primaryApp;
    if (Firebase.apps.any((a) => a.name == '[DEFAULT]')) {
      primaryApp = Firebase.app();
    } else {
      primaryApp = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final FirebaseApp secondaryApp;
    if (Firebase.apps.any((a) => a.name == 'SecondaryApp')) {
      secondaryApp = Firebase.app('SecondaryApp');
    } else {
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: SecondaryFirebaseOptions.options,
      );
    }

    final FirebaseApp salesApp;
    if (Firebase.apps.any((a) => a.name == 'SalesApp')) {
      salesApp = Firebase.app('SalesApp');
    } else {
      salesApp = await Firebase.initializeApp(
        name: 'SalesApp',
        options: SalesFirebaseOptions.options,
      );
    }

    // Instâncias do Firestore para cada banco de dados
    primaryFirestore = FirebaseFirestore.instanceFor(app: primaryApp);
    secondaryFirestore = FirebaseFirestore.instanceFor(app: secondaryApp);

    // Instância do Realtime Database para vendas
    salesDatabase = FirebaseDatabase.instanceFor(
      app: salesApp,
      databaseURL: SalesFirebaseOptions.options.databaseURL!,
    );

    // Configurações para habilitar o cache offline
    primaryFirestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    secondaryFirestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    print("Firebase inicializado com sucesso!");
  } catch (e) {
    print("Erro ao inicializar Firebase: $e");
    rethrow;
  }
}

void monitorConnectivity(StockStore store) {
  Connectivity()
      .onConnectivityChanged
      .listen((List<ConnectivityResult> results) {
    if (results != ConnectivityResult.none) {
      // Conexão voltou, sincroniza dados pendentes
      store.syncAllPendingData();
    }
  });
}

void main() async {
  await initializeDateFormatting('pt_BR', null);
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await initializeFirebase(); // Aguarde a inicialização dos bancos de dados

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ComandaStore>(create: (_) => ComandaStore()),
        Provider<SaborStore>(create: (_) => SaborStore()),
        Provider<StockStore>(create: (_) => StockStore()),
        Provider<VendasStore>(create: (_) => VendasStore()),
        ChangeNotifierProvider<DespesasStore>(create: (_) => DespesasStore()),
      ],
      child: MaterialApp(
        title: 'Orama Admin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            colorScheme: const ColorScheme.light(
                primary: Color(0xFF00A676), brightness: Brightness.light)),
        routes: Routes.routes,
        initialRoute: RouteName.splash,
      ),
    );
  }
}
