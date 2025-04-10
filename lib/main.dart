import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:orama_admin/routes/routes.dart';
import 'package:orama_admin/stores/comanda_store.dart';
import 'package:orama_admin/stores/stock_store.dart';
import 'package:provider/provider.dart';

void main() async {
  await initializeDateFormatting('pt_BR', null);
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  final FirebaseApp primaryApp = await Firebase.initializeApp();

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

                        