# US-045 — Review

**Verdetto:** APPROVATA CON RISERVE
**Diff esaminato:** `git diff main...HEAD` · 7 file, +791 / −82
**Verifica:** `flutter analyze` **66 avvisi, zero errori** (baseline invariato) · `flutter test` **237 test verdi** (erano 216) · `flutter build apk --debug` **riuscita**

La riserva è che **la scrittura vera su Firestore non è stata eseguita**: un test unitario non può
provarla, e un finto Firestore proverebbe il finto. Tutto ciò che precede la scrittura — lettura,
validazione, identificativi, conteggi — è provato sul file reale.

---

## Copertura dei criteri

| # | Criterio | Esito | Prova |
|---|---|---|---|
| 1 | Esiste uno script che importa gli esercizi da un file di partenza verso Firestore | ✅ nel codice, **da confermare sul dispositivo** | Comando in Impostazioni → «Carica Dati Default». **Verificato che l'asset finisca davvero nell'APK**: `assets/flutter_assets/assets/data/exercises_seed.json`, 14 774 byte, letto dall'archivio dell'APK costruito. Senza quella riga in `pubspec.yaml`, `rootBundle` non l'avrebbe trovato — ed è esattamente il motivo per cui il file era fermo da prima |
| 2 | Lo script è idempotente: eseguirlo due volte non crea duplicati | ✅ per costruzione, **la prova finale è sul dispositivo** | L'identificativo del documento è quello del file: 2 test (univocità dei 43, due letture danno la stessa lista). `set` su un id esistente sovrascrive — comportamento di Firestore, non nostro. Da eseguire due volte sul telefono |
| 3 | Ogni esercizio importato ha nome, tipo, gruppi muscolari e, dove disponibile, il video | ✅ | Test **sul file vero**: 43 esercizi, nessuno senza nome, nessuno senza gruppi, tutti con un tipo riconosciuto, 15 con video e 28 con la sola ricerca |
| 4 | Gli URL dei video sono validati durante l'importazione, e quelli scartati vengono elencati | ✅ | 4 test: una ricerca nel campo del video viene scartata **e l'esercizio resta valido**, un dominio non YouTube idem, un URL malformato idem, e ogni scarto porta identificativo, campo, valore e motivo |
| 5 | Il numero di esercizi importati è riportato al termine | ✅ nel codice, **la finestra da confermare sul dispositivo** | `ExerciseSeedResult` espone i tre conteggi e la finestra li mostra insieme all'elenco degli scarti |
| 6 | Gli esercizi curati sono distinguibili da quelli creati dagli utenti | ✅ | Test: tutti e 43 hanno `isCurated: true`, `isCustom: false`, `userId: null`. È anche ciò che li fa comparire nella libreria di tutti, per come `getExercises` interroga Firestore |

---

## Cosa ha trovato la review

### 🔴 Il baseline era salito a 67, per un motivo che è in realtà un miglioramento

Togliendo `FirestoreService()` dal comando, l'import di quel file è rimasto inutilizzato: un avviso
nuovo. Rimosso l'import. **Il file `settings_screen.dart` non istanzia più nessun servizio a mano**,
e questa è una riga in meno del debito di US-008 e US-009 — ottenuta di passaggio, non cercata.

### 🟡 Novantadue righe cancellate da `firestore_service.dart`

`seedDefaultExercises` conteneva gli otto esercizi scritti nel codice (`Bench Press`, `Squat`, …).
Sono spariti insieme al metodo. È voluto — sono ciò che US-045 sostituisce — ma va detto forte,
perché **il metodo aveva anche una protezione dai duplicati** (`if (existing.docs.isNotEmpty)
return;`) e qualcuno potrebbe cercarla. Non è stata persa: è diventata l'identificativo
deterministico, che è una garanzia più forte perché non dipende da un controllo da ricordare.

### 🟡 Gli otto esercizi vecchi restano in Firestore

L'import non cancella niente. Chi ha già premuto «Carica Dati Default» in passato si troverà in
libreria **8 esercizi inglesi senza video accanto ai 43 italiani**. Non è un difetto: cancellare
documenti che l'import non ha creato è una decisione dell'utente, non di uno strumento. Ma è una
cosa che si vede a schermo, e va decisa: o si cancellano a mano, o si aggiunge una voce apposta —
e in quel caso è una storia nuova.

### 🟡 «Script» è stato interpretato come comando dentro l'app

Il criterio dice «script». Un eseguibile separato avrebbe richiesto la chiave del service account,
un secondo runtime, e avrebbe scritto **scavalcando le regole di sicurezza**, cioè provando un
percorso che nessun utente percorre. L'import dentro l'app passa dalle regole vere e riusa un
comando che esisteva già.

