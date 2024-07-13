// utils/comanda_utils.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:orama_admin/stores/comanda_store.dart';
import 'package:orama_admin/widgets/cards/admin_descartaveis_card.dart';

class ComandaUtils {
  static Future<void> deleteComandaDescartaveis(BuildContext context, ComandaDescartaveis comanda) async {
    try {
      final userId = GetStorage().read('userId');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('descartaveis')
          .doc(comanda.id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comanda deletada com sucesso.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Erro ao deletar a comanda: $e');
    }
  }
}
