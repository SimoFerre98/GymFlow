# Review US-113

**Verdetto: APPROVATA CON RISERVE** — nessun rilievo bloccante sul codice. Le riserve sono tre condizioni
prima di dire «finita»: il **deploy delle regole** (non fatto, serve il tuo sì), la **cache Isar con dati
veri su un telefono** (non provata: il telefono non è raggiungibile), e due rilievi di sicurezza di
poco conto che trovi sotto.

La review è un'**autoverifica**. Sono partito dal diff (`git diff main...HEAD`, 22 file) e ho **rotto di
proposito** regole, modelli, mappatori e interfaccia: ogni controllo nuovo ha almeno un test che diventa
rosso se lo si toglie.

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| Terzo interruttore «Schede», spento di default, con parole che dicono cosa concede e cosa no | ✅ widget · ⬜ telefono | Tre interruttori tutti spenti; il testo dice «nuove schede», «solo quelle che ha scritto lui», «arrivano spente»; accendere solo «Schede» concede solo la scrittura. **Non visto su un telefono** |
| Con il permesso il trainer crea scheda e giorni a nome del cliente, **sempre inattiva**; senza, no | ✅ emulatore | `programs` e `workouts`: con permesso ok; senza, con solo sessioni e misure concesse, e con `isActive: true` → negato |
| Il trainer legge, modifica e cancella **solo ciò che ha scritto lui** | ✅ emulatore | Le altre schede del cliente e quelle di un altro trainer: lettura, modifica e cancellazione negate. La sua query per cliente **e** autore passa e restituisce una scheda sola; senza il filtro sull'autore è negata |
| Nessuna scrittura per chi non lo ha invitato; chiusa da revoca o scioglimento | ✅ emulatore | Un estraneo è negato; permesso spento → ogni operazione negata, anche sulle sue; legame sciolto con il consenso rimasto → negato (la cintura); lo scioglimento lascia le schede al cliente, che le legge, modifica e cancella |
| Il cliente non fabbrica né cambia un autore | ✅ emulatore | Crea con `authorId` → negato; lo cambia o lo toglie → negato; modifica, attiva e cancella la scheda ricevuta → ok |
| La scheda dice da chi arriva | ✅ widget · ⬜ telefono | «SCRITTA DA TINA»; «SCRITTA DAL TUO TRAINER» se il nome manca; nessuna riga per una scheda propria |
| L'autore sopravvive alla cache locale e al salvataggio del cliente | ✅ mappatori · ⬜ Isar vero | Andata e ritorno di dominio, mappa e modello Isar; **`toMap()` non scrive mai `authorId: null`**, con un test che fallisce se qualcuno lo fa. Non provato su un database Isar con dati veri |
| La frase «nessuno può modificare i tuoi dati» è riscritta | ✅ | Il foglio non la contiene più, in nessuna lingua |

## Cosa ha trovato la rottura di proposito

Rotti uno alla volta: i controlli sull'autore, sul permesso, sullo stato dell'invito, su `isActive`,
`senzaAutore`, `autoreInvariato`, la validazione di `grants`, la cancellazione dei giorni; e nel Dart la
scrittura di `authorId` nullo, ogni mappatore, `copyWith`, la lettura chiusa per predefinito, il valore
di partenza del foglio, la riga «scritta da» e la frase vecchia. Ogni volta un test è diventato rosso.

Due cose da dichiarare:
- **Un controllo è ridondante per costruzione** e nessun test lo isola: `userId != io` in `creatoPerConto`.
  Richiede un consenso `t_t`, che non può esistere perché un invito a se stessi è negato. L'ho lasciato
  perché dichiara l'intenzione e non costa nulla, con un commento che lo dice.
- **Una mia mutazione era sbagliata** (ancoraggio su un punto che non c'era): l'ho rifatta sul punto giusto
  prima di contarla come «presa».

## Rilievi

### 🔴 Bloccanti
Nessuno sul codice.

### 🟡 Da valutare
1. **Il nome «da chi arriva» lo scrive il trainer e nessuna regola lo può verificare.** `authorName` è
   testo libero copiato alla scrittura: un trainer potrebbe mettere un altro nome. Le regole non possono
   confrontarlo con il suo profilo (non si legge il profilo di un altro utente). Il cliente però **conosce già
   il nome vero**, perché lo ha nell'invito che ha accettato: in US-114 conviene mostrarlo ricavandolo
   dall'invito con quell'`authorId`, e usare `authorName` solo come ripiego. L'`authorId`, invece, lo
   impongono le regole.
2. **Un trainer con il permesso può creare giorni (`workouts`) che non stanno in nessuna scheda.** Restano
   del cliente, che li può cancellare, ma in passato i giorni «orfani» comparivano nei selettori del
   calendario. È un fastidio e non un furto di dati, e si chiude revocando il permesso. Non l'ho verificato
   sul selettore reale.
3. **Il nome dell'autore è quello del giorno della scrittura.** Se il trainer cambia nome, le schede vecchie
   mostrano il vecchio.
4. **Lo schema Isar cambia per la prima volta in questa sessione.** Aggiungere due proprietà nullabili a una
   collezione esistente è sicuro per Isar, ma **non l'ho provato su un telefono con dati**. È la prova da
   fare per prima: installare sopra l'app esistente e controllare che le schede di prima ci siano ancora.
5. **Costo delle regole non misurato.** `scrittoDalTrainer` viene dopo `eMio()` e non dovrebbe costare nulla
   al proprietario, ma non l'ho misurato.
6. **Quando si uniranno US-089 e questa storia ci sarà un conflitto** in `firestore-tests/rules.test.mjs`
   (entrambe aggiungono prove nello stesso punto e importano funzioni diverse). Vanno tenute **entrambe** le
   serie di prove. Nel branch temporaneo con cui ho costruito l'APK ho preso solo quelle di questa storia:
   non è un modello per il merge vero.

### 🔵 Suggerimenti
7. Nessun codice dell'app scrive ancora schede per un cliente: ci sono il permesso, le regole e il campo. Le
   scritture del trainer sono provate con scritture equivalenti dell'emulatore, non con il Dart che le farà
   (US-114).

## Fuori scope rilevato
Nessuno nuovo.

## Regressioni sospette
Nessuna trovata. Le schede che il cliente scrive da sé continuano a passare per la stessa strada
(`loCreoMio` senza autore) e le prove lo verificano; i documenti già esistenti non hanno `authorId` e si
leggono come prima (`get('authorId', null)`); i consensi scritti prima di questa storia si aggiornano
ancora e si estendono (prova dedicata); le 74 prove delle regole comprendono le 42 di US-092, tutte ancora verdi.

## Limiti dichiarati
- **Autoverifica**, non giudizio indipendente.
- **Nessun telefono.** Il foglio con tre interruttori, la riga «scritta da» e la cache Isar con dati veri sono
  da confermare sull'APK (preparato, non installato).
- **Il Dart che scrive per conto di un cliente non esiste ancora**: le regole sono provate con scritture
  JavaScript equivalenti.
- **Le regole non sono pubblicate.** I test girano contro l'emulatore (`demo-gymflow-test`), mai contro il
  progetto vero.
