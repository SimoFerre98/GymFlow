# Review US-092

**Verdetto: APPROVATA CON RISERVE** — nessun rilievo bloccante sul codice. Le riserve sono due
condizioni prima di dire «finita»: la **prova sul telefono con due account** (non fatta, il telefono
non è raggiungibile da `adb`) e due decisioni di prodotto segnalate sotto. **Il deploy delle regole è
fatto** (2026-10-17, dopo il tuo via libera) e verificato dall'API: vedi «Deploy».

La review è un'**autoverifica**: chi ha scritto il codice è anche chi lo rivede. Per compensare sono
partito dal diff (`git diff main...HEAD`, 14 file) e ho **rotto di proposito le regole e il codice**
per vedere i test diventare rossi — vedi «Cosa ha trovato la rottura di proposito».

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| Il cliente vede chi lo segue e **cosa** vede, in parole | ⬜ **Da confermare sull'APK** | Implementato: riga in elenco («Ti segue come trainer» + «Vede: …») e sezione nel dettaglio. Provato solo `consentSummaryKey` (4 combinazioni, `test/consent_test.dart`) e il foglio come widget. **Non provato**: che `connect_friend_screen.dart` mostri la riga giusta con un consenso vero (la schermata istanzia Firebase, non si monta in un test — debito US-008) |
| Le categorie si concedono e si revocano una per una | ✅ regole · ⬜ giro a schermo | Emulatore: con solo `sessions` il trainer legge le sessioni e **non** le misure, e viceversa; la scrittura a percorso `grants.sessions` usata dall'app tocca una categoria senza muovere l'altra. Widget: ogni interruttore chiama solo la propria categoria |
| La revoca ha effetto **nelle regole**, un test dimostra che la lettura viene negata | ✅ sull'emulatore · ✅ regole pubblicate (testo identico, verificato dall'API) | Test «la revoca vale subito»: la **stessa query** che passava ora è negata, per le sessioni e poi per le misure |
| Sciogliere il legame revoca tutto, il trainer smette di comparire | ✅ sull'emulatore | Due casi: batch completo (invito `revoked` + consenso cancellato) → negato; **solo** invito `revoked` con consenso rimasto → negato comunque (la cintura). La lista dei legami esclude già gli `revoked` (US-087) |
| Accettando, il cliente vede cosa concede **prima** di confermare | ✅ foglio · ⬜ cablaggio | Widget: il foglio mostra titolo e descrizione di entrambe le categorie e cosa resta privato, gli interruttori partono spenti, «Annulla» restituisce `null` e «Accetta» restituisce ciò che è acceso. **Non provato**: che il tocco su «Accetta» apra il foglio e che la scrittura avvenga solo dopo la conferma |

## Cosa ha trovato la rottura di proposito

Rotte una alla volta le «cinture» delle regole (otto mutazioni) e tre punti del codice Dart, ogni
volta con un test che doveva diventare rosso.

- **Un buco nei test, non nelle regole.** Togliendo `clientUserId == request.auth.uid` dalla creazione
  del consenso **nessun test diventava rosso**. Il controllo sembrava ridondante rispetto a
  `toUserId == request.auth.uid`, e non lo è: un cliente con un invito vero da un trainer poteva
  scrivere `consents/t_x` dichiarando **un altro utente** come cliente, e il trainer avrebbe letto i
  dati di quell'utente. Le regole erano giuste; mancava il test. Aggiunto («un cliente non può
  falsificarne uno per i dati di un altro utente»), e ora la mutazione lo fa diventare rosso.
- Una mutazione sulle sessioni aveva colpito per errore `workouts` (ancoraggio sbagliato nel mio
  script): rifatta sul punto giusto, e rossa.
- La suite era verde al primo colpo: per questo ho voluto la rottura, non l'ho presa per prova.

## Rilievi

### 🔴 Bloccanti
Nessuno sul codice.

**Una condizione operativa, ora soddisfatta:** senza le regole pubblicate, l'accettazione di un invito
`trainer_client` dall'APK fallirebbe con permesso negato. Le regole sono pubblicate (vedi «Deploy»),
quindi l'APK si può provare.

### 🟡 Da valutare — decisioni tue
1. **Gli interruttori partono spenti.** Chi accetta e non accende nulla crea un legame in cui il
   trainer non vede niente, e l'elenco lo dice a parole («Non vede ancora nulla»). È la scelta più
   protettiva e costa un tocco per categoria; l'alternativa (accesi) è concedere per inerzia. Dimmi se
   la vuoi diversa.
2. **Il testo del foglio dice «nessuno può modificare i tuoi dati».** È vero oggi (il trainer non
   scrive nulla), ma **US-090 gli farà scrivere la scheda del cliente**: in quel momento la frase
   diventa falsa e va riscritta nella stessa storia. L'ho annotato qui perché è un posto dove nessun
   test se ne accorgerebbe.

### 🟡 Da valutare — tecniche
3. **Un secondo invito dallo stesso trainer a un cliente già legato.** `createInvite` blocca solo gli
   inviti *pendenti* duplicati (US-087), quindi si può invitare chi è già un cliente accettato. Accettare
   il secondo fallirebbe con permesso negato, perché `consents/t_c` esiste già e l'accettazione la
   scriverebbe da capo. Non corrompe niente; l'utente vede un errore e l'invito resta in sospeso.
   Rimedio possibile: impedire l'invito a chi è già connesso. **Non l'ho fatto**: è fuori dai file del
   piano, e l'invito duplicato preesiste a questa storia.
