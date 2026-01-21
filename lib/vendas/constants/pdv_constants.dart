import 'package:flutter/material.dart';

enum CategoriaPDV { loja, turismo, evento }

const Map<CategoriaPDV, String> nomeCategoria = {
  CategoriaPDV.loja: 'Lojas',
  CategoriaPDV.turismo: 'Turismo',
  CategoriaPDV.evento: 'Eventos',
};

const Map<String, CategoriaPDV> categoriaPDV = {
  // Lojas (abrem diariamente)
  'paineiras': CategoriaPDV.loja,
  'retiro': CategoriaPDV.loja,
  'itupeva': CategoriaPDV.loja,
  'sousas': CategoriaPDV.loja,
  'mercadao': CategoriaPDV.loja,
  'sem_vendedor': CategoriaPDV.loja,

  // Turismo (finais de semana)
  'bendito_quintal': CategoriaPDV.turismo,
  'brunholli': CategoriaPDV.turismo,
  'fontebasso': CategoriaPDV.turismo,
  'marquezim': CategoriaPDV.turismo,
  'micheletto': CategoriaPDV.turismo,
  'sassafras': CategoriaPDV.turismo,
  'travitalia': CategoriaPDV.turismo,
  'bar_da_cachoeira': CategoriaPDV.turismo,
  'sitio_sao_f': CategoriaPDV.turismo,
  'da_roca': CategoriaPDV.turismo,

  // Eventos (ocasionais)
  'evento_1': CategoriaPDV.evento,
  'evento_2': CategoriaPDV.evento,
  'eventos': CategoriaPDV.evento,
  'eventos_2': CategoriaPDV.evento,
};

const Map<String, double> metasMensaisPDV = {
  // Lojas
  'paineiras': 35000,
  'retiro': 80000,
  'itupeva': 35000,
  'sousas': 30000,
  'mercadao': 130000,
  'sem_vendedor': 1000,

  // Turismo
  'bendito_quintal': 5000,
  'brunholli': 5000,
  'fontebasso': 5000,
  'marquezim': 5000,
  'micheletto': 5000,
  'sassafras': 5000,
  'travitalia': 5000,
  'bar_da_cachoeira': 5000,
  'sitio_sao_f': 5000,
  'da_roca': 5000,

  // Eventos
  'evento_1': 5000,
  'evento_2': 5000,
  'eventos': 5000,
  'eventos_2': 5000,
};

const Map<String, Color> coresPDV = {
  'paineiras': Color(0xFFEC4899),
  'retiro': Color(0xFF06B6D4),
  'itupeva': Color(0xFFF97316),
  'sousas': Color(0xFF22C55E),
  'mercadao': Color(0xFFF59E0B),
  'sem_vendedor': Color(0xFF94A3B8),
  'bendito_quintal': Color(0xFF8B5CF6),
  'brunholli': Color(0xFFF43F5E),
  'fontebasso': Color(0xFF14B8A6),
  'marquezim': Color(0xFFEAB308),
  'micheletto': Color(0xFF6366F1),
  'sassafras': Color(0xFF84CC16),
  'travitalia': Color(0xFF0EA5E9),
  'bar_da_cachoeira': Color(0xFFD946EF),
  'da_roca': Color(0xFFFB923C),
  'sitio_sao_f': Color(0xFF10B981),
  'evento_1': Color(0xFF8B5CF6),
  'evento_2': Color(0xFF6366F1),
  'eventos': Color(0xFFA855F7),
  'eventos_2': Color(0xFF7C3AED),
};

Color getCorPDV(String storeId) {
  return coresPDV[storeId] ?? const Color(0xFF9CA3AF);
}

double getMetaMensal(String storeId) {
  return metasMensaisPDV[storeId] ?? 5000;
}

CategoriaPDV getCategoria(String storeId) {
  return categoriaPDV[storeId] ?? CategoriaPDV.evento;
}
