# US-087 — Review: l'invito che lega trainer e cliente (assorbe US-080)

**Verdetto: APPROVATA**

Un rilievo 🔴 trovato **e chiuso** durante questa stessa review (non lasciato aperto per il merge
successivo): un dirottamento possibile del codice pubblico. Nessun altro rilievo bloccante.

---

## Copertura dei criteri

| Criterio (dal backlog, US-087) | Esito | Prova |
|---|---|---|
| L'invito vive in una collezione propria, nessuno scrive sul documento utente altrui | ✅ | `firestore.rules`: `invites`/`invite_codes`, nessuna scrittura su `users/{uid}` in nessun metodo nuovo di `firestore_service.dart` |
| Trovare la persona da invitare non richiede di leggere i documenti utente | ✅ | `createInvite` fa un `get()` su `invite_codes/{code}` (id di documento = codice), mai una query su `users` |
| Un invito ha una scadenza, uno scaduto non lega niente | ✅ | Regola: l'accettazione richiede `resource.data.expiresAt > request.time`. Test Node: *"un invito scaduto non si puo accettare"* |
| Un invito si può rifiutare, un legame si può sciogliere da entrambe le parti | ✅ | Test Node: *"il destinatario puo rifiutare"*, *"un legame accettato si scioglie da entrambe le parti"* |
| Le regole non concedono nulla fra utenti diversi che non passi da un invito accettato | ✅ | Nessuna regola di `sessions`/`programs`/`workouts`/`scheduled_workouts`/`users` referenzia `invites`: restano owner-only, invariate. Test Node: *"un invito accettato non apre la lettura di altre collezioni"* |
| **Un test dimostra che un utente non invitato non vede i dati** | ✅ | Test Node: *"un utente non invitato non legge ne scrive un invito che non lo riguarda"* |
| `firestore.rules` aggiornato nello stesso commit, deploy verificato dall'API | ✅ | Deploy eseguito il 2026-09-13 (`firebase deploy --only firestore:rules --project gymflow-d5d09`) dopo conferma esplicita dell'utente. **Verificato leggendo il ruleset attivo dall'API** (`firestore-tests/verify-deploy.mjs`, non il solo messaggio "Deploy complete!"): release `projects/gymflow-d5d09/releases/cloud.firestore/gymflow`, il ruleset scaricato contiene sia `match /invites/{inviteId}` sia `match /invite_codes/{code}` |
| Il meccanismo regge anche amico↔amico | ✅ | `connect_friend_screen.dart` riscritta ne è l'uso reale, con `relationshipType: friend` |

---

## Rilievi

### 🔴 Trovato e chiuso in questa review: un codice si poteva dirottare

La prima versione della regola `invite_codes` per `update` controllava solo che il **nuovo**
`userId` fosse quello di chi scriveva, non che il documento **appartenesse già a lui**. Chiunque
avrebbe potuto scrivere sul codice pubblico di un altro utente intestandoselo, dirottando chiunque
lo avesse usato per invitare quella persona verso di sé — lo stesso genere di furto che questa
storia esiste per chiudere, spostato di una collezione.

Trovato rileggendo la regola con la domanda della checklist ("cosa può rompersi qui, non cosa
dovrebbe funzionare"), non da un test che falliva: il test **non esisteva ancora**, quindi il
codice sarebbe stato scritto e verificato con un buco reale se non fosse emerso in review. Corretto
aggiungendo `resource.data.userId == request.auth.uid` alla regola di `update`, con un test
(`invite_codes: un codice esistente non si puo dirottare`) che fallisce sulla regola vecchia e passa
su quella nuova — verificato entrambi gli stati prima di committare la correzione.

### 🔵 `acceptedRelationships` non ha un test diretto

La combinazione `Rx.combineLatest2` (inviti dove sono `fromUserId` + dove sono `toUserId`,
entrambi filtrati su `accepted`) non è coperta da un test Dart isolato — solo dalla logica stessa,
semplice, e dal test Node che verifica il comportamento delle regole sottostanti. Il flusso
completo (invita → accetta → compare in "Le tue connessioni" → sciogli) resta da confermare
sull'APK con due account veri, come già dichiarato nel piano.

### 🔵 Un invito duplicato non è impedito

Niente vieta ad A di invitare B due volte: B vedrebbe due inviti in sospeso identici in "Inviti
ricevuti". Non è un criterio della storia (nessun'accettazione criteri lo richiede) e non è un
rischio di sicurezza — solo una rugosità dell'esperienza, lasciata per una storia futura se
l'utente la nota davvero usando l'app.

---

## Fuori scope rilevato nel diff

Coerente con il piano. In più, rimosso durante l'implementazione (non previsto in dettaglio nel
piano, ma diretta conseguenza della semplificazione di `friend_detail_screen.dart` già pianificata):
- `FirestoreService.importSharedProgram` — restava senza chiamanti dopo aver tolto le tab
  calendario/schede, mai state funzionanti (stesse regole negate)
