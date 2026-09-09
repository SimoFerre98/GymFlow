import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
part 'timer_settings_provider.g.dart';
/// Preferenze per la gestione del timer e del recupero automatico.
@immutable
class TimerSettings {
  const TimerSettings({
    this.autoRestEnabled = true,
    this.defaultRestSeconds = 90,
    this.vibrateOnTimerEnd = true,
    this.soundOnTimerEnd = true,
    this.restSecondsStrength = 180,
    this.restSecondsHypertrophy = 90,
    this.restSecondsEndurance = 45,
  });
  /// Avvia automaticamente il timer di recupero alla spunta di una serie.
  final bool autoRestEnabled;
  /// Durata del recupero predefinito in secondi (se ne' l'esercizio ne' il
  /// tipo di serie ne specificano una).
  final int defaultRestSeconds;
  /// Vibrazione attiva alla scadenza del timer di recupero.
  final bool vibrateOnTimerEnd;
  /// Suono di sistema attivo alla scadenza del timer di recupero.
  final bool soundOnTimerEnd;
  /// Recupero per serie di forza (1-5 ripetizioni), in secondi.
  final int restSecondsStrength;
  /// Recupero per serie di ipertrofia (6-12 ripetizioni), in secondi.
  final int restSecondsHypertrophy;
  /// Recupero per serie di resistenza (13+ ripetizioni), in secondi.
  final int restSecondsEndurance;
  /// Il recupero per il numero di ripetizioni della serie appena chiusa, in
  /// base alle tre fasce del mockup. `reps <= 0` (serie a cedimento, o dato
  /// assente) non e classificabile: usa [defaultRestSeconds], non una fascia
  /// scelta a caso.
  int restSecondsForReps(int reps) {
    if (reps <= 0) return defaultRestSeconds;
    if (reps <= 5) return restSecondsStrength;
    if (reps <= 12) return restSecondsHypertrophy;
    return restSecondsEndurance;
  }
  TimerSettings copyWith({
    bool? autoRestEnabled,
    int? defaultRestSeconds,
    bool? vibrateOnTimerEnd,
    bool? soundOnTimerEnd,
    int? restSecondsStrength,
    int? restSecondsHypertrophy,
    int? restSecondsEndurance,
  }) {
    return TimerSettings(
      autoRestEnabled: autoRestEnabled ?? this.autoRestEnabled,
      defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
      vibrateOnTimerEnd: vibrateOnTimerEnd ?? this.vibrateOnTimerEnd,
      soundOnTimerEnd: soundOnTimerEnd ?? this.soundOnTimerEnd,
      restSecondsStrength: restSecondsStrength ?? this.restSecondsStrength,
      restSecondsHypertrophy:
          restSecondsHypertrophy ?? this.restSecondsHypertrophy,
      restSecondsEndurance: restSecondsEndurance ?? this.restSecondsEndurance,
    );
  }
}
/// Provider per le impostazioni del timer con persistenza locale.
@Riverpod(keepAlive: true)
class TimerSettingsNotifier extends _$TimerSettingsNotifier {
  static const _autoRestKey = 'timer_auto_rest_enabled';
  static const _defaultRestKey = 'timer_default_rest_seconds';
  static const _vibrateKey = 'timer_vibrate_on_end';
  static const _soundKey = 'timer_sound_on_end';
  static const _restStrengthKey = 'timer_rest_strength_seconds';
  static const _restHypertrophyKey = 'timer_rest_hypertrophy_seconds';
  static const _restEnduranceKey = 'timer_rest_endurance_seconds';
  @override
  TimerSettings build() {
    _restore();
    return const TimerSettings();
  }
  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoRest = prefs.getBool(_autoRestKey);
      final defaultRest = prefs.getInt(_defaultRestKey);
      final vibrate = prefs.getBool(_vibrateKey);
      final sound = prefs.getBool(_soundKey);
      final restStrength = prefs.getInt(_restStrengthKey);
      final restHypertrophy = prefs.getInt(_restHypertrophyKey);
      final restEndurance = prefs.getInt(_restEnduranceKey);
      state = state.copyWith(
        autoRestEnabled: autoRest,
        defaultRestSeconds: defaultRest,
        vibrateOnTimerEnd: vibrate,
        soundOnTimerEnd: sound,
        restSecondsStrength: restStrength,
        restSecondsHypertrophy: restHypertrophy,
        restSecondsEndurance: restEndurance,
      );
    } catch (_) {
      // In contesti di test dove il canale SharedPreferences non e mockato,
      // mantiene i valori di default costanti.
    }
  }
  Future<void> setAutoRestEnabled(bool enabled) async {
    state = state.copyWith(autoRestEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoRestKey, enabled);
  }
  Future<void> setDefaultRestSeconds(int seconds) async {
    state = state.copyWith(defaultRestSeconds: seconds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_defaultRestKey, seconds);
  }
  Future<void> setVibrateOnTimerEnd(bool enabled) async {
    state = state.copyWith(vibrateOnTimerEnd: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrateKey, enabled);
  }
  Future<void> setSoundOnTimerEnd(bool enabled) async {
    state = state.copyWith(soundOnTimerEnd: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, enabled);
  }
  Future<void> setRestSecondsStrength(int seconds) async {
    state = state.copyWith(restSecondsStrength: seconds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_restStrengthKey, seconds);
  }
  Future<void> setRestSecondsHypertrophy(int seconds) async {
    state = state.copyWith(restSecondsHypertrophy: seconds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_restHypertrophyKey, seconds);
  }
  Future<void> setRestSecondsEndurance(int seconds) async {
    state = state.copyWith(restSecondsEndurance: seconds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_restEnduranceKey, seconds);
  }
}
