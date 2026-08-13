# US-FIX — Persistenza Sessione Attiva, Riprendi Allenamento e Timer Dinamico

**Epic:** EP-010 · **Priority:** HIGH
**Branch:** `feature/active-session-persistence-and-timer-fix`

---

## Contesto

L'utente ha segnalato tre comportamenti critici:
1. **Riprendi Allenamento:** Il pulsante "Riprendi allenamento" sulla Home (nella `HomeHeroCard`) mostrava sempre il primo allenamento della scheda attiva, ignorando l'allenamento che l'utente aveva effettivamente avviato.
2. **Timer Dinamico:** Cambiando la durata predefinita del recupero nelle Impostazioni a sessione in corso, le serie successive continuavano a usare la vecchia impostazione anziché quella appena salvata.
3. **Reset della Durata Allenamento:** Il timer in basso dell'allenamento in corso (`Stopwatch` locale di `ActiveSessionScreen`) si azzerava uscendo e rientrando dalla schermata o dall'app.

---

## Soluzione Tecnico-Architetturale

1. **`ActiveSessionNotifier` (`lib/src/core/providers/active_session_provider.dart`):**
   - Un provider globale Riverpod `keepAlive: true` gestisce la sessione di allenamento attiva.
   - Conserva `startedAt` (`DateTime`), l'istanza del `WorkoutTemplate` in corso e la lista aggiornata di `WorkoutExercise` con le relative serie completate.
   - Calcola la durata dell'allenamento come `DateTime.now().difference(startedAt!)`, garantendo continuità assoluta del conteggio del tempo anche in caso di chiusura o riapertura dell'app.

2. **Aggiornamento `HomeHeroCard` (`dashboard_screen.dart`):**
   - Legge `activeSessionNotifierProvider`. Se una sessione è attiva, mostra il nome esatto dell'allenamento in corso e premendo "Riprendi allenamento" riapre la sessione attiva nello stato esatto in cui era.

3. **Lettura Dinamica Impostazioni Timer (`active_session_screen.dart`):**
   - `_onSetCompleted` legge `ref.read(timerSettingsNotifierProvider)` ad ogni tocco sulla checkbox delle serie, assicurando che qualsiasi modifica effettuata nelle Impostazioni si rifletta immediatamente sulle serie successive.
