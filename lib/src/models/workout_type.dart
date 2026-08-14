/// Tipi di allenamento supportati dall'applicazione.
///
/// Ogni tipo dichiara i propri campi caratteristici:
/// - [strength] (Palestra): serie, ripetizioni, carico (kg)
/// - [cardio] (Cardio / Corsa): distanza (km), durata/tempo, ritmo (min/km), battito
/// - [mobility] (Mobilità / Stretching): durata/tempo, intensità/rpe, note
/// - [sport] (Sport / Attività): durata/tempo, calorie, battito, note
enum WorkoutType {
  strength,
  cardio,
  mobility,
  sport;

  /// Converte una stringa (es. da Firestore o Isar) in [WorkoutType],
  /// con retrocompatibilità per sessioni storiche e valori nulli che
  /// ricadono su [strength].
  static WorkoutType fromString(String? value) {
    if (value == null) return WorkoutType.strength;
    switch (value.trim().toLowerCase()) {
      case 'cardio':
      case 'running':
      case 'cycling':
        return WorkoutType.cardio;
      case 'mobility':
      case 'flexibility':
      case 'stretching':
      case 'timed':
      case 'isometric':
        return WorkoutType.mobility;
      case 'sport':
      case 'sports':
        return WorkoutType.sport;
      case 'strength':
      case 'palestra':
      case 'hypertrophy':
      case 'bodyweight':
      default:
        return WorkoutType.strength;
    }
  }

  String get keyName => name;

  /// Chiave di localizzazione per il nome visualizzato.
  String get localizationKey {
    switch (this) {
      case WorkoutType.strength:
        return 'workout_type_strength';
      case WorkoutType.cardio:
        return 'workout_type_cardio';
      case WorkoutType.mobility:
        return 'workout_type_mobility';
      case WorkoutType.sport:
        return 'workout_type_sport';
    }
  }

  bool get isStrength => this == WorkoutType.strength;
  bool get isCardio => this == WorkoutType.cardio;
  bool get isMobility => this == WorkoutType.mobility;
  bool get isSport => this == WorkoutType.sport;

  /// Proprietà dei campi dichiarati per questo tipo
  bool get usesWeightAndReps => this == WorkoutType.strength;
  bool get usesDistance => this == WorkoutType.cardio;
  bool get usesPace => this == WorkoutType.cardio;
  bool get usesDuration => true;
  bool get usesHeartRate => this == WorkoutType.cardio || this == WorkoutType.sport;
  bool get usesRpe => true;
  bool get usesCalories => this == WorkoutType.cardio || this == WorkoutType.sport;
}
