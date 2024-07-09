import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:orama_admin/pages/sabores_admin_page.dart';
import 'package:orama_admin/routes/routes.dart';
import 'package:orama_admin/utils/exit_dialog_utils.dart';
import 'package:orama_admin/widgets/BottomNavigationBar.dart';

class AdminPage extends StatefulWidget {
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final List<String> pdvs = [
    'Pesqueiro',
    'Brunholli',
    'Michelleto',
    'Travitália',
    'Da Roça',
    'Bendito',
    'Marquezim',
    'Vibe',
    'Sassafraz',
    'Fontebasso',
  ];
  int _currentIndex = 0;

  void onTabTapped(int index) {
    if (index == 1) {
      Navigator.pushReplacementNamed(context, RouteName.estoque_admin_page);
    }
    if (index == 2) {
      Navigator.pushReplacementNamed(context, RouteName.relatorios_admin_page);
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }
        final bool shouldPop =
            await DialogUtils.showBackDialog(context) ?? false;
        if (context.mounted && shouldPop) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        bottomNavigationBar: CustomBottomNavigationBar(
          currentIndex: _currentIndex,
          onTabTapped: onTabTapped,
        ),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          iconTheme: IconThemeData(color: Colors.white),
          title: Text("Orama Controle",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          elevation: 4,
          backgroundColor: const Color(0xff60C03D),
          scrolledUnderElevation: 0,
        ),
        body: _currentIndex == 0 ? PDVPage() : SizedBox.shrink(),
      ),
    );
  }
}

class PDVPage extends StatelessWidget {
  final List<String> pdvs = [
    'Pesqueiro',
    'Brunholli',
    'Michelleto',
    'Travitália',
    'Da Roça',
    'Bendito',
    'Marquezim',
    'Vibe',
    'Sassafraz',
    'Fontebasso',
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemCount: pdvs.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(5.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SaboresAdminPage(pdv: pdvs[index]),
                ),
              );
            },
            child: Card(
              elevation: 1,
              child: Center(
                child: Text(
                  pdvs[index],
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}