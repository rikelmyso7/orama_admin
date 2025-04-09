import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:orama_admin/routes/routes.dart';
import 'package:orama_admin/stores/comanda_store.dart';
import 'package:orama_admin/stores/stock_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_api_availability/google_api_availability.dart';

// Variáveis globais para os bancos de dados
late FirebaseFirestore primaryFirestore;
late FirebaseFirestore secondaryFirestore;

Future<void> initializeFirebase() async {
  try {
    // Inicialize o primeiro banco de dados (banco de dados padrão)
    final FirebaseApp primaryApp = await Firebase.initializeApp();

    // Inicialize o segundo banco de dados (usando as informações do JSON fornecido)
    final FirebaseApp secondaryApp = await Firebase.initializeApp(
      name: 'SecondaryApp',
      options: const FirebaseOptions(
        apiKey: 'AIzaSyA2kcPMyudjkGohevS98HXR4RdB1uIdNfY',
        appId: '1:681609262580:android:502d5ba58414b4cde075a1',
        messagingSenderId: '681609262580',
        projectId: 'oramaloja',
        storageBucket: 'oramaloja.firebasestorage.app',
      ),
    );

    // Instâncias do Firestore para cada banco de dados
    primaryFirestore = FirebaseFirestore.instanceFor(app: primaryApp);
    secondaryFirestore = FirebaseFirestore.instanceFor(app: secondaryApp);

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
      ],
      child: MaterialApp(
        title: 'Flutter Firebase Auth',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        routes: Routes.routes,
        initialRoute: RouteName.splash,
      ),
    );
  }
}