È una scelta di interpretazione, non un criterio riscritto: se serve un eseguibile a riga di
comando — per esempio per popolare un ambiente senza aprire l'app — **è una storia a parte e va
detto adesso**, non fra sei mesi.

### 🔵 `videoNote` del file viene ignorato

Il file porta per ognuno dei 15 video una nota con il titolo reale del video, che è la prova della
pertinenza. Il modello `Exercise` non ha un campo dove metterla, quindi si perde nell'import.
Rimane nel file, che è il posto dove serve a chi verifica.

### 🔵 Il tipo non viene indovinato, a differenza di quanto fa il modello

`Exercise.fromMap` ripiega su `strength` per un tipo sconosciuto: giusto per un documento già
salvato, che va comunque mostrato. In importazione no: inventare il tipo significa dare all'utente
la schermata di registrazione sbagliata. L'esercizio viene saltato e messo nell'elenco. Due
comportamenti diversi di proposito, con un test che lo dichiara.

---

## Fuori scope rilevato nel diff

Nessuna modifica fuori dall'elenco del piano.

---

## Checklist adversariale

| Domanda | Risposta |
|---|---|
| File assente o corrotto? | 3 test: JSON non valido, radice sbagliata, elenco mancante. In tutti e tre l'app mostra un errore e non cade |
| Una riga sbagliata fa perdere le altre? | No, ed è testato: una voce che non è un oggetto viene saltata e le altre passano |
| Rete assente durante l'import? | `batch.commit()` fallisce, l'eccezione è catturata e mostrata come errore. Firestore ha comunque una coda offline: la scrittura può essere applicata più tardi. **Da confermare sul dispositivo** |
| `BuildContext` attraverso un `await`? | Il punto delicato di questo diff. Tre punti: `if (mounted)` prima di ogni uso, e `if (!mounted) return;` prima della finestra. L'analyzer non segnala nulla |
| Risorse rilasciate? | Nessuna risorsa creata. La finestra è chiusa dal suo pulsante |
| Servizi istanziati a mano? | **Non più in questo file**: il servizio arriva da `firestoreServiceProvider` |
| Stringhe nuove tradotte? | Sei chiavi, tutte in `_en` e `_it`. Il pulsante della finestra riusa `done`, che esisteva |
| Segreti nel diff? | Nessuno. La chiave del service account non è mai stata toccata — è anche il motivo per cui l'import non è uno script esterno |
| Scritture di troppo? | 43 documenti in un lotto solo. Il limite di Firestore è 500; la suddivisione a 400 c'è comunque, perché la libreria crescerà |
| Può rompere qualcosa di non testato? | Il comando «Carica Dati Default» cambia comportamento: prima non faceva nulla se l'archivio non era vuoto, ora riscrive sempre i 43 curati. Chi lo preme aspettandosi «non succede niente» ora ottiene un import. Il sottotitolo del comando dice «Reset exercises list», quindi la promessa è coerente |

---

## Limiti dichiarati

1. **La scrittura su Firestore non è stata eseguita.** Nessun test la copre e nessuno può coprirla
   senza un Firestore vero. Idempotenza e conteggi sono provati **fino al bordo** della scrittura.
2. **La pertinenza dei 15 video è valutata dal titolo**, non guardandoli: limite ereditato da
   US-041 e scritto nel file stesso, nel campo `videoPolicy`.
3. **I 28 esercizi senza video mostreranno il segnaposto**, e toccando il video apriranno una
   ricerca. È il comportamento corretto e voluto, non una mancanza dell'import.
4. **Nessuna immagine curata**: il file ha `imageUrl` nullo per tutti e 43. La catena di US-042
   ripiega da sola.
5. **La review è un'autoverifica.**

---

## Da confermare sul dispositivo

1. **Impostazioni → «Carica Dati Default»**: compare la finestra con *43 esercizi importati, 15 con
   video, 28 con la sola ricerca*, e nessuno scartato.
2. **Premerlo una seconda volta**: la libreria resta di 43 curati, non 86. È la prova
   dell'idempotenza.
3. **Libreria**: 43 esercizi in italiano, **15 con miniatura vera e indicatore del video**, gli
   altri con il segnaposto colorato per gruppo muscolare. È anche la prima conferma a schermo di
   US-042 e US-043, che finora hanno avuto solo il catalogo.
4. **Gli 8 vecchi**: verificare se sono ancora lì e decidere cosa farne.

---

_Review del 2026-08-06 · fase 5 del ciclo in [`WORKFLOW.md`](../WORKFLOW.md)_
