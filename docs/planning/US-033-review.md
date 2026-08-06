# Review US-033

**Verdetto:** APPROVATA
**Data:** 2026-08-06 · **Diff:** 5 file nuovi, 2 modificati

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| Nota di decisione con almeno tre opzioni | ✅ | ADR-001: package di terze parti, implementazione interna, ibrido |
| Valuta manutenzione, dimensione, copertura, costo di migrazione | ✅ | Tabella con versioni, date, like, download e SDK richiesto per cinque package |
| Token non nativi da una `ThemeExtension` interrogabile | ✅ | `ExpressiveTokens` registrata in entrambi i temi; test lo verificano |
| Token nativi usati direttamente, senza duplicarli | ✅ | `ExpressiveMotion` rimanda a `Durations` ed `Easing`; un test lo blocca |
| Sostituzione futura senza modifiche ai widget consumatori | ✅ | I widget leggono solo `context.expressive`; l'accesso ripiega sui default se l'estensione manca |
| Catalogo accessibile solo in debug | ✅ | `isAvailable` restituisce `kDebugMode`, costante di compilazione: in release l'albero viene eliminato |

## La decisione, e perché non è arbitraria

Il rischio di una storia come questa è scegliere per impressione. I dati che hanno determinato la scelta sono misurati, datati e riportati nell'ADR:

| Package | Versione | Like | Download 30gg | SDK |
|---|---|---|---|---|
| `motor` | 1.1.0 | 238 | 77.299 | ✅ |
| `m3e_collection` | 0.3.7 | 33 | 822 | ✅ |
| `m3e_design` | 0.2.1 | 2 | 3.257 | ✅ |
| `m3e_buttons` | 0.0.5 | — | — | **❌ richiede Dart ^3.11.1, il progetto è su 3.10.7** |

Due fatti hanno deciso: `m3e_buttons` **non è installabile** senza aggiornare l'SDK, e la famiglia `m3e_*` è tutta `0.x` con adozione bassa. `motor` è l'eccezione, con numeri da libreria consolidata: per questo è l'unico raccomandato, e solo per il motion in US-036.

## Rilievi

### 🔴 Bloccanti

Nessuno.

### 🟡 Da valutare — emersi in verifica, corretti

1. **Due test fallivano per il caricamento dei font.** `AppTheme` costruisce la tipografia con `GoogleFonts.outfitTextTheme`, che scarica il font a runtime: nei test la rete non c'è e il caso falliva per un motivo estraneo a ciò che verificava.

   Corretto in due passaggi: `test/flutter_test_config.dart` disattiva il recupero a runtime per tutti i test; i due casi che costruiscono un tema sono diventati `testWidgets`, ambiente che tollera l'eccezione residua di GoogleFonts. La ragione è annotata nel file di test, così chi lo legge non pensa a una svista.

   Il file di configurazione **vale per tutti i test futuri**: US-031 e US-032 non incontreranno lo stesso ostacolo.

2. **Due avvisi nuovi da cast superflui** nei test su `lerp`: la firma restituisce già il tipo concreto. Rimossi; totale tornato a 66.

### 🔵 Suggerimenti

3. **I test verificano il contratto, non i valori.** Che le scale crescano in modo monotono, che le durate provengano dai token nativi, che l'assenza dell'estensione dia i default. Test sui numeri specifici si romperebbero a ogni ritocco senza segnalare nulla di utile; questi si rompono solo quando cambia qualcosa che conta.

4. **Il catalogo mostra le durate animandole.** Un numero in millisecondi non dice nulla su come si percepisce un movimento: le barre percorrono la propria larghezza nel tempo del token, così la differenza fra `quick` ed `emphasized` si vede.

5. **`lerp` non interpola** e restituisce uno dei due estremi. È corretto: i token sono costanti strutturali, non valori animabili. Interpolare un raggio durante un cambio di tema non avrebbe senso.

6. **Il commento su cosa non mettere nei token** è deliberato. Il modo tipico in cui un design system si degrada è diventare il posto dove finisce ogni costante: la barriera va messa prima che accada, non dopo.

## Fuori scope rilevato

Nessuno. Nessun widget esistente è stato modificato per usare i token: applicarli è US-021, US-022 e US-023. Questa storia costruisce solo le fondamenta e le rende osservabili.

## Regressioni sospette

| Verifica | Esito |
|---|---|
| `flutter analyze` | **66 issue, zero errori** — invariato rispetto a `main` |
| `flutter test` | **25 verdi**, da 15: dieci nuovi sul contratto dei token |
| `flutter build apk --debug` | Completa |
| Installazione su dispositivo reale | ✅ **SM-S948B, Android 16** — prima installazione diretta della sessione |
| Interfaccia esistente | Non toccata: registrare una `ThemeExtension` non altera nulla finché nessuno la legge |

## Da provare sul telefono

Il **catalogo del design system**, nel menu laterale in fondo (icona tavolozza, solo in debug). Mostra ruoli colore, spaziature, forme, elevazioni e durate — queste ultime animate dal pulsante in fondo.

Resta aperto anche il controllo rimandato da US-007: l'**overlay del timer**.