4. **L'id `trainer_cliente` è ambiguo solo se un uid contiene `_`.** Gli uid di Firebase Auth con
   email/password sono alfanumerici di 28 caratteri, quindi oggi non succede. Diventerebbe un problema
   con uid personalizzati.
5. **La categoria «Allenamenti» concede tutto lo storico**, non solo gli allenamenti da ora, e include
   nome della palestra e nome dell'allenamento (l'ho aggiunto alla descrizione dopo averlo notato:
   prima non lo diceva). Non c'è un limite di tempo.
6. **Costo delle regole**: ogni lettura del trainer valuta tre accessi a documenti (consenso, invito,
   `exists`). Sotto il limite di dieci per richiesta; **non misurato** su dati veri.

### 🔵 Suggerimenti
7. `consentsOfClient` serve il lato cliente. US-091 avrà bisogno del simmetrico lato trainer (la query
   `where('trainerUserId', ...)` è già provata permessa dalle regole, il provider no).
8. `connect_friend_screen.dart` ha ormai quasi 600 righe: l'elenco delle connessioni meriterebbe un
   widget a sé. Non l'ho spostato: sarebbe un rifacimento fuori mandato.

## Deploy (2026-10-17)

Autorizzato esplicitamente dall'utente. Tre cose da sapere:

1. **Il primo deploy non ha fatto niente, e ha detto «Deploy complete!».** Con `firebase.json` a
   configurazione multi-database (`"firestore": [{"database": "gymflow", ...}]`), `--only
   firestore:rules` viene letto come un database di nome «rules» e non corrisponde a niente: la CLI
   controlla solo i permessi sugli indici e finisce. L'ho scoperto perché la verifica dall'API mostrava
   ancora il ruleset vecchio (stesso identificativo, 8911 caratteri). **Il comando giusto è
   `firebase deploy --only firestore:gymflow:rules --project gymflow-d5d09`** (nel repository non c'è
   `.firebaserc`, quindi `--project` serve).
2. **`verify-deploy.mjs` non verificava niente di nuovo.** Cercava solo le stringhe di US-087, quindi
   dava «Verificato» **anche prima** del deploy. Ora cerca anche `match /consents/{consentId}` e
   confronta il ruleset attivo con `firestore.rules` riga per riga: prima del deploy fallisce, dopo
   passa. È una modifica fuori dai file del piano, fatta perché senza la verifica chiesta dall'utente
   non avrebbe dimostrato nulla.
3. **Esito.** Dopo il deploy giusto la release `cloud.firestore/gymflow` punta al ruleset
   `de1ea62f-2f1c-4226-87bf-00aa6ae2942b` (14236 caratteri), **identico a `firestore.rules`**; era
   `db618dd7-7e71-44f6-9ac2-314732b9ed59`. Il vecchio ruleset resta come cronologia: un ripristino è
   `firebase deploy` di una versione precedente del file.

## Fuori scope rilevato

- Il **`secondary` del tema chiaro** è sotto 4,5:1 come testo, e `onSecondary` su fondo `secondary`
  è sotto 4,5:1 in tutte le palette chiare (3,3–4,2). Trovato misurando per il difetto del tema chiaro,
  non riguarda questa storia. Non toccato.
- Rigenerando i provider, `build_runner` ha cambiato anche l'hash di `goals_provider.g.dart` e
  `timer_service.g.dart` (i loro sorgenti erano stati modificati dai fix di settembre senza
  rigenerare). **Riportati allo stato committato**: non sono file di questa storia.

## Regressioni sospette

Nessuna trovata, e dichiaro cosa ho guardato: il ramo `else` di `_respond` è il codice di prima
(`respondToInvite`), `dissolveRelationship` per un legame `friend` fa la stessa `update` di
`revokeInvite`, `FriendDetailScreen` riceve un parametro **opzionale** (un solo punto di chiamata), e
le regole di `invites`, `invite_codes`, `workouts`, `programs`, `scheduled_workouts`, `exercises` e
`users/{uid}` non sono cambiate (lo dimostra la suite di US-087, ancora verde nelle sue 15 prove).

## Limiti dichiarati

- **Autoverifica**, non giudizio indipendente.
- **Il Dart non è stato provato contro l'emulatore.** Le regole sono provate con scritture JS
  equivalenti; il codice di `FirestoreService` che le compone (`acceptTrainerInvite`,
  `dissolveRelationship`) non gira in nessun test. Ho verificato a parte che `Consent.toMap()` abbia
  esattamente le chiavi che le regole ammettono (`hasOnly`) e la forma di `grants` che esse validano,
  ma un errore di composizione nel batch si vedrebbe solo sul telefono.
- **Nessun giro a schermo.** Il telefono non è raggiungibile da `adb` (compare su USB in modalità
  MTP), e il giro completo (invito → foglio → interruttori → revoca → scioglimento) richiede **due
  account**, uno con ruolo trainer. Non verificati: aspetto del foglio, disposizione della riga in
  elenco, comportamento del tema chiaro, lettori di schermo.
- **Le regole sono pubblicate e verificate per identità del testo, non per comportamento.** I test
  girano contro l'emulatore (`demo-gymflow-test`); nessun client vero ha ancora esercitato le regole
  nuove in produzione.
- Il **costo** dei `get()` nelle regole e il comportamento offline del consenso non sono stati misurati.
