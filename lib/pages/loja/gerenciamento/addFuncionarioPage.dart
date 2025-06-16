import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:orama_admin/main.dart'; // expõe secondaryAuth e secondaryFirestore
import 'package:orama_admin/pages/loja/gerenciamento/removerUsuarioPage.dart';
import 'package:orama_admin/utils/show_snackbar.dart';

class AddFuncionarioPage extends StatefulWidget {
  const AddFuncionarioPage({super.key});

  @override
  State<AddFuncionarioPage> createState() => _AddFuncionarioPageState();
}

class _AddFuncionarioPageState extends State<AddFuncionarioPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();

  /// Mesmo padrão visual dos botões de salvar/remover
  bool isLoading = false;

  /// Senha padrão para novos atendentes
  static const String _defaultPassword = 'atendentes123';

  /// Referências do segundo app (admin)
  final FirebaseFirestore firestore = primaryFirestore;
  final auth = FirebaseAuth.instance;

  /* ------------------------------------------------------------------ */
  Future<void> _criarFuncionario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // 1. Cria usuário no Firebase Authentication
      final UserCredential cred = await auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: _defaultPassword,
      );

      // 2. Grava documento em "users/{uid}"
      await firestore.collection('users').doc(cred.user!.uid).set({
        'email': emailController.text.trim(),
        'role': 'user',
      });

      ShowSnackBar(
          context, 'Funcionário criado com sucesso!', const Color(0xff60C03D));
      Navigator.pop(context); // fecha página
    } on FirebaseAuthException catch (e) {
      String msg = switch (e.code) {
        'email-already-in-use' => 'E-mail já está em uso.',
        'invalid-email' => 'E-mail inválido.',
        _ => 'Erro: ${e.code}',
      };
      ShowSnackBar(context, msg, Colors.red);
    } catch (e) {
      ShowSnackBar(context, 'Erro inesperado: $e', Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
  /* ------------------------------------------------------------------ */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          'Adicionar Funcionário',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xff60C03D),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail do funcionário',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Informe um e-mail'
                    : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon:
                    const Icon(Icons.person_add, color: Colors.white, size: 18),
                label: const Text(
                  'Cadastrar',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff60C03D),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: isLoading ? null : _criarFuncionario,
              ),
              // const SizedBox(height: 22),
              // ElevatedButton.icon(
              //   label: const Text(
              //     'Remover Usuário cadastrado',
              //     style: TextStyle(color: Colors.white),
              //   ),
              //   onPressed: () => Navigator.push(
              //     context,
              //     MaterialPageRoute(builder: (_) => RemoveUsuarioPage()),
              //   ),
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.red,
              //     padding: const EdgeInsets.symmetric(vertical: 14),
              //   ),
              // ),
              const SizedBox(height: 8),
              Text(
                'Senha do usuario: $_defaultPassword\n',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
