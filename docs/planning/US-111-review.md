# US-111 — Review: Isar come cache locale per allenamenti, programmi, misure e programmazione

**Verdetto: APPROVATA**

L'unico rilievo 🟡 (dati condivisi del calendario) è stato risolto su richiesta esplicita
dell'utente, commit `ef352d9` — vedi esito in fondo alla sezione. Nessun rilievo 🔴. Restano solo i
due criteri che richiedono conferma sull'APK, dichiarati come tali fin dalla prima stesura.

---

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| 4 nuove collection Isar con mapper testati in round-trip (completo, minimo, limite) | ✅ | `lib/src/models/local/local_{workout_template,workout_program,scheduled_workout,body_measurement}.dart` + 4 file di test, 20 test totali (round-trip completo, minimo, set "a cedimento", ogni `ExerciseType`, simmetria locale→dominio→locale) |
| Un provider Riverpod per entità legge da Isar con `.watch(fireImmediately: true)` | ✅ | `workout_provider.dart:20-22`, `program_provider.dart`, `scheduled_workout_provider.dart`, `body_measurement_provider.dart` — stesso schema di `dashboard_provider.dart` |
| Un provider di sync per entità gestisce scritture **e cancellazioni** | ✅ | `sync_provider.dart` — 4 nuovi `Notifier` + correzione di `SessionSync`, che prima non cancellava mai. Provato da `test/sync_provider_deletion_test.dart`: due programmi scritti, uno sparisce dal servizio finto, resta solo l'altro in Isar |
| Le schermate elencate leggono le 4 entità dai nuovi provider, non da Firestore diretto | ✅ | `dashboard_screen.dart`, `calendar_screen.dart`, `program_list_screen.dart`, `program_creator_screen.dart`, `workout_creator_screen.dart`, `body_measurements_screen.dart`, `body_measurements_chart.dart`, `profile_screen.dart` — verificato con `grep` mirato e da `test/service_injection_test.dart` (parte A, invariata) |
| I dati di altri utenti restano fuori dalla cache | ✅ | `calendar_screen.dart`: `getSharedSessions`/`getSharedScheduledWorkouts` restano Firestore diretto. `friend_detail_screen.dart` non è nel diff |
| Comportamento funzionale invariato | ⬜ **Da confermare sull'APK** — dichiarato nel piano, non spuntato: nessuna interazione reale a schermo è stata provata in questa sessione |
| Nessun ricaricamento visibile alla riconnessione | ⬜ **Da confermare sull'APK** — stesso motivo |
| `flutter analyze` senza nuovi avvisi | ✅ **e in calo**: main ha realmente 12 avvisi (`experimental_member_use`, non i 6 `deprecated_member_use` che dice `CLAUDE.md` — disallineamento verificato con un worktree pulito), questo branch ne ha 0. Il calo è dichiarato e motivato: non è codice diventato corretto, è `experimental_member_use` soppresso in `analysis_options.yaml` perché riguarda accessori generati da Isar che nessuno chiama |
| `flutter test` verde, inclusi i mapper | ✅ | 911 test, tutti verdi (`flutter test` completo) |

---

## Rilievi

### 🟡 Il calendario può ora ri-sottoscrivere i dati condivisi più spesso di prima

`calendar_screen.dart` combinava 6 stream in un solo `Rx.combineLatest6`, tutti e sei ricreati ad ogni
rebuild — il problema che la storia risolve per i 4 propri. Ora i 4 propri arrivano da `ref.watch` sui
provider Isar, e i 2 condivisi (amici) restano un `Rx.combineLatest2` costruito dentro `build()`.

Prima, un aggiornamento dei **dati propri** (una nuova sessione, un programma modificato) veniva
gestito **dentro** la stessa sottoscrizione Firestore di lunga durata, senza mai far ripartire il
widget `_CalendarScreenState`. Ora, poiché i dati propri arrivano da `ref.watch`, un loro
aggiornamento fa ripartire `build()` **per intero**, e con esso il `Rx.combineLatest2` dei dati
condivisi — che quindi si ri-sottoscrive più spesso di quanto facesse prima a parità di navigazione
nel calendario (cambio mese esclusivo escluso, che ricreava già tutto).

Non viola nessun criterio di accettazione scritto: i dati condivisi restano esplicitamente fuori
scope, e l'obiettivo — i dati propri non più da Firestore diretto — è raggiunto. Ma è un effetto
collaterale reale del refactor, non solo teorico, ed è esattamente il tipo di problema che US-012
tratta per la parte "amici" del calendario. Segnalo perché **è una decisione che vale la pena
rendere esplicita**: si accetta questa frequenza più alta in attesa di US-012, o si preferisce
un provider dedicato anche per i 2 stream condivisi già in questa storia?

**Esito: risolto in questa storia**, su scelta esplicita dell'utente (commit `ef352d9`). Nuovo
`lib/src/core/providers/shared_calendar_provider.dart` (`SharedCalendarEvents`): la sottoscrizione
ai dati condivisi vive nel provider, non più dentro `build()` del widget. `calendar_screen.dart` non
usa più `Rx.combineLatest2` direttamente (import di `rxdart` rimosso dal file). `flutter analyze` 0
avvisi, `flutter test` 911 verdi dopo la modifica.

