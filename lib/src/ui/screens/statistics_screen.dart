import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:intl/intl.dart';
import '../../core/providers/localization_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/live_metrics_provider.dart'; // per healthServiceProvider
import '../../services/health_service.dart'; // per PermessiSaluteMancanti
import '../../models/session.dart';
import '../../models/workout_type.dart';
import '../../core/utils/statistics_helper.dart';
import '../widgets/back_pill.dart';
import '../widgets/charts/activity_chart.dart';
import '../widgets/charts/body_measurements_chart.dart';
import '../widgets/expressive_card.dart';
import '../widgets/sparkline.dart';
import '../../core/theme/immersivo_tokens.dart';
import 'package:health/health.dart';
import 'health_detail_screen.dart';
import 'workout_summary_screen.dart';
/// L'altezza dei due grafici a card: attivita e progresso corporeo.
///
/// Non e una misura del design system — nessun token descrive l'altezza di un
/// grafico — ma `fl_chart` ne vuole una definita per disegnare. Una costante
/// sola e non due numeri scritti a mano nei due punti d'uso: cosi i due
/// grafici restano della stessa altezza per costruzione, non per coincidenza.
const double kAltezzaGraficoStatistiche = 200;
/// Misure del mockup 1d Progressi (telaio a 384px = 384dp, nessuna
/// conversione — vedi `DESIGN-SPEC.md`): il numero del volume e piu grande di
/// qualunque voce di `typography.display`, quello dello streak piu piccolo.
const double _kVolumeFontSize = 48;
const double _kStreakFontSize = 34;
const double _kHistoryTitleFontSize = 28;
const double _kHeaderIconBoxSide = 36;
/// I tre periodi del mockup 1d Progressi. `giorni` e null per "tutto".
enum _Periodo {
  quattroSettimane(28),
  dodiciSettimane(84),
  unAnno(365);
  const _Periodo(this.giorni);
  final int giorni;
  String label(Localization loc) => switch (this) {
        _Periodo.quattroSettimane => loc.t('stats_period_4w'),
        _Periodo.dodiciSettimane => loc.t('stats_period_12w'),
        _Periodo.unAnno => loc.t('stats_period_1y'),
      };
}
class StatisticsScreen extends riverpod.ConsumerStatefulWidget {
  const StatisticsScreen({super.key});
  @override
  riverpod.ConsumerState<StatisticsScreen> createState() =>
      _StatisticsScreenState();
}
class _StatisticsScreenState extends riverpod.ConsumerState<StatisticsScreen> {
  Future<Map<String, dynamic>>? _healthDataFuture;
  _Periodo _periodo = _Periodo.quattroSettimane;
  @override
  void initState() {
    super.initState();
    _healthDataFuture = _initAndFetchHealth();
  }
  Future<Map<String, dynamic>> _initAndFetchHealth() async {
    if (kIsWeb) return {};
    try {
      final health = ref.read(healthServiceProviderProvider);
      await health.configure();
      final mancanti = await health.getMissingSummaryPermissions();
      if (mancanti != null && mancanti.isNotEmpty) {
        // Con dentro l'elenco: la schermata deve poter dire **cosa** manca, non
        // solo che qualcosa e andato storto.
        throw PermessiSaluteMancanti(mancanti);
      }
      return await health.fetchDailySummary();
    } catch (e) {
      debugPrint('Health Load Error: $e');
      rethrow;
    }
  }
  /// Chiede i permessi e ricarica, se sono stati concessi.
  ///
  /// `mounted` dopo l'attesa: la richiesta apre una schermata di sistema, e
  /// l'utente puo tornare indietro chiudendo questa.
  Future<void> _chiediPermessiSalute() async {
    final concessi = await ref.read(healthServiceProviderProvider).requestPermissions();
    if (!mounted) return;
    if (concessi) await _refreshHealthData();
  }
  Future<void> _refreshHealthData() async {
    setState(() {
      _healthDataFuture = ref.read(healthServiceProviderProvider).fetchDailySummary();
    });
    try {
      await _healthDataFuture;
    } catch (_) {}
  }
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localizationNotifierProvider);
    final userId = ref.watch(currentUserIdProvider) ?? '';
    final sessionsAsync = ref.watch(dashboardSessionsProvider);
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(t.spacing.lg, t.spacing.sm, t.spacing.lg, 0),
              child: _buildHeader(context, loc, t, scheme, sessionsAsync.valueOrNull ?? const []),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshHealthData,
                child: sessionsAsync.when(
                  data: (allSessions) => _buildBody(context, loc, t, scheme, allSessions, userId),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildHeader(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
    List<WorkoutSession> sessions,
  ) {
    const iconBoxSide = _kHeaderIconBoxSide;
    return Row(
      children: [
        Text(
          loc.t('data_tab').toUpperCase(),
          style: t.typography.title?.copyWith(color: scheme.onSurface),
        ),
        SizedBox(width: t.spacing.md),
        Expanded(
          child: Container(height: 1, color: scheme.primary.withValues(alpha: 0.5)),
        ),
        SizedBox(width: t.spacing.md),
        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _HistoryScreen(sessions: sessions, loc: loc),
            ),
          ),
          child: Container(
            width: iconBoxSide,
            height: iconBoxSide,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              border: Border.all(color: scheme.outline),
            ),
            child: Icon(Icons.history, size: 18, color: scheme.onSurface),
          ),
        ),
      ],
    );
  }
  Widget _buildBody(
    BuildContext context,
    Localization loc,
    ImmersivoTokens t,
    ColorScheme scheme,
    List<WorkoutSession> allSessions,
    String userId,
  ) {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: _periodo.giorni));
    final sessions = allSessions.where((s) => s.startTime.isAfter(cutoff)).toList();
    // Confronto col periodo equivalente precedente, per la percentuale.
    final periodoPrecedenteInizio = cutoff.subtract(Duration(days: _periodo.giorni));
    final sessioniPeriodoPrecedente = allSessions
        .where((s) => s.startTime.isAfter(periodoPrecedenteInizio) && s.startTime.isBefore(cutoff))
        .toList();
    final volume = StatisticsHelper.calculateTotalVolume(sessions);
    final volumePrecedente =
        StatisticsHelper.calculateTotalVolume(sessioniPeriodoPrecedente);
    final variazione = volumePrecedente > 0
        ? ((volume - volumePrecedente) / volumePrecedente * 100)
        : null;
    final settimane = _volumePerSettimana(sessions, now);
    final streak = StatisticsHelper.calculateCurrentStreak(allSessions);
    final ultimiSetteGiorni = _ultimiSetteGiorniLavorati(allSessions, now);
    final ripartizione = StatisticsHelper.getWorkoutTypeDistribution(sessions);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(t.spacing.lg, t.spacing.sm, t.spacing.lg, 0),
            child: Row(
              children: [
                for (final p in _Periodo.values)
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _periodo = p),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: p == _periodo ? scheme.primary : null,
                          border: Border.all(color: scheme.outline),
                        ),
                        child: Text(
                          p.label(loc).toUpperCase(),
                          style: t.typography.eyebrow?.copyWith(
                            color: p == _periodo
                                ? scheme.onPrimary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(t.spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // VOLUME — la sezione "MASSIMALE" del mockup, adattata: un
                // massimale su un solo esercizio non e disponibile senza una
                // nuova interrogazione (serve una serie storica per singolo
                // esercizio, non solo il primato corrente). Il volume e la
                // stessa forma — numero grande, variazione, andamento — su un
                // dato che questa schermata gia calcola per intero.
                _SezioneDati(
                  eyebrow: loc.t('volume_label'),
                  footer: settimane.length > 1
                      ? Sparkline(
                          values: settimane.map((s) => s.$2.toDouble()).toList(),
                          color: scheme.primary,
                          height: _kChartHeight,
                          width: double.infinity,
                        )
                      : null,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$volume',
                            style: t.typography.display?.copyWith(
                              fontSize: _kVolumeFontSize,
                              color: scheme.primary,
                            ),
                          ),
                          Text(
                            ' kg',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      if (variazione != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: t.spacing.sm,
                            vertical: t.spacing.xs,
                          ),
                          color: scheme.tertiary,
                          child: Text(
                            '${variazione >= 0 ? '+' : ''}${variazione.toStringAsFixed(1)}%',
                            style: t.typography.eyebrow?.copyWith(
                              color: scheme.onTertiary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: t.spacing.xl),
                // VOLUME SETTIMANALE
                if (settimane.isNotEmpty)
                  _SezioneDati(
                    eyebrow: loc.t('weekly_volume_label'),
                    child: SizedBox(
                      height: _kBarChartHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final s in settimane) ...[
                            Expanded(
                              child: FractionallySizedBox(
                                heightFactor: _frazioneBarra(settimane, s.$2),
                                alignment: Alignment.bottomCenter,
                                // `ColoredBox` qui non disegnava nulla (le
                                // barre restavano un unico blocco pieno,
                                // riprodotto e isolato con un fondo
                                // magenta di debug durante la story
                                // Immersivo, 2026-08-21); `Container` con lo
                                // stesso `color` funziona.
                                child: Container(
                                  color: s == settimane.last
                                      ? scheme.primary
                                      : scheme.surfaceContainerHigh,
                                ),
                              ),
                            ),
                            if (s != settimane.last) SizedBox(width: t.spacing.xs),
                          ],
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: t.spacing.xl),
                // RIPARTIZIONE
                if (ripartizione.isNotEmpty)
                  _SezioneDati(
                    eyebrow: loc.t('breakdown_label'),
                    child: Column(
                      children: [
                        for (final entry in ripartizione.entries)
                          Padding(
                            padding: EdgeInsets.only(bottom: t.spacing.sm),
                            child: _RigaRipartizione(
                              etichetta: loc.t(
                                WorkoutType.fromString(entry.key.toLowerCase())
                                    .localizationKey,
                              ),
                              frazione: entry.value /
                                  ripartizione.values.fold(0, (a, b) => a + b),
                              colore: _coloreTipo(
                                WorkoutType.fromString(entry.key.toLowerCase()),
                                scheme,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                SizedBox(height: t.spacing.xl),
                // STREAK
                _SezioneDati(
                  eyebrow: loc.t('streak_label'),
                  child: Row(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$streak',
                            style: t.typography.display?.copyWith(
                              fontSize: _kStreakFontSize,
                              color: scheme.onSurface,
                            ),
                          ),
                          Text(
                            ' ${loc.t('days_label').toUpperCase()}',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      SizedBox(width: t.spacing.lg),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            for (final lavorato in ultimiSetteGiorni) ...[
                              Expanded(
                                child: Container(
                                  height: _kStreakBlockHeight,
                                  color: lavorato
                                      ? scheme.primary
                                      : scheme.onSurface.withValues(alpha: 0.12),
                                ),
                              ),
                              if (lavorato != ultimiSetteGiorni.last)
                                SizedBox(width: t.spacing.xs),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Contenuto reale non coperto dal mockup: salute e misure del
                // corpo. Non tolto — solo spostato sotto le sezioni che
                // replicano il mockup, invece di duplicarne il posto.
                SizedBox(height: t.spacing.xxl),
                Container(height: 1, color: scheme.outline),
                SizedBox(height: t.spacing.lg),
                HealthSummarySection(
                  future: _healthDataFuture,
                  loc: loc,
                  onConsenti: _chiediPermessiSalute,
                ),
                SizedBox(height: t.spacing.md),
                RepaintBoundary(
                  child: ExpressiveCard(
                    title: loc.t('workout_activity_chart'),
                    child: SizedBox(
                      height: kAltezzaGraficoStatistiche,
                      child: ActivityChart(sessions: allSessions),
                    ),
                  ),
                ),
                SizedBox(height: t.spacing.md),
                RepaintBoundary(
                  child: ExpressiveCard(
                    title: loc.t('body_progress_chart'),
                    child: SizedBox(
                      height: kAltezzaGraficoStatistiche,
                      child: BodyMeasurementsChart(userId: userId),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(padding: EdgeInsets.only(bottom: t.spacing.bottomInset)),
      ],
    );
  }
  static const double _kChartHeight = 90;
  static const double _kBarChartHeight = 78;
  static const double _kStreakBlockHeight = 24;
  /// Volume per settimana, dalla piu vecchia alla piu recente — al massimo
  /// otto barre, per non far crescere il grafico oltre lo spazio che il
  /// mockup gli riserva.
  List<(DateTime, int)> _volumePerSettimana(
    List<WorkoutSession> sessions,
    DateTime now,
  ) {
    final settimane = <(DateTime, int)>[];
    for (var i = 7; i >= 0; i--) {
      final fine = now.subtract(Duration(days: i * 7));
      final inizio = fine.subtract(const Duration(days: 7));
      final diQuestaSettimana = sessions
          .where((s) => s.startTime.isAfter(inizio) && s.startTime.isBefore(fine))
          .toList();
      if (diQuestaSettimana.isEmpty && settimane.isEmpty) continue;
      settimane.add((inizio, StatisticsHelper.calculateTotalVolume(diQuestaSettimana)));
    }
    return settimane;
  }
  double _frazioneBarra(List<(DateTime, int)> settimane, int valore) {
    final massimo = settimane.map((s) => s.$2).fold(0, (a, b) => a > b ? a : b);
    if (massimo <= 0) return 0.02;
    return (valore / massimo).clamp(0.02, 1.0);
  }
  List<bool> _ultimiSetteGiorniLavorati(
    List<WorkoutSession> sessions,
    DateTime now,
  ) {
    final oggi = DateTime(now.year, now.month, now.day);
    return List.generate(7, (i) {
      final giorno = oggi.subtract(Duration(days: 6 - i));
      return sessions.any((s) {
        final data = DateTime(
          s.startTime.year,
          s.startTime.month,
          s.startTime.day,
        );
        return data.isAtSameMomentAs(giorno);
      });
    });
  }
  Color _coloreTipo(WorkoutType type, ColorScheme scheme) => switch (type) {
        WorkoutType.strength => scheme.primary,
        WorkoutType.cardio => scheme.tertiary,
        WorkoutType.mobility => scheme.secondary,
        WorkoutType.sport => scheme.outline,
      };
}
/// Una sezione della schermata Dati: etichetta piccola maiuscola, filetto
/// sopra, contenuto — la stessa grammatica ripetuta per massimale, volume
/// settimanale, ripartizione e streak nel mockup 1d Progressi.
class _SezioneDati extends StatelessWidget {
  const _SezioneDati({required this.eyebrow, required this.child, this.footer});
  final String eyebrow;
  final Widget child;
  final Widget? footer;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: t.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(eyebrow.toUpperCase(), style: t.typography.eyebrow),
            SizedBox(height: t.spacing.sm),
            child,
            if (footer != null) ...[
              SizedBox(height: t.spacing.sm),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
class _RigaRipartizione extends StatelessWidget {
  const _RigaRipartizione({
    required this.etichetta,
    required this.frazione,
    required this.colore,
  });
  final String etichetta;
  final double frazione;
  final Color colore;
  static const double _kLabelWidth = 84;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: _kLabelWidth,
          child: Text(
            etichetta.toUpperCase(),
            style: t.typography.eyebrow?.copyWith(color: scheme.onSurface),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: t.spacing.md,
            // `ColoredBox` qui non disegnava nulla — vedi la nota sulla
            // barra del volume settimanale poco sopra in questo file.
            child: Stack(
              children: [
                Container(color: scheme.onSurface.withValues(alpha: 0.1)),
                FractionallySizedBox(widthFactor: frazione, child: Container(color: colore)),
              ],
            ),
          ),
        ),
        SizedBox(width: t.spacing.sm),
        SizedBox(
          width: t.sizing.thumbnailSm,
          child: Text(
            '${(frazione * 100).round()}%',
            textAlign: TextAlign.right,
            style: t.typography.eyebrow?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
/// Lo storico delle sessioni, non piu una scheda della schermata Dati — il
/// mockup non lo mostra come vista primaria, resta raggiungibile dall'icona
/// nell'intestazione senza sparire.
class _HistoryScreen extends StatelessWidget {
  const _HistoryScreen({required this.sessions, required this.loc});
  final List<WorkoutSession> sessions;
  final Localization loc;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(t.spacing.md, t.spacing.sm, t.spacing.md, 0),
              child: Row(
                children: [
                  BackPill(label: loc.t('data_tab')),
                  SizedBox(width: t.spacing.md),
                  Text(
                    loc.t('history_tab').toUpperCase(),
                    style: t.typography.headline?.copyWith(
                      fontSize: _kHistoryTitleFontSize,
                      color: scheme.onSurface,
                    ),
                  ),
                  SizedBox(width: t.spacing.md),
                  Expanded(
                    child: Container(height: 1, color: scheme.primary.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(context, t)),
          ],
        ),
      ),
    );
  }
  Widget _buildBody(BuildContext context, ImmersivoTokens t) {
    return sessions.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(t.spacing.xxl),
                child: Text(loc.t('no_workouts_history')),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: t.spacing.lg,
                vertical: t.spacing.sm,
              ),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final now = DateTime.now();
                final isToday = now.difference(session.startTime).inDays == 0 &&
                    session.startTime.day == now.day;
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: t.spacing.xs),
                  child: _StoricoItem(session: session, isToday: isToday),
                );
              },
            );
  }
}
class _StoricoItem extends StatelessWidget {
  const _StoricoItem({required this.session, required this.isToday});
  final WorkoutSession session;
  final bool isToday;
  @override
  Widget build(BuildContext context) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(border: Border.all(color: scheme.outline)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WorkoutSummaryScreen(session: session),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(t.spacing.md),
          child: Row(
            children: [
              Container(
                width: t.sizing.thumbnailMd,
                height: t.sizing.thumbnailMd,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isToday ? scheme.primary.withValues(alpha: 0.15) : null,
                  border: isToday ? Border.all(color: scheme.primary) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('dd').format(session.startTime),
                      style: t.typography.metricSmall?.copyWith(
                        color: isToday ? scheme.primary : scheme.onSurface,
                      ),
                    ),
                    Text(
                      DateFormat('MMM').format(session.startTime).toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isToday ? scheme.primary : scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: t.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.workoutName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: t.spacing.xs),
                    Text(
                      DateFormat('HH:mm').format(session.startTime),
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
/// La sintesi salute delle statistiche: passi e calorie di oggi.
///
/// È un widget suo e non un metodo della schermata perche `StatisticsScreen`
/// intera non si monta in un test — legge Firestore e i provider della
/// dashboard — e senza montarla non c'e modo di dimostrare la cosa che questa
/// storia promette: che quando il permesso manca **non compare uno zero**.
class HealthSummarySection extends StatelessWidget {
  const HealthSummarySection({
    super.key,
    required this.future,
    required this.loc,
    required this.onConsenti,
  });
  /// La sintesi giornaliera, o l'errore che ne ha impedito la lettura.
  final Future<Map<String, dynamic>>? future;
  final Localization loc;
  /// Chiede i permessi. Vive nella schermata, che ha `ref`.
  final VoidCallback onConsenti;
  /// Il nome leggibile di un tipo di dato, per dire cosa manca.
  String _nome(HealthDataType tipo, Localization loc) => switch (tipo) {
    HealthDataType.STEPS => loc.t('steps_label'),
    HealthDataType.ACTIVE_ENERGY_BURNED => loc.t('active_cal_label'),
    _ => tipo.name,
  };
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError) {
          // Prima di questa storia l'errore finiva in `snapshot.data ?? {}` e
          // diventava «0 passi, 0 calorie». Uno zero inventato e peggio di un
          // dato assente: il secondo si nota e si chiede, il primo si crede.
          final errore = snapshot.error;
          return _avviso(
            context,
            errore is PermessiSaluteMancanti ? errore.tipi : null,
          );
        }
        final data = snapshot.data ?? {};
        final steps = data['steps'] ?? 0;
        final calories = data['calories'] ?? 0;
        final t = context.immersivo;
        final scheme = Theme.of(context).colorScheme;
        return Row(
          children: [
            Expanded(
              child: ExpressiveCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HealthDetailScreen(
                        dataType: HealthDataType.STEPS,
                        title: loc.t('steps_label'),
                        baseColor: scheme.secondary,
                        unit: 'steps',
                      ),
                    ),
                  );
                },
                child: _buildStatColumn(
                  context,
                  loc.t('steps_label'),
                  '$steps',
                  Icons.directions_walk,
                  scheme.secondary,
                ),
              ),
            ),
            SizedBox(width: t.spacing.md),
            Expanded(
              child: ExpressiveCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HealthDetailScreen(
                        dataType: HealthDataType.ACTIVE_ENERGY_BURNED,
                        title: loc.t('active_cal_label'),
                        baseColor: scheme.tertiary,
                        unit: 'kcal',
                      ),
                    ),
                  );
                },
                child: _buildStatColumn(
                  context,
                  loc.t('active_cal_label'),
                  '${calories.toInt()}',
                  Icons.local_fire_department,
                  // Le calorie sono un dato vitale come il battito: salmone.
                  // Il rosso che c'era qui e il ruolo dell'errore.
                  scheme.tertiary,
                  suffix: ' kcal',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  Widget _buildStatColumn(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    String? suffix,
  }) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        SizedBox(height: t.spacing.sm),
        Text(
          value + (suffix ?? ''),
          style: t.typography.metricSmall?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
  Widget _avviso(BuildContext context, List<HealthDataType>? mancanti) {
    final t = context.immersivo;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.spacing.lg),
      child: ExpressiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: scheme.error),
                SizedBox(width: t.spacing.sm),
                Expanded(
                  child: Text(
                    loc.t('health_permission_needed'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            // Quali dati mancano, quando si sa: e la differenza fra «qualcosa
            // non va» e un'informazione su cui si puo agire. Se non si sa —
            // `hasPermissions` non sempre risponde — non si inventa un elenco.
            if (mancanti != null && mancanti.isNotEmpty) ...[
              SizedBox(height: t.spacing.sm),
              Text(
                '${loc.t('health_permission_missing_prefix')} '
                '${mancanti.map((tipo) => _nome(tipo, loc)).join(', ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            SizedBox(height: t.spacing.md),
            FilledButton.icon(
              onPressed: onConsenti,
              icon: const Icon(Icons.health_and_safety_outlined),
              label: Text(loc.t('health_permission_grant')),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
