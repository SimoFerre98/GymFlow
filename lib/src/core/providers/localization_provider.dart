import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'localization_provider.g.dart';

/// Traduzioni per la lingua corrente.
///
/// Immutabile: cambiare lingua produce una nuova istanza, non muta questa.
@immutable
class Localization {
  const Localization(this.locale);

  final Locale locale;

  /// Traduce [key]. Se manca nel dizionario restituisce la chiave stessa,
  /// cosi la stringa non tradotta e visibile invece di sparire.
  String t(String key) {
    final table = locale.languageCode == 'it' ? _it : _en;
    return table[key] ?? key;
  }

  static final Map<String, String> _en = {
    'settings_title': 'Settings',
    'account_section': 'ACCOUNT',
    'my_profile': 'My Profile',
    'body_measurements': 'Body Measurements',
    'subscription': 'Subscription',
    'gym_settings_section': 'GYM SETTINGS',
    'gym_details': 'Gym Details',
    'gym_location': 'Gym Location',
    'integrations_section': 'INTEGRATIONS',
    'preferences_section': 'PREFERENCES',
    'notifications': 'Notifications',
    'app_theme': 'App Theme',
    'language': 'Language',
    'primary_color': 'Primary Color',
    'load_default_data': 'Load Default Data',
    'sign_out': 'Sign Out',
    'guest_user': 'Guest User',
    'track_progress': 'Track your progress',
    'free_plan': 'Free Plan',
    'expires': 'Expires',
    'set_name_address': 'Set Name & Address',
    'location_pinned': 'Location pinned',
    'tap_to_set': 'Tap to set location',
    'sync_steps': 'Sync steps, calories, and more',
    'permissions_granted': 'Permissions granted!',
    'default_loaded': 'Default exercises loaded!',
    'gym_info_saved': 'Gym Info Saved!',
    'system': 'System',
    'light': 'Light',
    'dark': 'Dark',
    'select_language': 'Select Language',
    'home': 'Home',
    'achievements': 'Achievements',
    'stopwatch_menu': 'Stopwatch',
    'connect_friend': 'Connect Friend',
    'stopwatch_tab': 'Stopwatch',
    'timer_tab': 'Timer',
    'lap': 'Lap',
    'reset': 'Reset',
    'pause': 'Pause',
    'start': 'Start',
    'tap_to_edit': 'Tap to edit',

    // Calendar
    'calendar_title': 'Calendar',
    'select_day': 'Select a day',
    'no_workouts_day': 'No workouts this day',
    'schedule_workout': 'Schedule Workout',
    'schedule_workout_btn': 'Schedule Workout',
    'delete_event_title': 'Delete Event?',
    'delete_event_body': 'This action cannot be undone.',
    'sync_calendar': 'Sync to Calendar',
    'workout_label': 'Workout:',
    'scheduled_using': 'Scheduled using GymFlow',
    'select_workout_schedule': 'Select Workout to Schedule',
    'no_workouts_found': 'No workouts found. Create one first!',

    // Connect Friend
    'connect_friends_title': 'Connect with Friends',
    'your_friend_code': 'Your Friend Code',
    'share_code_msg': 'Share this code with your friends so they can add you!',
    'enter_friend_code': 'Enter Friend Code',
    'friend_code_hint': 'e.g. A1B2C3',
    'connect_btn': 'CONNECT',
    'your_friends_list': 'Your Friends',
    'no_friends_msg': 'No friends yet. Add some!',
    'privacy_settings': 'Privacy:',
    'share_calendar': 'Share Calendar',
    'share_calendar_sub': 'Allow viewing your workout history',
    'share_programs': 'Share Programs',
    'share_programs_sub': 'Allow viewing/copying your programs',
    'done': 'DONE',
    'cant_add_self': "You can't add yourself!",
    'friend_connected': 'Friend connected successfully!',
    'friend_not_found': 'Friend not found with code:',

    // Program List
    'my_programs_title': 'My Programs',
    'no_programs_yet': 'No Programs Yet',
    'create_program_msg': 'Create a workout program (Scheda) to get started',
    'delete': 'Delete',
    'delete_program_title': 'Delete Program?',
    'delete_program_body_prefix': 'Are you sure you want to delete',
    'program_deleted': 'Program deleted',
    'active_caps': 'ACTIVE',
    'ongoing': 'Ongoing',
    'no_dates': 'No dates set',
    'days_label': 'Days',

    // Dashboard
    'dashboard_title': 'Dashboard',
    'overview_tab': 'Overview',
    'history_tab': 'History',
    'workouts_label': 'Workouts',
    'streak_label': 'Streak',
    'steps_label': 'Steps',
    'active_cal_label': 'Active Cal',
    'heart_rate_label': 'Heart Rate',
    'sleep_label': 'Sleep',
    'volume_label': 'Volume',
    'avg_intensity_label': 'Avg Intensity',
    'my_gym_label': 'My Gym',
    'workout_activity_chart': 'Workout Activity',
    'body_progress_chart': 'Body Progress',
    'workout_types_chart': 'Workout Types',
    'no_workouts_history': 'No workouts yet',
    'start_training_msg': 'Start training to see your history here.',
    'quick_start': 'Quick Start',

    // Gamification
    'achievements_title': 'Achievements',
    'monthly_challenges': 'Monthly Challenges',
    'step_master': 'Step Master',
    'reach_steps_goal': 'Reach 180k steps',
    'calorie_burn': 'Calorie Burn',
    'goal_label': 'Goal:',
    'distance_label': 'Distance',
    'badges_section': 'Badges',

    // Badge Details
    'badge_name_first_step': 'First Step',
    'badge_desc_first_step': 'Complete your first workout',
    'badge_name_getting_serious': 'Getting Serious',
    'badge_desc_getting_serious': 'Complete 10 workouts',
    'badge_name_gym_rat': 'Gym Rat',
    'badge_desc_gym_rat': 'Complete 50 workouts',
    'badge_name_warming_up': 'Warming Up',
    'badge_desc_warming_up': 'Reach a 3-day streak',
    'badge_name_unstoppable': 'Unstoppable',
    'badge_desc_unstoppable': 'Reach a 7-day streak',
    'badge_name_social_butterfly': 'Social Butterfly',
    'badge_desc_social_butterfly': 'Connect with a friend',

    // Set editor (US-046)
    'set_label': 'Set',
    'previous_set': 'Previous set',
    'load_label': 'Load',
    'reps_label': 'Reps',
    'rpe_full_label': 'Perceived effort',
    'close_set': 'Close the set',

    // Missing strings found on screen: `t` returns the key when it is absent,
    // so these were being displayed as `rpe_label`, `cancel`, and so on.
    'cancel': 'Cancel',
    'login_required': 'Sign in to continue',
    'completed_at': 'Completed at',
    'scheduled_for': 'Scheduled for',
    'friend_label': '(friend)',
    'event_deleted': 'Event deleted',
    'no_workouts_create_first': 'No workouts yet. Create one first!',
    'error_connecting': 'Error while connecting',
    'error_deleting': 'Error while deleting',
    'gymflow_user': 'GymFlow user',
    'rpe_label': 'Avg Effort',

    // Exercises
    'exercises_menu': 'Exercises',
    'exercises_title': 'Exercise library',
    'exercises_search': 'Search exercise',
    'exercises_empty': 'No exercises yet. Load the curated library from Settings, or add your own.',
    'video_available': 'Execution video available',

    // Execution video
    'video_none': 'No execution video for this exercise yet.',
    'video_search_only':
        'No specific video has been picked for this exercise yet. You can search for it on YouTube.',
    'video_open_search': 'Search on YouTube',
    'video_unavailable':
        'This video is no longer available, or its author does not allow it to be played here.',
    'video_offline':
        'Watching the video needs a connection. Check your network and try again.',
    'video_open_failed': 'Could not open YouTube',
  };

