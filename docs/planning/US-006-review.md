# Review US-006

**Verdetto:** APPROVATA
**Data:** 2026-08-06 · **Diff:** 11 file di codice + 1 generato

> Autoverifica con checklist adversariale (modello a singolo agente). Tre rilievi 🟡 emersi durante la verifica e corretti.

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| Lingua e traduzioni esposte da un provider Riverpod | ✅ | `LocalizationNotifier` annotato `@Riverpod(keepAlive: true)`, espone `Localization` immutabile |
| Tutte le schermate aperte si aggiornano al cambio lingua | ✅ | Ogni consumatore usa `ref.watch(localizationNotifierProvider)`: un cambio di stato ricostruisce chi osserva |
| La preferenza persiste tra riavvii | ✅ | Chiave `language_code` invariata: le preferenze già salvate restano valide |
| Nessun file in `lib/src/ui` importa `LocalizationProvider` via `package:provider` | ✅ | Ricerca: zero occorrenze in tutto `lib/` fuori dal file che lo definisce |

## Rilievi

### 🔴 Bloccanti

Nessuno.

### 🟡 Da valutare — tutti emersi in verifica e corretti

1. **Widget annidati non convertiti.** Tre widget vivevano dentro i file convertiti ma erano classi separate: `_AccessControlDialog` in `connect_friend_screen`, `StopwatchView` e `TimerView` in `time_tools_screen`. La conversione della classe principale non li tocca, quindi `ref` risultava non definito al loro interno. Emerso come errore di compilazione, non come comportamento silenzioso.
   **Corretto:** convertiti a `ConsumerStatefulWidget` e `ConsumerWidget`, con la firma di `build` aggiornata.

2. **Collisioni di nome fra i due pacchetti.** `calendar_screen`, `gamification_screen` e `time_tools_screen` usano ancora `Provider.of<FirestoreService>` e `Provider.of<TimerService>` di `package:provider`. Con `flutter_riverpod` importato nello stesso file, `Provider` diventa ambiguo.
   **Corretto:** prefisso `legacy` con commento che ne motiva l'esistenza e ne indica la scadenza (US-007).

3. **Cinque avvisi nuovi rispetto al baseline.** Dopo la migrazione, cinque file importavano `package:provider` senza più usarlo. Il totale era salito da 67 a 72, in violazione della regola "nessun avviso nuovo".
   **Corretto:** import rimossi dopo aver verificato l'assenza di usi residui. Totale tornato a **67, esattamente il baseline**.

### 🔵 Suggerimenti

4. **`t()` restituisce la chiave quando manca la traduzione**, comportamento ereditato e mantenuto. Rende visibile la stringa non tradotta invece di farla sparire — utile per US-026 e US-027, che dovranno trovare le stringhe mancanti.

5. **I dizionari non sono stati toccati.** La modifica è chirurgica sull'involucro: le circa 270 chiavi sono passate intatte. In una migrazione di questa ampiezza, riscriverli avrebbe aggiunto rischio senza alcun beneficio.

## Fuori scope rilevato

Nessuno. Un solo cambiamento non strettamente necessario alla localizzazione: il prefisso `legacy` su `Provider.of<FirestoreService>` e `Provider.of<TimerService>` in tre file. Non è scelta di stile ma condizione per compilare, ed è documentato nel codice.

## Regressioni sospette

| Verifica | Esito |
|---|---|
| `flutter analyze` | **67 issue, zero errori — esattamente il baseline di `main`.** Nessun avviso nuovo |
| `build_runner` | 258 output, nessun conflitto |
| `flutter test` | Fallisce, ma **già su `main`** (`widget_test.dart`, US-032) |
| Esecuzione su emulatore | App avviata, schermata di login resa correttamente |
| Integrità dei dizionari | Preservati dalla modifica chirurgica; nessuna stringa mostra la chiave al posto del testo nella schermata verificata |
| Compatibilità preferenze salvate | Chiave `language_code` invariata |

## Limite della verifica, dichiarato

**Il cambio lingua dalle impostazioni non è stato provato a schermo**: la schermata richiede l'autenticazione, non disponibile in questo ambiente. La schermata di login verificata non contiene stringhe localizzate, quindi non è una prova del percorso di traduzione. Ciò che è dimostrato: l'app compila, si avvia, tutti i consumatori osservano il provider, il percorso di scrittura usa la stessa chiave di prima. La verifica interattiva del cambio lingua resta da fare al primo accesso reale.

## Effetto su US-007

Con US-005 e US-006 concluse, **US-007 ha entrambe le dipendenze soddisfatte** ed è ora eseguibile. Resta l'ultimo consumatore di `package:provider`: `TimerService`. Alla sua migrazione cadranno il `MultiProvider`, tutti i prefissi `legacy` e la dipendenza dal pacchetto.
