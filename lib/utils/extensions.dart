import 'package:flutter/material.dart';

extension TextEditingControllerExtension on TextEditingController {
  // Não podemos verificar "isDisposed" diretamente, então usamos uma solução alternativa
  bool get isDisposed => text == null; // Não é perfeito, mas pode ajudar
}