  static final Map<String, String> _it = {
    'settings_title': 'Impostazioni',
    'account_section': 'ACCOUNT',
    'my_profile': 'Il Mio Profilo',
    'body_measurements': 'Misure Corporee',
    'subscription': 'Abbonamento',
    'gym_settings_section': 'IMPOSTAZIONI PALESTRA',
    'gym_details': 'Dettagli Palestra',
    'gym_location': 'Posizione Palestra',
    'integrations_section': 'INTEGRAZIONI',
    'preferences_section': 'PREFERENZE',
    'notifications': 'Notifiche',
    'app_theme': 'Tema App',
    'language': 'Lingua',
    'primary_color': 'Colore Principale',
    'load_default_data': 'Carica Dati Default',
    'sign_out': 'Esci',
    'guest_user': 'Utente Ospite',
    'track_progress': 'Traccia i tuoi progressi',
    'free_plan': 'Piano Gratuito',
    'expires': 'Scade il',
    'set_name_address': 'Imposta Nome e Indirizzo',
    'location_pinned': 'Posizione salvata',
    'tap_to_set': 'Tocca per impostare',
    'sync_steps': 'Sincronizza passi, calorie, etc.',
    'permissions_granted': 'Permessi concessi!',
    'default_loaded': 'Esercizi caricati!',
    'gym_info_saved': 'Info Palestra Salvate!',
    'system': 'Sistema',
    'light': 'Chiaro',
    'dark': 'Scuro',
    'select_language': 'Seleziona Lingua',
    'home': 'Home',
    'achievements': 'Obiettivi',
    'stopwatch_menu': 'Cronometro',
    'connect_friend': 'Connetti Amico',
    'stopwatch_tab': 'Cronometro',
    'timer_tab': 'Timer',
    'lap': 'Parziale',
    'reset': 'Azzera',
    'pause': 'Pausa',
    'start': 'Avvia',
    'tap_to_edit': 'Tocca per modificare',

    // Calendar
    'calendar_title': 'Calendario',
    'select_day': 'Seleziona un giorno',
    'no_workouts_day': 'Nessun allenamento',
    'schedule_workout': 'Programma Allenamento',
    'schedule_workout_btn': 'Programma Allenamento',
    'delete_event_title': 'Elimina Evento?',
    'delete_event_body': 'Questa azione non può essere annullata.',
    'sync_calendar': 'Sincronizza con Calendario',
    'workout_label': 'Allenamento:',
    'scheduled_using': 'Programmato con GymFlow',
    'select_workout_schedule': 'Seleziona Allenamento da Programmare',
    'no_workouts_found': 'Nessun allenamento trovato. Creane uno prima!',

    // Connect Friend
    'connect_friends_title': 'Connetti Amici',
    'your_friend_code': 'Il tuo Codice Amico',
    'share_code_msg':
        'Condividi questo codice con i tuoi amici per farti aggiungere!',
    'enter_friend_code': 'Inserisci Codice Amico',
    'friend_code_hint': 'es. A1B2C3',
    'connect_btn': 'CONNETTI',
    'your_friends_list': 'I tuoi Amici',
    'no_friends_msg': 'Ancora nessun amico. Aggiungine qualcuno!',
    'privacy_settings': 'Privacy:',
    'share_calendar': 'Condividi Calendario',
    'share_calendar_sub': 'Permetti di vedere la tua cronologia',
    'share_programs': 'Condividi Schede',
    'share_programs_sub': 'Permetti di vedere/copiare le tue schede',
    'done': 'FATTO',
    'cant_add_self': 'Non puoi aggiungere te stesso!',
    'friend_connected': 'Amico connesso con successo!',
    'friend_not_found': 'Amico non trovato con codice:',

    // Program List
    'my_programs_title': 'Le mie Schede',
    'no_programs_yet': 'Nessuna Scheda',
    'create_program_msg': 'Crea una scheda di allenamento per iniziare',
    'delete': 'Elimina',
    'delete_program_title': 'Elimina Scheda?',
    'delete_program_body_prefix': 'Sei sicuro di voler eliminare',
    'program_deleted': 'Scheda eliminata',
    'active_caps': 'ATTIVA',
    'ongoing': 'In corso',
    'no_dates': 'Nessuna data',
    'days_label': 'Giorni',

    // Dashboard
    'dashboard_title': 'Dashboard',
    'overview_tab': 'Panoramica',
    'history_tab': 'Storico',
    'workouts_label': 'Allenamenti',
    'streak_label': 'Streak',
    'steps_label': 'Passi',
    'active_cal_label': 'Calorie Attive',
    'heart_rate_label': 'Battito Card.',
    'sleep_label': 'Sonno',
    'volume_label': 'Volume',
    'avg_intensity_label': 'Intensità Media',
    'my_gym_label': 'La mia Palestra',
    'workout_activity_chart': 'Attività Allenamento',
    'body_progress_chart': 'Progresso Corporeo',
    'workout_types_chart': 'Tipi di Allenamento',
    'no_workouts_history': 'Nessun allenamento ancora',
    'start_training_msg': 'Inizia ad allenarti per vedere il tuo storico qui.',
    'quick_start': 'Avvio Rapido',

    // Gamification
    'achievements_title': 'Obiettivi',
    'monthly_challenges': 'Sfide Mensili',
    'step_master': 'Signore dei Passi',
    'reach_steps_goal': 'Raggiungi 180k passi',
    'calorie_burn': 'Calorie Bruciate',
    'goal_label': 'Obiettivo:',
    'distance_label': 'Distanza',
    'badges_section': 'Badge',

    // Badge Details
    'badge_name_first_step': 'Primo Passo',
    'badge_desc_first_step': 'Completa il tuo primo allenamento',
    'badge_name_getting_serious': 'Si fa sul serio',
    'badge_desc_getting_serious': 'Completa 10 allenamenti',
    'badge_name_gym_rat': 'Topo da Palestra',
    'badge_desc_gym_rat': 'Completa 50 allenamenti',
    'badge_name_warming_up': 'Riscaldamento',
    'badge_desc_warming_up': 'Raggiungi una serie di 3 giorni',
    'badge_name_unstoppable': 'Inarrestabile',
    'badge_desc_unstoppable': 'Raggiungi una serie di 7 giorni',
    'badge_name_social_butterfly': 'Animale Sociale',
    'badge_desc_social_butterfly': 'Connettiti con un amico',

    // Editor della serie (US-046)
    'set_label': 'Serie',
    'previous_set': 'Serie precedente',
    'load_label': 'Carico',
    'reps_label': 'Ripetizioni',
    'rpe_full_label': 'Sforzo percepito',
    'close_set': 'Chiudi la serie',

    // Stringhe mancanti trovate a schermo: `t` restituisce la chiave quando
    // manca, quindi al loro posto si leggeva `rpe_label`, `cancel`, e cosi via.
    'cancel': 'Annulla',
    'login_required': 'Accedi per continuare',
    'completed_at': 'Completato alle',
    'scheduled_for': 'Programmato per le',
    'friend_label': '(amico)',
    'event_deleted': 'Evento eliminato',
    'no_workouts_create_first': 'Nessun allenamento. Creane uno prima!',
    'error_connecting': 'Errore durante la connessione',
    'error_deleting': "Errore durante l'eliminazione",
    'gymflow_user': 'Utente GymFlow',
    // Il valore che accompagna viene da calculateAverageRPE: e lo sforzo
    // percepito, non l'intensita, che e gia un'altra voce.
    'rpe_label': 'Sforzo medio',

    // Esercizi
    'exercises_menu': 'Esercizi',
    'exercises_title': 'Libreria esercizi',
    'exercises_search': 'Cerca esercizio',
    'exercises_empty': 'Nessun esercizio. Carica la libreria dalle impostazioni, oppure creane uno tuo.',
    'video_available': "Video dell'esecuzione disponibile",

    // Video dell'esecuzione
    'video_none': "Per questo esercizio non c'e ancora un video.",
    'video_search_only':
        "Per questo esercizio non e ancora stato scelto un video preciso. Puoi cercarlo su YouTube.",
    'video_open_search': 'Cerca su YouTube',
    'video_unavailable':
        "Questo video non e piu disponibile, oppure il suo autore non ne permette la visione qui.",
    'video_offline':
        'Per vedere il video serve una connessione. Controlla la rete e riprova.',
    'video_open_failed': 'Non e stato possibile aprire YouTube',
  };
}

/// Espone la lingua corrente e le sue traduzioni, persistendo la scelta.
///
/// Come per il tema, [build] restituisce subito il default e avvia la lettura
/// da `SharedPreferences`: nessuno stato di caricamento da gestire nella UI.
@Riverpod(keepAlive: true)
class LocalizationNotifier extends _$LocalizationNotifier {
  static const _languageKey = 'language_code';
  static const _defaultLocale = Locale('it');

  @override
  Localization build() {
    _restore();
    return const Localization(_defaultLocale);
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_languageKey);
    if (savedCode != null && savedCode.isNotEmpty) {
      state = Localization(Locale(savedCode));
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = Localization(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);
  }
}
