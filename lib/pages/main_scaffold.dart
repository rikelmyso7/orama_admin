import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:orama_admin/pages/estoque_page.dart';
import 'package:orama_admin/pages/loja/gerenciamento/estoqueActions_page.dart';
import 'package:orama_admin/pages/relatorios_descartaveis_page.dart';
import 'package:orama_admin/pages/relatorios_sorvete_page.dart';
import 'package:orama_admin/routes/routes.dart';
import 'package:orama_admin/services/update_service.dart';
import 'package:orama_admin/utils/exit_dialog_utils.dart';
import 'package:orama_admin/utils/show_update_dialogs_util.dart';
import 'package:orama_admin/widgets/BottomNavigationBar.dart';
import 'package:orama_admin/widgets/my_styles/my_menu.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;

  const MainScaffold({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      const EstoqueActionsPage(),
      EstoqueAdminPage(),
      RelatoriosSorvetePage(),
      RelatoriosDescartaveisPage(),
    ];
    _checkAndShowUpdate();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return "Orama Controle";
      case 1:
        return "Estoque";
      case 2:
        return "Relatórios Sorvete";
      case 3:
        return "Relatórios Descartáveis";
      default:
        return "Orama Controle";
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        await DialogUtils.showConfirmationDialog(
          context: context,
          title: 'Confirmação de Saída',
          content: 'Você deseja cancelar?',
          confirmText: 'Sim',
          cancelText: 'Não',
          onConfirm: () {
            Navigator.pop(context);
          },
        );
      },
      child: Scaffold(
        drawer: _currentIndex == 0 ? const Menu() : null,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          automaticallyImplyLeading: _currentIndex == 0,
          title: Text(
            _getAppBarTitle(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          elevation: 4,
          backgroundColor: const Color(0xff60C03D),
          scrolledUnderElevation: 0,
          actions: _currentIndex == 0
              ? [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushReplacementNamed(RouteName.login);
                    },
                  ),
                ]
              : null,
        ),
        bottomNavigationBar: CustomBottomNavigationBar(
          currentIndex: _currentIndex,
          onTabTapped: _onTabTapped,
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
    );
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
}
