import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:orama_admin/others/constants.dart';
import 'package:orama_admin/pages/estoque_page.dart';
import 'package:orama_admin/pages/loja/gerenciamento/estoqueActions_page.dart';
import 'package:orama_admin/pages/relatorios_descartaveis_page.dart';
import 'package:orama_admin/pages/relatorios_sorvete_page.dart';
import 'package:orama_admin/pages/sabores_admin_page.dart';
import 'package:orama_admin/routes/routes.dart';
import 'package:orama_admin/services/update_service.dart';
import 'package:orama_admin/utils/exit_dialog_utils.dart';
import 'package:orama_admin/utils/show_update_dialogs_util.dart';
import 'package:orama_admin/widgets/BottomNavigationBar.dart';
import 'package:orama_admin/widgets/my_styles/my_menu.dart';

class AdminPage extends StatefulWidget {
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _currentIndex = 0;

  void _navigateToPage(int index) {
    switch (index) {
      case 1:
        _replaceWith(EstoqueAdminPage());
        break;
      case 2:
        _replaceWith(RelatoriosSorvetePage());
        break;
      case 3:
        _replaceWith(RelatoriosDescartaveisPage());
        break;
      default:
        setState(() => _currentIndex = index);
    }
  }

  void _replaceWith(Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
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
  void initState() {
    super.initState();
    _checkAndShowUpdate();
  }

   Future<void> _checkAndShowUpdate() async {
    final update = await UpdateService.checkForUpdate();
    if (!mounted || update == null) return;

    UpdateDialog.show(
      context: context,
      title: "${update.title} ${update.version}",
      message: update.message,
      apkUrl: update.apkUrl,
      color: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        final bool shouldPop = await DialogUtils.showConfirmationDialog(
              context: context,
              title: 'Confirmação de Saída',
              content: 'Você deseja cancelar?',
              confirmText: 'Sim',
              cancelText: 'Não',
              onConfirm: () {
                Navigator.pop(context);
              },
            ) ??
            false;
      },
      child: Scaffold(
        bottomNavigationBar: CustomBottomNavigationBar(
          currentIndex: _currentIndex,
          onTabTapped: _navigateToPage,
        ),
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          title: Text("Orama Controle",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          elevation: 4,
          backgroundColor: const Color(0xff60C03D),
          scrolledUnderElevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed(RouteName.login);
              },
            ),
          ],
        ),
        drawer: Menu(),
        body: _currentIndex == 0 ? EstoqueActionsPage() : SizedBox.shrink(),
      ),
    );
  }
}

class PDVPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Selecione o PDV',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xff60C03D),
      ),
      body: GridView.builder(
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
      ),
    );
  }
}
