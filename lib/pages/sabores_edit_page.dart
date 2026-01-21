import 'package:flutter/material.dart';
import 'package:orama_admin/others/sabores.dart';
import 'package:orama_admin/routes/routes.dart';
import 'package:orama_admin/stores/comanda_store.dart';
import 'package:orama_admin/utils/scroll_hide_fab.dart';
import 'package:orama_admin/widgets/sabor_tile_admin.dart';
import 'package:orama_admin/widgets/sabor_tile_edit.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:mobx/mobx.dart';

class SaboresEditPage extends StatefulWidget {
  final Comanda comanda;

  SaboresEditPage({required this.comanda});

  @override
  _SaboresEditPageState createState() => _SaboresEditPageState();
}

class _SaboresEditPageState extends State<SaboresEditPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: sabores.keys.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
    final tabViewState = Provider.of<SaborStore>(context, listen: false);
    _tabController.index = tabViewState.currentIndex;
    _scrollController = ScrollController();

    // Preencher sabores selecionados a partir da comanda atual
    tabViewState.saboresSelecionados =
        ObservableMap<String, ObservableMap<String, Map<String, int>>>.of(
            widget.comanda.sabores.map((key, value) => MapEntry(
                key, ObservableMap<String, Map<String, int>>.of(value))));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    Provider.of<SaborStore>(context, listen: false)
        .setCurrentIndex(_tabController.index);
  }

  @override
  Widget build(BuildContext context) {
    final comandaStore = Provider.of<ComandaStore>(context);
    final tabViewState = Provider.of<SaborStore>(context);

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("Editar Sabores - ${widget.comanda.pdv}",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        elevation: 4,
        backgroundColor: const Color(0xff60C03D),
        scrolledUnderElevation: 0,
        bottom: TabBar(
          labelColor: Colors.white,
          indicatorColor: Colors.amber,
          controller: _tabController,
          tabs: sabores.keys.map((String key) {
            return Tab(text: key);
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: sabores.keys.map((String key) {
          final sortedSabores = List.from(sabores[key]!)
            ..sort((a, b) => a.compareTo(b));
          return ListView(
            controller: _scrollController,
            children: sortedSabores.map((sabor) {
              return SaborTileEdit(
                sabor: sabor,
                categoria: key,
              );
            }).toList(),
          );
        }).toList(),
      ),
      floatingActionButton: ScrollHideFab(
        scrollController: _scrollController,
        child: FloatingActionButton(
          backgroundColor: const Color(0xff60C03D),
          child: Icon(
            Icons.check,
            color: Colors.white,
          ),
          onPressed: () {
            // Atualizar sabores na comanda
            widget.comanda.sabores = tabViewState.saboresSelecionados.map(
                (key, value) => MapEntry(
                    key,
                    Map<String, Map<String, int>>.from(value.map(
                        (saborKey, saborValue) => MapEntry(
                            saborKey, Map<String, int>.from(saborValue))))));

            // Salvar comanda atualizada
            comandaStore.addOrUpdateCard(widget.comanda);

            // Resetar o estado do SaborStore
            tabViewState.resetExpansionState();
            tabViewState.resetSaborTabView();

            // Navegar de volta para estoque_admin_page
            Navigator.pushReplacementNamed(
                context, RouteName.estoque_admin_page);
          },
        ),
      ),
    );
  }
}
