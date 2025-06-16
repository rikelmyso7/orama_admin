import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:orama_admin/main.dart';
import 'package:orama_admin/utils/show_snackbar.dart';

class RemoveItemEstoquePage extends StatefulWidget {
  const RemoveItemEstoquePage({super.key});

  @override
  State<RemoveItemEstoquePage> createState() => _RemoveItemEstoquePageState();
}

class _RemoveItemEstoquePageState extends State<RemoveItemEstoquePage>
    with TickerProviderStateMixin {
  final firestore = secondaryFirestore;
  String? lojaSelecionada;
  String? categoriaSelecionada;
  List<String> lojas = [];
  List<String> categorias = [];
  List<Map<String, dynamic>> itens = [];
  bool isLoadingLojas = true;
  bool isLoadingCategorias = false;
  bool isLoadingItens = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    carregarLojas();
  }

  Future<void> carregarLojas() async {
    setState(() => isLoadingLojas = true);
    try {
      final snapshot = await firestore.collection('configuracoes_loja').get();
      setState(() {
        lojas = snapshot.docs.map((doc) => doc.id).toList();
        isLoadingLojas = false;
      });
    } catch (e) {
      setState(() => isLoadingLojas = false);
      ShowSnackBar(context, 'Erro ao carregar lojas: $e', Colors.red);
    }
  }

  Future<void> carregarCategorias(String loja) async {
    setState(() => isLoadingCategorias = true);
    try {
      final doc =
          await firestore.collection('configuracoes_loja').doc(loja).get();
      if (doc.exists) {
        final data = doc.data();
        final insumos = data?['insumos'] as Map<String, dynamic>? ?? {};
        setState(() {
          categorias = insumos.keys.toList();
          itens = [];
          categoriaSelecionada = null;
          isLoadingCategorias = false;
        });
      }
    } catch (e) {
      setState(() => isLoadingCategorias = false);
      ShowSnackBar(context, 'Erro ao carregar categorias: $e', Colors.red);
    }
  }

  Future<void> carregarItens(String loja, String categoria) async {
    setState(() => isLoadingItens = true);
    try {
      final doc =
          await firestore.collection('configuracoes_loja').doc(loja).get();
      final insumos = doc.data()?['insumos'] ?? {};
      final lista = insumos[categoria];
      setState(() {
        itens = List<Map<String, dynamic>>.from(lista ?? []);
        isLoadingItens = false;
      });

      // Animar a lista quando carregar
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() => isLoadingItens = false);
      ShowSnackBar(context, 'Erro ao carregar itens: $e', Colors.red);
    }
  }

  Future<void> removerItem(
      String loja, String categoria, Map<String, dynamic> item) async {
    try {
      await firestore.collection('configuracoes_loja').doc(loja).update({
        'insumos.$categoria': FieldValue.arrayRemove([item])
      });
      ShowSnackBar(context, 'Item removido com sucesso!', Colors.red);

      // Reset animations
      _fadeController.reset();
      _slideController.reset();

      await carregarItens(loja, categoria);
    } catch (e) {
      ShowSnackBar(context, 'Erro ao remover item: $e', Colors.red);
    }
  }

  Widget _buildDropdownContainer({
    required Widget child,
    required IconData icon,
    required String label,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xff60C03D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xff60C03D),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: child),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xff60C03D),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Remover Item do Estoque",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xff60C03D),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.remove_shopping_cart,
                        color: Colors.red[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Remover Item',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2D3748),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecione a loja e categoria para gerenciar os itens do estoque',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                // Dropdown Loja
                _buildDropdownContainer(
                  icon: Icons.store,
                  label: 'Loja',
                  isLoading: isLoadingLojas,
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Selecione a Loja',
                      border: InputBorder.none,
                      labelStyle: TextStyle(color: Color(0xff718096)),
                    ),
                    value: lojaSelecionada,
                    items: lojas
                        .map((loja) => DropdownMenuItem(
                              value: loja,
                              child: Text(
                                loja,
                                style: const TextStyle(
                                  color: Color(0xff2D3748),
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: isLoadingLojas
                        ? null
                        : (value) {
                            setState(() {
                              lojaSelecionada = value;
                              categoriaSelecionada = null;
                              itens = [];
                            });
                            if (value != null) carregarCategorias(value);
                          },
                  ),
                ),

                const SizedBox(height: 16),

                // Dropdown Categoria
                _buildDropdownContainer(
                  icon: Icons.category,
                  label: 'Categoria',
                  isLoading: isLoadingCategorias,
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Selecione a Categoria',
                      border: InputBorder.none,
                      labelStyle: TextStyle(color: Color(0xff718096)),
                    ),
                    value: categoriaSelecionada,
                    items: categorias
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(
                                cat,
                                style: const TextStyle(
                                  color: Color(0xff2D3748),
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (lojaSelecionada == null || isLoadingCategorias)
                        ? null
                        : (value) {
                            setState(() {
                              categoriaSelecionada = value;
                            });
                            if (value != null && lojaSelecionada != null) {
                              // Reset animations
                              _fadeController.reset();
                              _slideController.reset();
                              carregarItens(lojaSelecionada!, value);
                            }
                          },
                  ),
                ),
              ],
            ),

            // Lista de itens
            if (categoriaSelecionada != null) ...[
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
                            color: const Color(0xff60C03D).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.inventory,
                            color: Color(0xff60C03D),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Itens do Estoque (${itens.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2D3748),
                          ),
                        ),
                        if (isLoadingItens) ...[
                          const SizedBox(width: 12),
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xff60C03D),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (isLoadingItens)
                      Container(
                        padding: const EdgeInsets.all(40),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xff60C03D),
                          ),
                        ),
                      )
                    else if (itens.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 48,
                                color: Color(0xff718096),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Nenhum item encontrado',
                                style: TextStyle(
                                  color: Color(0xff718096),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            children: itens.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;

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
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(12),
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
                                              Icons.inventory_2,
                                              color: Color(0xff60C03D),
                                              size: 24,
                                            ),
                                          ),
                                          title: Text(
                                            item['nome'] ?? 'Sem nome',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xff2D3748),
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      item['tipo'] ?? 'N/A',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.blue,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Mín: ${item['minimo'] ?? 'N/A'}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xff718096),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          trailing: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.red.withOpacity(0.1),
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
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                    ),
                                                    title: Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .warning_amber_rounded,
                                                          color: Colors
                                                              .orange[600],
                                                          size: 24,
                                                        ),
                                                        const SizedBox(
                                                            width: 12),
                                                        const Text(
                                                          'Confirmar remoção',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    content: Text(
                                                      'Deseja remover "${item['nome']}" do estoque?\n\nEsta ação não pode ser desfeita.',
                                                      style: const TextStyle(
                                                          fontSize: 16),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, false),
                                                        child: const Text(
                                                          'Cancelar',
                                                          style: TextStyle(
                                                            color: Color(
                                                                0xff718096),
                                                          ),
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, true),
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          'Remover',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  await removerItem(
                                                    lojaSelecionada!,
                                                    categoriaSelecionada!,
                                                    item,
                                                  );
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
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
