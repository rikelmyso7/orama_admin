import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orama_admin/others/sabores.dart';
import 'package:orama_admin/routes/routes.dart';
import 'package:orama_admin/stores/comanda_store.dart';
import 'package:orama_admin/utils/scroll_hide_fab.dart';
import 'package:orama_admin/widgets/sabor_tile_admin.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class SaboresAdminPage extends StatefulWidget {
  final String pdv;

  SaboresAdminPage({required this.pdv});

  @override
  _SaboresPageState createState() => _SaboresPageState();
}

class _SaboresPageState extends State<SaboresAdminPage>
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
    final dataFormat = DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());
    final comandaId = '${dataFormat} - ${widget.pdv}';

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("Sabores - ${widget.pdv}",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        elevation: 4,
        backgroundColor: const Color(0xff60C03D),
        scrolledUnderElevation: 0,
        bottom: TabBar(
          labelColor: Colors.white,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          controller: _tabController,
          isScrollable: true,
          labelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.normal,
          ),
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
              return SaborTile(
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
            comandaStore.addOrUpdateCard(
              Comanda(
                  pdv: widget.pdv,
                  sabores: tabViewState.saboresSelecionados.map((key, value) =>
                      MapEntry(key, Map<String, Map<String, int>>.from(value))),
                  data: DateTime.now(),
                  id: comandaId,
                  name: '',
                  userId: ''),
            );
            tabViewState.resetExpansionState();
            tabViewState.resetSaborTabView();
            Navigator.pushReplacementNamed(
                context, RouteName.estoque_admin_page);
          },
        ),
      ),
    );
  }
}
