import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:orama_admin/others/field_validators.dart';
import 'package:orama_admin/pages/loja/reposicao/reposicao_formulario.dart';
import 'package:orama_admin/stores/stock_store.dart';
import 'package:orama_admin/widgets/my_styles/my_button.dart';
import 'package:orama_admin/widgets/my_styles/my_textfield.dart';
import 'package:orama_admin/widgets/my_styles/my_dropdown.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AddReposicaoInfo extends StatefulWidget {
  @override
  _AddReposicaoInfoState createState() => _AddReposicaoInfoState();
}

class _AddReposicaoInfoState extends State<AddReposicaoInfo> {
  final TextEditingController _nameController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final ValueNotifier<bool> isFormValid = ValueNotifier<bool>(false);

  // Dados das cidades e lojas
  final Map<String, List<String>> cityStores = {
    "Jundiaí": ["Orama Paineiras", "Orama Retiro"],
    "Itupeva": ["Orama Itupeva"],
    "Campinas": ["Platz", "Bar da Cachoeira"],
  };

  String? selectedCity;
  String? selectedStore;

  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.removeListener(_validateForm);
    _nameController.dispose();
    isFormValid.dispose();
    super.dispose();
  }

  void _validateForm() {
    isFormValid.value = _nameController.text.isNotEmpty &&
        selectedCity != null &&
        selectedStore != null;
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<StockStore>(context);

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Nova Reposição",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        elevation: 4,
        backgroundColor: const Color(0xff60C03D),
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height / 2,
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  MyTextField(
                    controller: _nameController,
                    hintText: 'Seu Nome',
                    validator: FieldValidators.validateName,
                  ),
                  const SizedBox(height: 15),
                  MyDropDownButton(
                    value: selectedCity,
                    options: cityStores.keys.toList(),
                    hint: 'Selecione a Cidade',
                    onChanged: (value) {
                      setState(() {
                        selectedCity = value;
                        selectedStore =
                            null; // Resetar a loja ao mudar a cidade
                      });
                      _validateForm();
                    },
                  ),
                  const SizedBox(height: 15),
                  MyDropDownButton(
                    value: selectedStore,
                    options:
                        selectedCity != null ? cityStores[selectedCity!]! : [],
                    hint: 'Selecione a Loja',
                    onChanged: (value) {
                      setState(() {
                        selectedStore = value;
                      });
                      _validateForm();
                    },
                  ),
                  const SizedBox(height: 15),
                  ValueListenableBuilder<bool>(
                    valueListenable: isFormValid,
                    builder: (context, isValid, child) {
                      return MyButton(
                        buttonName: 'Próximo',
                        onTap: isValid
                            ? () {
                                if (formKey.currentState!.validate()) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ReposicaoFormularioPage(
                                        nome: _nameController.text,
                                        data: _date.toIso8601String(),
                                        loja: selectedStore!,
                                        reportData: null,
                                        city: selectedCity!,
                                        reportId: Uuid().v4(),
                                      ),
                                    ),
                                  );
                                }
                              }
                            : null,
                        enabled: isValid,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
