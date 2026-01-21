import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:orama_admin/routes/routes.dart';

class Menu extends StatelessWidget {
  const Menu({super.key});

  static const Map<String, String> _storeMap = {
    "h0g6nwqiRKcM3VSFk6Wu4JFWe9k2": "Orama Paineiras",
    "gwYkGevTSZUuGpMQsKLQSlFHZpm2": "Orama Itupeva",
    "VNlSNV0SKEOACk9Cxcxwe4E2Rtm2": "Orama Retiro",
  };

  String get _storeName {
    final userId = GetStorage().read('userId');
    return _storeMap[userId] ?? "Admin";
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 100,
            child: DrawerHeader(
              padding: const EdgeInsets.all(0),
              decoration: const BoxDecoration(color: Color(0xff60C03D)),
              child: Row(
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 26),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    _storeName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 26,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildMenuItem(
            context,
            label: 'Relatórios',
            icon: FontAwesomeIcons.folderOpen,
            routeName: RouteName.relatorios,
          ),
          const Divider(),
          _buildMenuItem(
            context,
            label: 'Reposições',
            icon: Icons.add_business_outlined,
            routeName: RouteName.reposicao,
          ),
          const Divider(),
          _buildMenuItem(
            context,
            label: 'Fábrica',
            icon: FontAwesomeIcons.industry,
            routeName: RouteName.fabrica,
          ),
          const Divider(),
          _buildMenuItem(
            context,
            label: 'Tela Inicial',
            icon: Icons.home_outlined,
            routeName: RouteName.admin_page,
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String routeName,
  }) {
    return ListTile(
      // Se preferir o ícone à direita do texto (como no original),
      // troque 'leading' por um Row no 'title' ou use 'trailing'.
      // Padrão Material Drawer é 'leading'.
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
          ),
          const SizedBox(width: 8),
          Icon(icon,
              size: 20, color: Colors.black87), // Ajuste cor se necessário
        ],
      ),
      onTap: () => Navigator.of(context).pushNamed(routeName),
    );
  }
}