- Le chiavi di localizzazione collegate solo a quel metodo e a quelle tab (`profile_tab`,
  `import_program_*`, `no_history_shared`, `no_programs_shared`, `friend_no_shared_content`,
  `cancel_caps`, `import_caps`, `program_imported_success`), verificate senza altri chiamanti prima
  di toglierle

Nessun'altra modifica fuori dall'elenco del piano. Non toccati, come dichiarato: `user_profile.dart`,
`gym_settings_screen.dart` (`_FriendsAtGym` resta inerte, stessa causa di sempre), le regole di
`sessions`/`programs`/`workouts`/`scheduled_workouts`/`users`, `FirestoreService.getUsers` (ancora
usato da `gym_settings_screen.dart`).

## Regressioni sospette

Nessuna. `ImmersivoSwitch` (rimosso da questo file) resta usato altrove (`appearance_settings_screen.dart`,
`timer_settings_screen.dart`), verificato con grep prima di escludere un rischio di regressione lì.

---

## Checklist adversariale

- **Ogni criterio soddisfatto, con quale prova?** Tabella sopra, ognuno con un test Node o un
  riscontro diretto nel codice
- **Il diff contiene modifiche non previste dal piano?** Sì, dichiarate sopra (import Shared
  Program e le sue stringhe), dirette conseguenze di una rimozione già pianificata
- **Dato assente, lista vuota, utente non autenticato, rete assente?** Liste vuote → stato vuoto o
  widget nascosto, mai un errore. Utente non autenticato → le tre sezioni di inviti non si montano
  (`myUserId == null`). Rete assente: stesso comportamento offline di sempre, non peggiorato né
  migliorato da questa storia
- **Ogni risorsa creata viene rilasciata?** `_codeController` dispose già presente (ereditato,
  verificato ancora corretto); nessun nuovo `StreamSubscription` manuale (tutto via `ref.watch`/
  `StreamBuilder`, gestiti automaticamente)
- **Stream o Future creato dentro `build`?** Sì, in un punto: `StreamBuilder` su
  `_auth.getUserProfileStream()` in `connect_friend_screen.dart` — **preesistente**, stesso schema
  di prima di questa storia, non introdotto qui e fuori scope (riguarda `AuthService`, non
  `FirestoreService`, US-009 più che US-087)
- **Convenzioni di CLAUDE.md rispettate?** Nessun colore letterale, ogni stringa nuova localizzata
  EN+IT, `const` dove possibile, nessuna istanziazione diretta di `FirestoreService` nelle due
  schermate riscritte (resta per `AuthService`, come sopra)
- **Qualcosa può rompere una funzionalità non testata?** Il `firestore.rules` di produzione non
  cambia finché non viene fatto il deploy: fino a quel momento, zero rischio per l'app reale
- **Segreti o percorsi locali nel diff?** Nessuno
- **Comprensibile fra sei mesi?** I commenti nelle regole spiegano il *perché* di ogni ramo, non
  solo il *cosa* — importante qui più che altrove, perché una regola di sicurezza letta senza
  contesto è facile da "semplificare" per errore

---

_Review scritta il 2026-09-13, sul diff `main...feature/US-087-invite-model`. Deploy delle regole
completato ed verificato lo stesso giorno; resta solo il via libera al merge del codice._
