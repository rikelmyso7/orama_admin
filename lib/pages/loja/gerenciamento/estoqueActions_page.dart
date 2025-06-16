import 'package:flutter/material.dart';
import 'package:orama_admin/pages/admin_page.dart';
import 'package:orama_admin/pages/loja/gerenciamento/addFuncionarioPage.dart';
import 'package:orama_admin/pages/loja/gerenciamento/addItemEstoquePage.dart';
import 'package:orama_admin/pages/loja/gerenciamento/addLocalPage.dart';

class EstoqueActionsPage extends StatelessWidget {
  const EstoqueActionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCard(
                context,
                title: 'Adicionar item ao estoque',
                icon: Icons.post_add_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddItemEstoquePage()),
                ),
              ),
              const SizedBox(height: 20),
              _buildCard(
                context,
                title: 'Adicionar funcionário PDV',
                icon: Icons.person_add,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddFuncionarioPage()),
                ),
              ),
              const SizedBox(height: 20),
              _buildCard(
                context,
                title: 'Criar reposição para PDV',
                icon: Icons.local_shipping,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PDVPage()),
                ),
              ),
              const SizedBox(height: 20),
              _buildCard(
                context,
                title: 'Adicionar nova Loja',
                icon: Icons.add_business_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddLojaPage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context,
      {required String title,
      required IconData icon,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 32.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: const Color(0xff60C03D)),
              const SizedBox(width: 16),
              Flexible(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