### 🔵 Il montaggio vero di `ProgramListScreen` non è più provato da un test automatico

`test/service_injection_test.dart` provava prima l'iniezione **montando** la schermata con un
servizio finto. Isar `.watch()` dentro `testWidgets` si è rivelato inaffidabile in questo ambiente
(dettagli nel piano, sezione "Piano di test"): riscritto come `test()` puro su `ProviderContainer`,
che prova la stessa catena (servizio finto → sync → Isar → provider) senza montare l'albero di
widget. Il montaggio reale resta verificato solo sull'APK — non diversamente da come questa storia
tratta già ogni altro criterio visivo, ma vale la pena saperlo: se in futuro emergesse un modo
affidabile di far avanzare I/O asincrono reale dentro `testWidgets` in questo ambiente (es.
`tester.runAsync` con un tempo di prova più ampio), varrebbe la pena riprovare a montare la
schermata per davvero.

### 🔵 L'istanza Isar dei nuovi test non viene chiusa esplicitamente

`test/service_injection_test.dart` e `test/sync_provider_deletion_test.dart` aprono un'istanza Isar
reale e la lasciano aperta a fine test (solo la directory temporanea viene cancellata via
`addTearDown`). Non causa errori — il processo del test termina comunque e rilascia l'handle — ma
per coerenza un `isar.close()` esplicito sarebbe più pulito. Non l'ho aggiunto perché il pattern
esistente (`IsarDatabase.build()` in produzione) non chiude mai l'istanza nemmeno lui: sarebbe stata
un'asimmetria fra test e codice reale, non un allineamento.

---

## Fuori scope rilevato nel diff

Quattro file non erano nell'elenco originale del piano — aggiunti **durante l'implementazione**,
dichiarati e motivati nel piano stesso (sezione "File toccati", con nota a parte) prima di
proseguire, non scoperti ora in review:

- `analysis_options.yaml` — sopprime `experimental_member_use`, altrimenti il conteggio degli avvisi
  sarebbe salito da 12 a 60 per un effetto collaterale del codice generato da Isar
- `test/service_injection_test.dart` — adattato, vedi rilievo 🔵 sopra
- `test/sync_provider_deletion_test.dart` — nuovo, prova le cancellazioni (criterio di accettazione
  esplicito)
- `.gitignore` — ignora `libisar.so`, scaricato nella working directory dai due test sopra
- `lib/src/core/providers/shared_calendar_provider.dart` — aggiunto **dopo** questa review, per
  risolvere il rilievo 🟡 sotto, su richiesta esplicita dell'utente

Nessun'altra modifica fuori dall'elenco.

## Regressioni sospette

Nessuna trovata. Verificato in particolare:
- Ordinamento: nessun `orderBy` nuovo dove Firestore non ne aveva uno (allenamenti, allenamenti
  programmati); mantenuto dove c'era (programmi per `createdAt` decrescente, misure per `date`
  decrescente)
- Risorse: nessun `StreamSubscription`/`TextEditingController` nuovo non rilasciato; i sync provider
  cancellano la sottoscrizione in `ref.onDispose`, come `SessionSync` già faceva
- `friend_detail_screen.dart` e le due query di dati condivisi (`getSharedSessions`,
  `getSharedScheduledWorkouts`): non toccati, restano su Firestore diretto come da piano

---

## Checklist adversariale

- **Utente non autenticato**: ogni nuovo provider di lettura fa `if (userId == null) { yield []; return; }`, stesso schema di `DashboardSessions`
- **Lista vuota**: coperta esplicitamente dai test dei mapper e dal test di iniezione (il servizio finto restituisce `[]`)
- **Dato assente / rete assente**: le scritture restano su Firestore, che mette già in coda offline (`persistenceEnabled: true`); non è stato aggiunto un percorso di scrittura locale-prima, deliberatamente (vedi "Fuori scope" del piano)
- **`Stream`/`Future` creato dentro `build`**: eliminato per le 4 entità nelle 8 schermate elencate, e — dopo la correzione del rilievo 🟡 — anche per i 2 stream condivisi di `calendar_screen.dart`, ora dentro `SharedCalendarEvents`
- **Convenzioni di `CLAUDE.md`**: nessun colore letterale, nessuna stringa fuori localizzazione (nessuna stringa nuova), `const` dove il compilatore lo consente, nessun servizio istanziato direttamente nelle schermate per le 4 entità trattate
- **Segreti o percorsi locali nel diff**: nessuno
- **Comprensibilità fra sei mesi**: i sync provider sono quattro blocchi quasi identici invece di un'astrazione generica — scelta motivata nel piano (coerenza con lo stile esistente, niente astrazione con un solo consumatore reale prima di questa storia)

---

_Review scritta il 2026-09-12, sul diff `main...feature/US-111-isar-local-first-cache`_
