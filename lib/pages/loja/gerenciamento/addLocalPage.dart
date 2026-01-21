import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:orama_admin/main.dart';
import 'package:orama_admin/utils/show_snackbar.dart';

class AddLojaPage extends StatefulWidget {
  const AddLojaPage({super.key});

  @override
  State<AddLojaPage> createState() => _AddLojaPageState();
}

class _AddLojaPageState extends State<AddLojaPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController cidadeController = TextEditingController();
  bool isLoading = false;
  final firestore = secondaryFirestore;
  bool mostrarLojas = false;

  late AnimationController _slideController;
  late AnimationController _rotationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _rotationAnimation;

  /// Gera o ID do documento baseado no nome, em minúsculas e com "_" no lugar de espaços.
  String gerarIdDocumento(String nome) {
    return nome.trim().toLowerCase().replaceAll(' ', '_');
  }

  List<Map<String, dynamic>> lojas = [];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    );
    _rotationAnimation = CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    );

    carregarLojas();
  }

  Future<void> carregarLojas() async {
    final snapshot = await firestore.collection('lojas').get();
    setState(() {
      lojas = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'nome': data['nome'],
          'cidade': data['cidade'],
        };
      }).toList();
    });
  }

  Future<void> adicionarNovaLoja() async {
    final String nome = nomeController.text.trim();
    final String cidade = cidadeController.text.trim();
    final String docId = gerarIdDocumento(nome);

    if (nome.isEmpty || cidade.isEmpty) return;

    setState(() => isLoading = true);

    try {
      await firestore.collection('lojas').doc(docId).set({
        'nome': nome,
        'cidade': cidade,
      });

      ShowSnackBar(
          context, 'Loja adicionada com sucesso!', const Color(0xff60C03D));

      // Limpar campos após sucesso
      nomeController.clear();
      cidadeController.clear();

      // Atualizar lista
      await carregarLojas();
    } catch (e) {
      ShowSnackBar(context, 'Erro ao adicionar loja: $e', Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> removerLoja(String docId) async {
    try {
      await firestore.collection('lojas').doc(docId).delete();
      ShowSnackBar(context, 'Loja removida com sucesso!', Colors.red);
      await carregarLojas();
    } catch (e) {
      ShowSnackBar(context, 'Erro ao remover loja: $e', Colors.red);
    }
  }

  void _toggleMostrarLojas() {
    setState(() {
      mostrarLojas = !mostrarLojas;
    });

    if (mostrarLojas) {
      _slideController.forward();
      _rotationController.forward();
    } else {
      _slideController.reverse();
      _rotationController.reverse();
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    cidadeController.dispose();
    _slideController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Gerenciar Lojas",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xff60C03D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card principal para adicionar loja
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xff60C03D).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.store,
                          color: Color(0xff60C03D),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Adicionar Loja',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2D3748),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Campo Nome
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: TextFormField(
                      controller: nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome da Loja',
                        prefixIcon:
                            Icon(Icons.business, color: Color(0xff60C03D)),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        labelStyle: TextStyle(color: Color(0xff718096)),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Informe o nome'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Campo Cidade
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: TextFormField(
                      controller: cidadeController,
                      decoration: const InputDecoration(
                        labelText: 'Cidade',
                        prefixIcon:
                            Icon(Icons.location_city, color: Color(0xff60C03D)),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        labelStyle: TextStyle(color: Color(0xff718096)),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Informe a cidade'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botão Adicionar
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff60C03D), Color(0xff4FA832)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff60C03D).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add, color: Colors.white),
                      label: Text(
                        isLoading ? 'Adicionando...' : 'Adicionar Loja',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                adicionarNovaLoja();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botão para mostrar/esconder lojas com animação
            AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    icon: Transform.rotate(
                      angle: _rotationAnimation.value * 3.14159,
                      child: const Icon(
                        Icons.expand_more,
                        color: Colors.red,
                      ),
                    ),
                    label: Text(
                      mostrarLojas ? 'Ocultar Lojas' : 'Gerenciar Lojas',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: _toggleMostrarLojas,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Lista de lojas com animação
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: _slideAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.store_mall_directory,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Lojas Cadastradas (${lojas.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff2D3748),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (lojas.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'Nenhuma loja cadastrada ainda',
                                style: TextStyle(
                                  color: Color(0xff718096),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                        else
                          ...lojas.asMap().entries.map((entry) {
                            final index = entry.key;
                            final loja = entry.value;
                            return TweenAnimationBuilder(
                              duration:
                                  Duration(milliseconds: 200 + (index * 100)),
                              tween: Tween<double>(begin: 0, end: 1),
                              builder: (context, double value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.withOpacity(0.2),
                                        ),
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xff60C03D)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.store,
                                            color: Color(0xff60C03D),
                                            size: 20,
                                          ),
                                        ),
                                        title: Text(
                                          loja['nome'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xff2D3748),
                                          ),
                                        ),
                                        subtitle: Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 14,
                                              color: Color(0xff718096),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              loja['cidade'],
                                              style: const TextStyle(
                                                color: Color(0xff718096),
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            onPressed: () async {
                                              final confirm =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text(
                                                      'Confirmar remoção'),
                                                  content: Text(
                                                      'Deseja remover "${loja['nome']}"?'),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, false),
                                                        child: const Text(
                                                            'Cancelar')),
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, true),
                                                        child: const Text(
                                                            'Remover')),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true) {
                                                await removerLoja(loja['id']);
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
