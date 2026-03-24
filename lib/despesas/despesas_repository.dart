import '../main.dart';
import 'models/despesa_lancamento.dart';

class DespesasRepository {
  /// Busca todos os lançamentos do nó /score/lancamentos/ no Firebase.
  /// Retorna apenas os do tipo "pagamento" (despesas).
  Future<List<DespesaLancamento>> fetchDespesas() async {
    final snapshot = await salesDatabase.ref('/score/lancamentos').get();

    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final rawData = Map<String, dynamic>.from(snapshot.value as Map);
    final List<DespesaLancamento> lancamentos = [];

    for (final unidadeEntry in rawData.entries) {
      final unidade = unidadeEntry.key;
      final unidadeData = unidadeEntry.value;

      if (unidadeData == null || unidadeData is! Map) continue;

      final mesesMap = Map<String, dynamic>.from(unidadeData as Map);

      for (final mesEntry in mesesMap.entries) {
        final mesKey = mesEntry.key; // formato YYYY-MM
        final mesData = mesEntry.value;

        if (mesData == null) continue;

        // Os lançamentos podem ser uma lista ou um mapa indexado
        List<dynamic> items = [];
        if (mesData is List) {
          items = mesData;
        } else if (mesData is Map) {
          items = Map<String, dynamic>.from(mesData as Map).values.toList();
        }

        for (final item in items) {
          if (item == null || item is! Map) continue;
          final lancamento = DespesaLancamento.fromMap(
            Map<dynamic, dynamic>.from(item as Map),
            unidade,
            mesKey,
          );

          // Filtrar apenas despesas (pagamentos)
          if (lancamento.tipo == 'pagamento') {
            lancamentos.add(lancamento);
          }
        }
      }
    }

    return lancamentos;
  }
}
