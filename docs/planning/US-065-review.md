# US-065 — Review

**Storia:** Libreria esercizi ridisegnata · **Epic:** EP-014 · 3 punti
**Branch:** `feature/US-065-exercise-library-redesign` · **Base:** `main` `34e5fe1`
**Implementata da:** Agy (Antigravity), con l'utente come tramite
**Recensita il:** 2026-08-07

**Verdetto: APPROVATA.** È la consegna migliore ricevuta finora, e la prima in cui **tutte
e tre le trappole scritte nel mandato sono state evitate**: nessun pixel copiato, nessun
widget clonato nel test, nessun criterio spuntato senza prova.

Un difetto trovato in review, e non era nel codice ma in **cosa dice all'utente**.

---

## Verifica

| | Dichiarato da Agy | Misurato da me |
|---|---|---|
| `flutter analyze` | 63 | **63**, zero avvisi nuovi rispetto a `main` ✅ |
| `flutter test` | 389 verdi | **389** ✅ |
| File | 3 | 3 ✅ |
| Fuori piano | nessuno | nessuno ✅ |
| Commit | presente nel rapporto | **committato davvero** ✅ — a differenza di US-031 |

Dopo le correzioni di review: **63 avvisi, 391 test verdi**.

### Le tre trappole del mandato, una per una

**1. «I pixel del mockup non si copiano».** Nel file non c'è **un solo valore numerico**:
verificato con una ricerca su colori letterali, ombre inline, `EdgeInsets` numerici,
`BorderRadius.circular` numerici e `fontSize`. Zero risultati, `Colors.transparent` escluso.
Chip e segmentato hanno `cornerFull`, come il mandato chiedeva.

**2. «Non clonare il widget nel test».** Non l'ha fatto. Ha estratto tre funzioni pure —
l'estrazione dei gruppi muscolari, il filtro, la composizione della riga di dettaglio — e ha
provato quelle. **È la strada che US-076 avrebbe dovuto prendere.**

**3. «`exerciseLibraryViewFor` non si tocca».** Intatta: il diff non la sfiora, e il test di
US-076 continua a sorvegliarla.

In più ha scritto **di propria iniziativa un gruppo di ispezione statica del sorgente**, sullo
stesso modello del test di US-022, che vieta il ritorno dei valori a mano in questo file.

### Controprove, due e indipendenti dalla sua

| Mutazione | Esito |
|---|---|
| `matchesMuscle = true` — il filtro per gruppo non filtra più | **rosso** |
| Un `Colors.grey` rimesso al posto di un ruolo | **rosso**, dal suo test sul sorgente |

La sua controprova dichiarata era la prima; la seconda l'ho aggiunta io per verificare che
anche il test sul sorgente reggesse. Regge.

---

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| Titolo «Esercizi» con il conteggio accanto | ✅ | Pillola con il numero, su `surfaceContainerHigh`, raggio pieno |
| Casella «Cerca fra i tuoi esercizi» | ✅ | Con chiave localizzata, che prima era una stringa nel codice |
| Segmentato `Tutti · Miei · Recenti` | ✅ **con la scelta dichiarata** | Opzione (a) del piano: «Recenti» c'è e mostra «Ancora nessuno storico». **Non ha inventato un ordinamento**, che era il divieto esplicito |
| Chip per gruppo muscolare | ✅ | I gruppi si ricavano dai dati, ordinati per frequenza, **senza lista fissa** — e c'è un test con gruppi inattesi che lo dimostra |
| Riga di dettaglio: gruppi, «tuo», «senza video» | ✅ | Quattro test, uno per combinazione |
| Nessuna misura o colore scritti a mano | ✅ | Verificato da me con una ricerca indipendente, oltre al suo test |
| `exerciseLibraryViewFor` preservata | ✅ | Diff pulito |
| L'aspetto corrisponde al mockup | ❌ **da confermare sull'APK** | Dichiarato correttamente nel rapporto |

---

## Rilievi

### 🟡 1 — I tre vuoti dicevano la stessa cosa, e una era falsa

**Corretto.**

Con un chip di gruppo muscolare attivo che non trovava niente, la schermata mostrava
`exercises_empty`, cioè: *«Non ci sono ancora esercizi. Carica la libreria curata dalle
impostazioni, o aggiungine uno tuo.»*

