import 'package:gymflow/src/models/workout_program.dart';

/// Dove si trova una scheda rispetto alle sue date.
enum ProgramPhase {
  /// Nessuna data di inizio: non c'e una settimana da contare.
  undated,

  /// Inizia in un giorno futuro.
  upcoming,

  /// In corso: comincia da oggi o prima, e non e ancora finita.
  running,

  /// La data di fine e passata.
  ended,
}

/// La posizione di una scheda nel tempo, calcolata dalle sole date che
/// l'utente ha scritto: nessun dato inventato.
class ProgramTimeline {
  const ProgramTimeline({
    required this.phase,
    this.week,
    this.totalWeeks,
    this.daysToStart,
  });

  final ProgramPhase phase;

  /// La settimana corrente, da 1. Solo se [phase] e `running`.
  final int? week;

  /// Le settimane totali. Assente se la scheda non ha una data di fine.
  final int? totalWeeks;

  /// Giorni mancanti all'inizio. Solo se [phase] e `upcoming`.
  final int? daysToStart;

  /// Quanto del percorso e fatto, da 0 a 1; assente senza una data di fine.
  double? get progress {
    if (phase != ProgramPhase.running || week == null || totalWeeks == null) return null;
    return (week! / totalWeeks!).clamp(0.0, 1.0);
  }
}

/// Calcola [ProgramTimeline] per [program] al giorno di [now].
///
/// Si confrontano **giorni**, non istanti: una scheda che inizia oggi e in
/// corso dalla mezzanotte, e l'ora legale non sposta una settimana. Una data
/// di fine precedente all'inizio e un dato sbagliato: la scheda si tratta come
/// senza fine invece di dichiararla conclusa prima di cominciare.
ProgramTimeline programTimeline(WorkoutProgram program, DateTime now) {
  final start = program.startDate;
  if (start == null) return const ProgramTimeline(phase: ProgramPhase.undated);

  DateTime soloGiorno(DateTime d) => DateTime.utc(d.year, d.month, d.day);
  final oggi = soloGiorno(now);
  final inizio = soloGiorno(start);

  if (oggi.isBefore(inizio)) {
    return ProgramTimeline(
      phase: ProgramPhase.upcoming,
      daysToStart: inizio.difference(oggi).inDays,
    );
  }

  final endDate = program.endDate;
  final fine = endDate == null ? null : soloGiorno(endDate);
  final fineValida = fine != null && !fine.isBefore(inizio);

  int? settimaneTotali;
  if (fineValida) {
    // La data di fine e inclusa: dal lunedi al venerdi della stessa settimana
    // sono 5 giorni, non 4.
    final giorni = fine.difference(inizio).inDays + 1;
    settimaneTotali = (giorni / 7).ceil();
    if (oggi.isAfter(fine)) {
      return ProgramTimeline(phase: ProgramPhase.ended, totalWeeks: settimaneTotali);
    }
  }

  var settimana = oggi.difference(inizio).inDays ~/ 7 + 1;
  if (settimaneTotali != null && settimana > settimaneTotali) settimana = settimaneTotali;
  return ProgramTimeline(
    phase: ProgramPhase.running,
    week: settimana,
    totalWeeks: settimaneTotali,
  );
}
