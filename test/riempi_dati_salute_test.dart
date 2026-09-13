import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/ui/screens/health_detail_screen.dart';

/// Un giorno senza lettura di battito/peso non deve diventare uno zero.
///
/// Prima di questo fix, `HealthDetailScreen` riempiva ogni giorno senza dato
/// con 0.0, per qualunque tipo di dato. Per battito e peso — misurazioni
/// puntuali e sparse, non conteggi del giorno come i passi — questo falsava
/// sia la media (`total / _data.length`, con `_data.length` sempre il
/// numero di giorni del periodo, mai i giorni con un dato vero) sia il
/// minimo del grafico a linea (sempre 0 per via dello zero artificiale).
void main() {
  test('con riempiZero: false, i giorni senza dato restano assenti', () {
    final giorni = [
      DateTime(2026, 9, 1),
      DateTime(2026, 9, 2),
      DateTime(2026, 9, 3),
    ];
    final risultato = riempiDatiSalute(
      dati: {DateTime(2026, 9, 1): 75.0},
      giorni: giorni,
      riempiZero: false,
    );

    expect(risultato.length, 1, reason: 'un solo giorno aveva davvero una misurazione');
    expect(risultato[DateTime(2026, 9, 1)], 75.0);
  });

  test('con riempiZero: true, i giorni senza dato diventano zero', () {
    final giorni = [
      DateTime(2026, 9, 1),
      DateTime(2026, 9, 2),
      DateTime(2026, 9, 3),
    ];
    final risultato = riempiDatiSalute(
      dati: {DateTime(2026, 9, 1): 5000.0},
      giorni: giorni,
      riempiZero: true,
    );

    expect(risultato.length, 3);
    expect(risultato[DateTime(2026, 9, 2)], 0.0);
  });

  test('la media su dati non riempiti conta solo i giorni veri: 75 su un giorno, non 75 su sette', () {
    final giorni = List.generate(7, (i) => DateTime(2026, 9, 1 + i));
    final risultato = riempiDatiSalute(
      dati: {DateTime(2026, 9, 1): 75.0},
      giorni: giorni,
      riempiZero: false,
    );

    final media = risultato.values.reduce((a, b) => a + b) / risultato.length;
    expect(media, 75.0, reason: 'non 75/7 = 10.7, il peso medio reale e 75');
  });
}