**Ma gli esercizi ci sono** — se non ce ne fossero, `exerciseLibraryViewFor` avrebbe già
restituito `empty` prima di arrivare lì. Sono i filtri a nasconderli. Il messaggio quindi
**dice una cosa falsa e manda l'utente a rifare un'operazione già fatta**: caricare una
libreria che ha già.

Ora i vuoti sono tre e distinti: nessun esercizio in libreria, nessuna corrispondenza coi
filtri, nessuno storico. Con un test che verifica che siano diversi fra loro, tradotti in EN
e IT, e che **solo il primo mandi alle impostazioni**.

Perché il rapporto non l'ha visto: il piano segnalava esattamente questo caso fra i rischi —
«il filtro combinato dà risultati vuoti inspiegabili... è il caso da testare: tre filtri
attivi insieme, e il messaggio di lista vuota che compare invece di una schermata muta» — e la
consegna ha testato che **il filtro restituisce una lista vuota**, non che **il messaggio sia
giusto**. Ha provato la funzione e non il suo effetto.

### 🔵 2 — Aritmetica sul token

`vertical: t.spacing.xs / 2` nella pillola del conteggio, per ottenere 2. Un token diviso non
è un token: se la scala cambia, questo valore cambia in un modo che nessuno ha deciso. È lo
stesso rilievo fatto in US-047, e la conclusione è la stessa: se serve un valore che i token
non hanno, si aggiunge il token o si accetta il letterale con una ragione scritta — non si
divide.

Non l'ho corretto: è un pixel di padding verticale, e toccarlo per due unità non vale un
rischio in una schermata che va ancora guardata sull'APK.

### 🔵 3 — «Recenti» è una voce che non fa niente, e l'utente la vedrà

La scelta (a) era prevista dal piano ed è quella onesta: la voce c'è e dichiara di non avere
storico. Ma va detto chiaro che **l'utente troverà nell'interfaccia un filtro che non filtra
niente**, finché non esiste il dato dell'ultimo uso.

Se dà fastidio, l'opzione (b) — la voce non compare — è un `if`. È una decisione di prodotto,
e la lascio all'utente.

---

## Regressioni sospette

**Il filtro per tipo è stato rimosso**, come il piano chiedeva: i chip ora sono per gruppo
muscolare. Chi si era abituato a filtrare per Cardio non trova più quel controllo. È voluto —
di *tipo* forza sono quasi tutti, quindi il filtro non filtrava — ma è un cambiamento
d'abitudine che va notato guardando l'APK.

**La ricerca resta sopra i filtri**, come nel mockup. Nessuno l'ha spostata, e la lettura
sbagliata che l'orchestratore aveva fatto a voce era stata corretta nel piano prima della
consegna.

**Le chiavi di localizzazione sono nove nuove**, tutte in EN e IT: verificato nel diff. Il
test del progetto che legge il sorgente le avrebbe prese comunque.

---

## Limiti di questa review

- **La schermata non è stata aperta.** Tutto ciò che riguarda l'aspetto — che i chip stiano su
  una riga, che il segmentato non vada a capo, che la pillola del conteggio non spinga il
  titolo fuori — **non è verificato**. Per una storia il cui scopo è «assomigliare al
  mockup», è il limite più grande.
- **Non ho sovrapposto lo screenshot al mockup.** La fedeltà è giudicata leggendo quali token
  sono stati scelti, non guardando il risultato.
- **Il rallentamento della libreria resta il pezzo aperto di US-076**, e questa storia
  aggiunge widget alla stessa schermata: se lo scorrimento era già lento, ora c'è più roba.
  Da misurare insieme.
- **Non ho letto le 241 righe del test riga per riga**: ho letto i nomi dei casi, la struttura,
  e ho verificato il comportamento con due mutazioni.

---

## Cosa serve dall'utente

**La prova sull'APK**, ed è quella che chiude la storia: Menu → Esercizi, e guardare se è la
schermata che avevi approvato. In particolare i chip su una riga, il segmentato, e i marcatori
«tuo» e «senza video» nella riga di dettaglio.

E una decisione: **la voce «Recenti» che non filtra niente** resta, o spariste finché non c'è
il dato?

---

_Review del 2026-08-07 · numeri rimisurati, due mutazioni indipendenti, un difetto in ciò che la schermata dice_
