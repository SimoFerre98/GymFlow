# US-112 — Review

**Verdetto: APPROVATA**

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| `app_drawer.dart` non esiste più | ✅ | `git status` / diff: file cancellato, 215 righe rimosse |
| Nessun test referenzia più il file cancellato | ✅ | `grep -rn "app_drawer\|AppDrawer" lib/ test/` trova solo un commento esplicativo in `statistics_screen_test.dart`, nessun riferimento eseguibile |
| `expressive_tokens.dart` resta | ✅ | non toccato dal diff — verificato che è ancora importato da 4 file (`home_hero_card.dart`, `lifting_icon_button.dart`, `workout_receipt.dart`, `workout_type_pie_chart.dart`), fuori scope come da piano |
| `flutter analyze` nessun avviso nuovo | ✅ | `No issues found!` — main è già a 0, nessuna variazione |
| `flutter test` verde | ✅ | 912/912, rieseguito anche dopo il rebase su `main` aggiornato |

## Checklist adversariale

- **Ogni criterio è soddisfatto, con quale prova?** Tabella sopra — nessuno per "si presume di sì".
- **Il diff contiene modifiche non previste dal piano?** No. Cinque file, tutti previsti: il widget cancellato, i due test aggiornati, il piano e la voce di backlog. Nessun altro file toccato — verificato con `git diff main...HEAD --stat` dopo il rebase.
- **Regressione di navigazione?** È il rischio principale di una cancellazione di questo tipo, e la checklist lo tratta esplicitamente: ogni ex-destinazione del cassetto (Home, Impostazioni, Obiettivi, Achievements, Cronometro, Connetti Amico, più Statistiche/Esercizi già spostate da US-103) è stata verificata raggiungibile da un altro punto **prima** di cancellare il file, non dopo — `main_screen.dart` (tab Impostazioni) e `_ShortcutRow` in `dashboard_screen.dart` (righe 673-698). Nessuna are stata trovata orfana.
- **Dato assente, lista vuota, utente non autenticato, rete assente?** Non applicabile: la storia rimuove codice, non ne aggiunge — non c'è un percorso a runtime nuovo da mettere alla prova con input degeneri.
- **Risorse rilasciate — controller, sottoscrizioni, timer, stream?** Non applicabile, stesso motivo: `AppDrawer` non aveva controller propri (era un `ConsumerWidget` stateless), e il file è cancellato, non refactorizzato.
- **`Stream`/`Future` dentro `build`, effetti collaterali in `build`?** Non applicabile al diff.
- **Le convenzioni di `CLAUDE.md` sono rispettate?** Sì per la parte che riguarda questa storia: nessuna dipendenza aggiunta, nessuna regola Firestore toccata, commit in italiano con riferimento a US-112, nessuna attribuzione ad AI. `expressive_tokens.dart` resta — coerente con la convenzione "i token vivono in `immersivo_tokens.dart`" solo nel senso che non se ne è aggiunto un nuovo uso: rimuoverlo del tutto era esplicitamente fuori scope, deciso con l'utente.
- **Qualcosa può rompere una funzionalità non testata?** Il rischio più concreto è una chiave di localizzazione diventata orfana (`gymflow_user`, tra le altre usate solo da `app_drawer.dart`). Non rompe nulla — una voce di mappa inutilizzata non produce errori né avvisi — ma è debito non quantificato: dichiarato nel piano, non verificato riga per riga.
- **Segreti, credenziali o percorsi locali nel diff?** No — verificato a occhio, il diff è cancellazione di un widget e aggiornamento di due asserzioni di test.
- **Il codice resta comprensibile a chi lo rilegge fra sei mesi?** Il commento aggiunto in `statistics_screen_test.dart` spiega perché il test non legge più `app_drawer.dart`, con riferimento a US-112. Il piano e la voce di backlog portano la ricostruzione storica completa (git history, commit del recupero da APK) per chi si chiedesse "perché era lì e perché non c'è più".

## Fuori scope rilevato

Nessuno oltre a quanto già dichiarato nel piano: `expressive_tokens.dart` e i quattro widget che lo importano ancora (`home_hero_card.dart`, `lifting_icon_button.dart`, `workout_receipt.dart`, `workout_type_pie_chart.dart`) restano — nessuno dei quattro risulta raggiunto da una schermata viva, ma è debito segnalato, non di questa storia. Lo stato di US-103 (`🟡 IN CORSO` con un criterio non più verificabile) è segnalato nel piano e nella voce di backlog, non corretto qui.

## Regressioni sospette

Nessuna trovata. Il rischio principale (una destinazione del cassetto diventata irraggiungibile) è stato verificato **prima** dell'implementazione, non dedotto a posteriori — vedi sezione dedicata nel piano e sopra nella checklist.

## Limiti dichiarati

- **La review è un'autoverifica**, non un giudizio indipendente (principio di `WORKFLOW.md`): chi ha scritto il codice è anche chi lo rivede. Storia di dimensione minima (1 punto, cancellazione più due asserzioni di test), non tra quelle per cui vale la pena chiedere una review delegata.
- **Le chiavi di localizzazione potenzialmente orfane non sono state verificate una per una.** Dichiarato come rischio accettato nel piano, non come criterio soddisfatto.
- **Nessun criterio di questa storia richiede prova sul telefono.** La storia rimuove codice irraggiungibile: non c'è un comportamento a schermo nuovo da confermare. L'APK di verifica (Fase 4) è stato comunque costruito con successo.
