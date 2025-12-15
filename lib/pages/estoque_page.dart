import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_storage/get_storage.dart';
import 'package:orama_admin/pages/admin_page.dart';
import 'package:orama_admin/pages/relatorios_descartaveis_page.dart';
import 'package:orama_admin/pages/relatorios_sorvete_page.dart';
import 'package:orama_admin/stores/comanda_store.dart';
import 'package:orama_admin/utils/exit_dialog_utils.dart';
import 'package:orama_admin/widgets/BottomNavigationBar.dart';
import 'package:orama_admin/widgets/cards/comanda_card.dart';
import 'package:orama_admin/widgets/date_picker_widget.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class EstoqueAdminPage extends StatefulWidget {
  @override
  _EstoquePageState createState() => _EstoquePageState();
}

class _EstoquePageState extends State<EstoqueAdminPage> {
  List<bool> _selectedComandas = [];
  int _currentIndex = 1;
  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    final comandaStore = Provider.of<ComandaStore>(context, listen: false);
    comandaStore.syncWithFirebaseChanges();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final comandaStore = Provider.of<ComandaStore>(context, listen: false);
      setState(() {
        _selectedComandas = List.filled(comandaStore.comandas.length, false);
      });
    });
  }

  void onTabTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminPage()),
      );
    } else if (index == 1) {
      setState(() {
        _currentIndex = index;
      });
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RelatoriosSorvetePage()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RelatoriosDescartaveisPage()),
      );
    }
  }

  void _updateSelectedDate(ComandaStore comandaStore, DateTime newDate) {
    comandaStore.setSelectedDate(newDate);
  }

  Future<void> _refreshComandas(BuildContext context) async {
    final comandaStore = Provider.of<ComandaStore>(context, listen: false);
    await comandaStore.syncWithFirebaseChanges();
  }

  @override
  Widget build(BuildContext context) {
    final comandaStore = Provider.of<ComandaStore>(context);

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
          onTabTapped: onTabTapped,
        ),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          iconTheme: IconThemeData(color: Colors.white),
          title: Text("Estoque",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          elevation: 4,
          backgroundColor: const Color(0xff60C03D),
        ),
        body: Column(
          children: [
            Observer(
              builder: (_) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        _updateSelectedDate(
                            comandaStore,
                            comandaStore.selectedDate
                                .subtract(Duration(days: 1)));
                      },
                    ),
                    DatePickerWidget(
                      key: UniqueKey(),
                      initialDate: comandaStore.selectedDate,
                      onDateSelected: (newDate) {
                        comandaStore.setSelectedDate(newDate);
                      },
                      dateFormat: DateFormat('dd MMMM yyyy', 'pt_BR'),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {
                        _updateSelectedDate(comandaStore,
                            comandaStore.selectedDate.add(Duration(days: 1)));
                      },
                    ),
                  ],
                );
              },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _refreshComandas(context),
                child: Observer(
                  builder: (_) {
                    final comandasPorDia = <String, List<Comanda>>{};

                    for (var comanda in comandaStore
                        .getComandasForSelectedDay(comandaStore.selectedDate)) {
                      final dia = DateFormat('dd/MM/yyyy', 'pt_BR')
                          .format(comanda.data);
                      if (!comandasPorDia.containsKey(dia)) {
                        comandasPorDia[dia] = [];
                      }
                      comandasPorDia[dia]!.add(comanda);
                    }

                    if (_selectedComandas.length !=
                        comandaStore.comandas.length) {
                      _selectedComandas =
                          List.filled(comandaStore.comandas.length, false);
                    }

                    if (comandasPorDia.isEmpty) {
                      return const SizedBox.expand(
                        child: Center(
                          child: Text(
                            "Não há Relatório do período selecionado.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16
                            , color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    return ListView(
                      children: comandasPorDia.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ...entry.value.map((comanda) {
                              final index =
                                  comandaStore.comandas.indexOf(comanda);
                              return StatefulBuilder(
                                  builder: (context, setState) {
                                return ComandaCard(
                                  comanda: comanda,
                                  isSelected: _selectedComandas[index],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedComandas[index] = value!;
                                    });
                                  },
                                  isExpanded: comandaStore
                                      .getExpansionState(comanda.id),
                                  onExpansionChanged: (isExpanded) {
                                    comandaStore.setExpansionState(
                                        comanda.id, isExpanded);
                                  },
                                );
                              });
                            }).toList(),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
