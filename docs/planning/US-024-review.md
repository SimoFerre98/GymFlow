# Review US-024

**Verdetto:** APPROVATA
**Data:** 2026-08-06 · **Diff esaminato:** 23 file, 105 sostituzioni

> Autoverifica con checklist adversariale (modello a singolo agente).

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| 95 `withOpacity` sostituite senza perdita di precisione | ✅ | Zero `withOpacity` residue; 95 `withValues(alpha:`. Conteggio pre/post coincidente |
| `background`/`onBackground` sostituiti da `surface`/`onSurface` | ✅ | Rimossi da entrambi i `ColorScheme`. `surface` e `onSurface` erano già valorizzati con gli stessi colori: nessun cambiamento di resa |
| `MaterialStateProperty` → `WidgetStateProperty` | ✅ | Due occorrenze in `app_theme.dart`, entrambe convertite |
| `Color.value` e `activeColor` sostituiti | ✅ | `toARGB32()` in `theme_provider` e nel confronto di `settings_screen`; `activeThumbColor` sullo `SwitchListTile` |
| Nessun avviso `deprecated_member_use` sulle API trattate | ✅ | `flutter analyze` filtrato sulle cinque famiglie: zero righe |
| Colori identici a prima | ✅ | Schermata di login su emulatore: magenta, sfondo e bordi invariati |

**Effetto complessivo: da 172 a 67 avvisi, −105.** Zero errori.

## Rilievi

### 🔴 Bloccanti

Nessuno.

### 🟡 Da valutare

Nessuno.

### 🔵 Suggerimenti

1. **La sostituzione è stata eseguita da uno script**, non a mano. La correttezza non poggia sulla fiducia nello script ma su tre riscontri indipendenti: conteggio pre/post coincidente (95 = 95), zero errori di compilazione dall'analyzer, resa visiva invariata sull'emulatore. Lo script usa parsing bilanciato delle parentesi, non una regex ingenua, quindi gestisce correttamente le espressioni annidate come `Theme.of(context).primaryColor.withOpacity(0.3)`.

2. **Rimane un `activeColor` in `main_screen.dart:48`**, deliberatamente non toccato: appartiene a `GNav` del package `google_nav_bar` e non è deprecato. Confonderlo con quello di `Switch` avrebbe rotto la barra di navigazione.

3. **`toARGB32()` invece di `==` diretto** nel confronto dei preset colore. `Color ==` confronta anche lo spazio colore, che in Flutter recenti è un campo a sé: il confronto esplicito sul valore ARGB è più prevedibile e mantiene esattamente la semantica precedente di `.value == .value`.

## Fuori scope rilevato

Nessuno. Tutti i 23 file toccati rientrano nelle categorie previste dal piano. Nessuna modifica a logica, layout o comportamento: le sostituzioni sono tutte semanticamente equivalenti per costruzione.

## Regressioni sospette

| Verifica | Esito |
|---|---|
| `flutter analyze` | 67 issue (da 172), **zero errori**. Nessun avviso nuovo introdotto |
| Rimozione di `background`/`onBackground` | Ricerca preventiva su tutto `lib/`: zero consumatori fuori da `app_theme.dart`. Nessun errore di compilazione conferma l'accertamento |
| `flutter test` | Fallisce, ma **già su `main`**: `widget_test.dart` predefinito, tracciato in US-032 |
| Esecuzione su emulatore | App avviata, schermata di login resa correttamente, nessuna eccezione |
| Riscontro visivo | Magenta primario, sfondo chiaro, bordi dei campi e ombra del pulsante identici alla resa precedente |

## Nota per US-033

Questa storia sblocca US-033. Il tema è ora libero da API in via di rimozione: i token Material 3 Expressive possono essere costruiti sopra `ColorScheme` e `WidgetStateProperty` correnti senza debito immediato.
