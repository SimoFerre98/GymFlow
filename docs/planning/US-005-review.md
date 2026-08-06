# Review US-005

**Verdetto:** APPROVATA
**Data:** 2026-08-06 · **Diff:** 4 file di codice + 1 generato

> Autoverifica con checklist adversariale (modello a singolo agente).

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| Tema esposto da un provider Riverpod | ✅ | `ThemeSettingsNotifier` annotato `@Riverpod(keepAlive: true)`; generato `theme_provider.g.dart` |
| Persistenza tra riavvii | ✅ | `setThemeMode` e `setPrimaryColor` scrivono su `SharedPreferences`, `_restore()` rilegge all'avvio. Chiavi invariate (`theme_mode`, `primary_color`): le preferenze già salvate dagli utenti restano valide |
| Aggiornamento immediato al cambio tema | ✅ | `GymFlowApp` è `ConsumerWidget` e osserva il provider: ogni cambio di stato ricostruisce `MaterialApp` |
| Colore senza `Color.value` | ✅ | Usa `toARGB32()`, nessuna regressione rispetto a US-024 |
| `ThemeProvider` `ChangeNotifier` rimosso | ✅ | Zero occorrenze di `ThemeProvider` in tutto `lib/` |

## Rilievi

### 🔴 Bloccanti

Nessuno.

### 🟡 Da valutare — risolto durante l'implementazione

1. **Collisione di nomi tra i due sistemi.** `package:provider` e `flutter_riverpod` dichiarano entrambi `Provider`, `Consumer` e `ChangeNotifierProvider`. Importarli senza prefisso nello stesso file produce otto errori `ambiguous_import`, emersi al primo `analyze`.

   **Risolto** con `import 'package:provider/provider.dart' as legacy;` in `app.dart` e `settings_screen.dart`, e prefisso sugli usi legacy. Il commento accanto all'import spiega perché esiste e quando sparirà (US-007). È debito temporaneo e dichiarato, non una scelta di stile.

### 🔵 Suggerimenti

2. **`ThemeMode.values.elementAtOrNull(savedMode)`** invece di `ThemeMode.values[savedMode]`: se una versione futura riducesse i valori dell'enum, l'indice salvato potrebbe eccedere. Con `elementAtOrNull` si ottiene `null`, che `copyWith` interpreta come "lascia invariato", quindi il default. Il codice precedente sarebbe andato in eccezione. Aggiunto anche il controllo `savedMode >= 0`.

3. **`keepAlive: true`** è necessario: senza, il provider verrebbe distrutto quando nessuna schermata lo osserva e le preferenze tornerebbero al default cambiando pagina.

## Fuori scope rilevato

Nessuno. Quattro file toccati, tutti previsti. `MultiProvider` resta in `app.dart` con un commento che ne motiva la permanenza: rimuoverlo ora romperebbe localizzazione e timer, ed è compito di US-007.

## Regressioni sospette

| Verifica | Esito |
|---|---|
| `flutter analyze` | 67 issue, **zero errori** — identico a `main` dopo US-024 |
| `build_runner` | 406 output generati, nessun conflitto |
| `flutter test` | Fallisce, ma **già su `main`** (`widget_test.dart`, US-032) |
| Esecuzione su emulatore | App avviata, tema magenta di default applicato correttamente dal nuovo provider |
| Compatibilità delle preferenze salvate | Chiavi di `SharedPreferences` invariate: nessuna migrazione necessaria |

## Limite della verifica, dichiarato

**Il cambio di tema dalle impostazioni non è stato provato a schermo**: la schermata richiede l'autenticazione e la sessione non è disponibile in questo ambiente. La prova prodotta è che il tema di default viene applicato dal nuovo provider e che il percorso di scrittura (`setThemeMode`/`setPrimaryColor` → `SharedPreferences`) è lo stesso di prima, con le stesse chiavi. La verifica interattiva resta da fare al primo accesso reale.
