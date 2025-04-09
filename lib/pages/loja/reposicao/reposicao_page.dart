import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:orama_admin/pages/loja/reposicao/DataReposicaoView.dart';
import 'package:orama_admin/pages/loja/reposicao/add_reposicao_info.dart';
import 'package:orama_admin/pages/loja/editarRelatorio_page.dart';
import 'package:orama_admin/pages/loja/relatorios_page.dart';
import 'package:orama_admin/pages/loja/reposicao/copiar_reposicao_page.dart';
import 'package:orama_admin/pages/loja/reposicao/editar_reposicao_page.dart';
import 'package:orama_admin/routes/routes.dart';
import 'package:orama_admin/stores/stock_store.dart';
import 'package:orama_admin/utils/exit_dialog_utils.dart';
import 'package:orama_admin/utils/gerar_excel.dart';
import 'package:orama_admin/utils/gerar_romaneio.dart';
import 'package:orama_admin/widgets/my_styles/my_drawer.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class ReposicaoPage extends StatefulWidget {
  @override
  _ReposicaoPageState createState() => _ReposicaoPageState();
}

class _ReposicaoPageState extends State<ReposicaoPage> {
  @override
  void initState() {
    super.initState();
    final store = Provider.of<StockStore>(context, listen: false);
    store.fetchReports();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StockStore>(context);

    return Observer(builder: (_) {
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
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: Icon(Icons.menu),
                  color: Colors.white,
                  onPressed: () {
                    Scaffold.of(context).openDrawer(); // Abre o menu hamburguer
                  },
                );
              },
            ),
            title: Text(
              "Ultimas Reposições",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xff60C03D),
          ),
          drawer: MyDrawer(
            title: 'Admin',
            menuItems: [
              DrawerMenuItem(
                label: 'Jundiaí',
                icon: Icons.post_add,
                onTap: () {
                  // _filterReportsByCity('Jundiaí');
                  Navigator.pop(context);
                },
              ),
              DrawerMenuItem(
                label: 'Itupeva',
                icon: Icons.post_add,
                onTap: () {
                  // _filterReportsByCity('Itupeva');
                  Navigator.pop(context);
                },
              ),
              DrawerMenuItem(
                label: 'Campinas',
                icon: Icons.post_add,
                onTap: () {
                  // _filterReportsByCity('Campinas');
                  Navigator.pop(context);
                },
              ),
              DrawerMenuItem(
                label: 'Relatórios',
                icon: Icons.create_new_folder_outlined,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => RelatoriosPage(
                              city: "Jundiaí",
                            )),
                  );
                },
              ),
              DrawerMenuItem(
                label: 'Fábrica',
                icon: Icons.add_home_work_outlined,
                onTap: () {
                  Navigator.of(context).pushNamed(RouteName.fabrica);
                },
              ),
              DrawerMenuItem(
                label: 'Tela Inicial',
                icon: Icons.home_outlined,
                onTap: () {
                  Navigator.of(context)
                      .pushReplacementNamed(RouteName.admin_page);
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => store.fetchReports(),
            child: Observer(
              builder: (_) {
                if (store.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (store.reports.isEmpty) {
                  return Center(child: Text("Nenhum relatório disponível"));
                }

                return ListView.builder(
                  itemCount: store.reports.length,
                  itemBuilder: (context, index) {
                    final sortedReports =
                        List<Map<String, dynamic>>.from(store.reports)
                          ..sort((a, b) {
                            final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
                            final dateA = a['Data'] != null
                                ? dateFormat.parse(a['Data'], true)
                                : DateTime(0);
                            final dateB = b['Data'] != null
                                ? dateFormat.parse(b['Data'], true)
                                : DateTime(0);
                            return dateB.compareTo(dateA); // Ordem decrescente
                          });

                    final report = sortedReports[index];
                    final date = report['Data'] ?? '';
                    final formattedDate = date.isNotEmpty
                        ? DateFormat('dd/MM/yy HH:MM')
                            .format(DateTime.tryParse(date) ?? DateTime.now())
                        : "Data não disponível";
                    final name = report['Nome do usuario'] ?? '';
                    final loja = report['Loja'] ?? '';
                    final city = report['Cidade'] ?? '';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DataReposicaoView(
                              report: report,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Reposição",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditarReposicaoPage(
                                                nome: name,
                                                data: date,
                                                loja: loja,
                                                city: city,
                                                reportData:
                                                    report, // Passa os dados do relatório
                                                reportId: report[
                                                    'ID'], // Pass the document ID for existing report
                                              ),
                                            ),
                                          );
                                        },
                                        child: Icon(
                                          Icons.edit,
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      IconButton(
                                        onPressed: () async {
                                          final message =
                                              store.formatReportForWhatsAppRepo(
                                                  report);
                                          await Share.share(message);
                                        },
                                        icon: FaIcon(FontAwesomeIcons.whatsapp),
                                      ),
                                      IconButton(
                                        onPressed: () async {
                                          try {
                                            final caminho =
                                                await gerarRomaneioPDF(
                                                    context, report);
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      "Erro ao compartilhar: $e")),
                                            );
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.share,
                                          size: 26,
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),
                              Text(
                                "$loja",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              Text("Responsável: $name",
                                  style: TextStyle(fontSize: 16)),
                              Text(
                                "Data: $date",
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xff60C03D),
            icon: Icon(
              Icons.add,
              color: Colors.white,
            ),
            label: Text(
              'Adicionar',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              store.clearRepoFields();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddReposicaoInfo(),
                ),
              );
            },
          ),
        ),
      );
    });
  }
}
