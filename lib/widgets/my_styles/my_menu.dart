import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:orama_admin/routes/routes.dart';

class Menu extends StatelessWidget {
  const Menu({
    super.key,
  });

  String getStoreName() {
    final userId = GetStorage().read('userId');
    switch (userId) {
      case "h0g6nwqiRKcM3VSFk6Wu4JFWe9k2":
        return "Orama Paineiras";
      case "gwYkGevTSZUuGpMQsKLQSlFHZpm2":
        return "Orama Itupeva";
      case "VNlSNV0SKEOACk9Cxcxwe4E2Rtm2":
        return "Orama Retiro";
      default:
        return "Loja";
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeName = getStoreName();

    return Drawer(
      child: _buildMenuContent(context, 'Admin'),
    );
  }

  Widget _buildMenuContent(BuildContext context, String storeName) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          height: 100,
          child: DrawerHeader(
            decoration: BoxDecoration(
              color: const Color(0xff60C03D),
            ),
            child: Text(
              storeName,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 26),
            ),
          ),
        ),
        ListTile(
          title: Row(
            children: [
              Text(
                'Relatórios',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
              ),
              SizedBox(width: 5),
              FaIcon(
                FontAwesomeIcons.folderOpen,
                size: 20,
              ),
            ],
          ),
          onTap: () {
            Navigator.of(context).pushNamed(RouteName.relatorios);
          },
        ),
        Divider(),
        ListTile(
            title: const Align(
                alignment: Alignment.bottomLeft,
                child: Row(
                  children: [
                    Text(
                      'Reposições',
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Icon(Icons.add_business_outlined)
                  ],
                )),
            onTap: () async {
              Navigator.of(context).pushNamed(RouteName.reposicao);
            }),
        Divider(),
        ListTile(
            title: const Align(
                alignment: Alignment.bottomLeft,
                child: Row(
                  children: [
                    Text(
                      'Fábrica',
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    FaIcon(
                      FontAwesomeIcons.industry,
                      size: 20,
                    )
                  ],
                )),
            onTap: () async {
              Navigator.of(context).pushNamed(RouteName.fabrica);
            }),
        Divider(),
        ListTile(
            title: const Align(
                alignment: Alignment.bottomLeft,
                child: Row(
                  children: [
                    Text(
                      'Tela Inicial',
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Icon(Icons.home_outlined)
                  ],
                )),
            onTap: () async {
              Navigator.of(context).pushNamed(RouteName.admin_page);
            }),
        Divider(),
      ],
    );
  }
}
