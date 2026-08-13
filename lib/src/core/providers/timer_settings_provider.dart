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
  });

  /// Avvia automaticamente il timer di recupero alla spunta di una serie.
  final bool autoRestEnabled;

  /// Durata del recupero predefinito in secondi (se l'esercizio non ne specifica una).
  final int defaultRestSeconds;

  /// Vibrazione attiva alla scadenza del timer di recupero.
  final bool vibrateOnTimerEnd;

  TimerSettings copyWith({
    bool? autoRestEnabled,
    int? defaultRestSeconds,
    bool? vibrateOnTimerEnd,
  }) {
    return TimerSettings(
      autoRestEnabled: autoRestEnabled ?? this.autoRestEnabled,
      defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
      vibrateOnTimerEnd: vibrateOnTimerEnd ?? this.vibrateOnTimerEnd,
    );
  }
}

/// Provider per le impostazioni del timer con persistenza locale.
@Riverpod(keepAlive: true)
class TimerSettingsNotifier extends _$TimerSettingsNotifier {
  static const _autoRestKey = 'timer_auto_rest_enabled';
  static const _defaultRestKey = 'timer_default_rest_seconds';
  static const _vibrateKey = 'timer_vibrate_on_end';

  @override
  TimerSettings build() {
    _restore();
    return const TimerSettings();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final autoRest = prefs.getBool(_autoRestKey);
    final defaultRest = prefs.getInt(_defaultRestKey);
    final vibrate = prefs.getBool(_vibrateKey);

    state = state.copyWith(
      autoRestEnabled: autoRest,
      defaultRestSeconds: defaultRest,
      vibrateOnTimerEnd: vibrate,
    );
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
}
