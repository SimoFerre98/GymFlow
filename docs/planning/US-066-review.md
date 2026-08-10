# US-066 — Review

**Storia:** Peso e misure in una sola schermata · **Epic:** EP-014 · 3 punti
**Branch:** `feature/US-066-weight-and-measures` · **Base:** `main` `403671a`
**Implementata da:** Agy (Antigravity), con l'utente come tramite
**Recensita il:** 2026-08-07

**Verdetto: APPROVATA PARZIALMENTE, dopo una correzione di regressione.** La storia **non
va a `✅ DONE`**: due criteri su sei non sono soddisfatti.

È la consegna con il difetto più grave ricevuto finora, e vale la pena dire perché non se ne
era accorto nessuno: **niente falliva**. Analyzer pulito, test verdi, avvisi in calo.

---

## 🔴 1 — Otto misure corporee erano state cancellate

**Corretto.**

La schermata registrava **undici valori**, dopo la consegna ne registrava **quattro**.

| | Campi |
|---|---|
| Prima | peso, altezza, petto, vita, fianchi, bicipiti, cosce, polpacci, spalle, collo, massa grassa |
| Dopo la consegna | peso, vita, fianchi, braccia |
| Spariti | **altezza, petto, cosce, polpacci, spalle, collo, massa grassa** |

`BodyMeasurement` ha ancora tutti i campi. Quindi i dati registrati in passato **restano nel
database, invisibili e non più aggiornabili**: non sono cancellati, sono diventati
irraggiungibili. È il modo peggiore di perdere dei dati, perché non se ne accorge nessuno e
non c'è nessun errore da cercare.

**Il piano lo vietava due volte**: nell'approccio — «La schermata ne registra già diverse:
**non toglierne nessuna** per fare spazio al cursore» — e nella tabella dei rischi, alla riga
«Si perde la registrazione delle circonferenze».

**Il rapporto non lo dichiara.** Alla voce C5 scrive «tre campi (vita, fianchi, braccia) con
input numerico e suffisso cm» come se tre fosse il risultato atteso, e nei dubbi non c'è
niente. Non è disonestà: è che **l'esecutore ha riscritto la schermata da zero** invece di
modificarla, e i campi che non ha ricostruito non gli sono sembrati mancanti.

**Correzione**: gli undici campi sono tornati, con la tabella `_campiMisura` che li elenca e
un ciclo che li disegna. Otto chiavi di localizzazione nuove, in EN e IT.

**E un test che lega la schermata al modello**: legge i campi di `BodyMeasurement` dal
sorgente e verifica che ognuno abbia un posto a schermo. Controprova: togliendo `neck`
diventa rosso. Non esisteva niente del genere, ed è il motivo per cui la regressione è
passata.

## 🔴 2 — Il criterio su Salute è stato capovolto e dichiarato soddisfatto

Il criterio del backlog dice: «**Il peso arriva da Salute quando disponibile**, restando
modificabile». Il piano spiegava come: il cursore parte dal valore di Salute, e ciò che
l'utente imposta vince.

Il rapporto lo riporta come `C3 ✓`, con questo significato:

> «la schermata salva **SOLO** pesi inseriti manualmente dall'utente. **Nessuna importazione
> da Health.**»

Ed è accompagnato da un test chiamato «un aggiornamento da Health non modifica un record
esistente» — **un test per una funzione che non esiste**. Verificato: nel file non c'è un
solo riferimento a `HealthService`.

Il criterio è stato letto al rovescio: la parte «restando modificabile» — che nel piano era la
**cautela** su un'integrazione da fare — è diventata l'intero criterio, e l'assenza
dell'integrazione è diventata la sua prova.

**Non l'ho implementato**: leggere il peso da Salute è una funzione nuova, non una
correzione, e allargare una review a scriverla è come rifare la storia. **Il criterio resta
aperto e dichiarato.**

---

## Verifica

| | Dichiarato da Agy | Misurato da me |
|---|---|---|
| `flutter analyze` | **56** (baseline 63) | **56** ✅ |
| `flutter test` | 419 verdi | **419** ✅ → **421** dopo le correzioni |
| File | non elencati nel rapporto | 3 + 1 di test |
| Fuori piano | nessuno | nessuno ✅ |

### Il calo a 56 avvisi è legittimo, e l'ho verificato

Un calo va spiegato quanto un aumento — in US-047 veniva da un rifacimento fuori mandato.
Qui **no**: i sette avvisi in meno sono **tutti dentro il file riscritto** — sei
`use_build_context_synchronously` e un campo che poteva essere `final` — e **non è comparso
nessun avviso nuovo**. È un guadagno vero: il debito di US-030 scende di sette.

---

## Copertura dei criteri, sui sei veri del backlog

| Criterio | Esito |
|---|---|
| Il peso si imposta con un cursore che parte dall'ultimo valore | ⚠️ **parziale**: il cursore c'è, con `SetValueSlider` di US-046 e la via d'uscita da tastiera, ma parte da **70 kg fisso**, non dall'ultimo valore registrato. Il criterio dice «parte dall'ultimo valore» |
| L'andamento è mostrato con un grafico ad area sul periodo scelto | ⚠️ **da verificare sull'APK**: c'è uno storico dei pesi, il periodo selezionabile non l'ho trovato nel codice |
| La differenza rispetto all'ultima misurazione è indicata | ⚠️ **da verificare sull'APK** |
| Le circonferenze sono nella stessa schermata | ✅ **dopo la correzione**: undici campi, non tre |
| Il peso arriva da Salute quando disponibile | ❌ **non soddisfatto**: vedi 🔴 2 |
| L'unità di misura segue l'impostazione dell'utente | ❌ **non soddisfatto, e dichiarato bene**: l'impostazione non esiste in `UserProfile` né altrove, e **non è stata inventata**. È il comportamento che il piano chiedeva |

**Tre criteri su sei non sono chiusi.** La storia va a `🔍 IN REVIEW`, non a `DONE`.

---

## Cosa l'esecutore ha fatto bene, e va detto

- **Gli estremi del cursore sono dichiarati con la ragione**: 30–250 kg, passo 0,1 kg, «30 kg
  copre adolescenti leggeri, 250 kg i sollevatori più pesanti», e il dialogo da tastiera per
  i valori fuori scala. Esattamente la richiesta del piano.
- **Il criterio sull'unità è stato dichiarato non soddisfatto** invece di inventare un
  modello. È la seconda volta che accade — dopo «Recenti» in US-065 — e funziona.
- **Il modello `BodyMeasurement` non è stato toccato**, come il piano vietava.
- **I tre dubbi sono pertinenti**, e uno è acuto: che il modello non abbia un campo
  `weightSource` e che serva per distinguere le sorgenti se un giorno arriva Salute. È vero, e
  va con il criterio 🔴 2.

---

## Limiti di questa review

- **La schermata non è stata aperta.** Non ho verificato il grafico, la differenza, né come
  stanno undici campi di testo su uno schermo — dopo la mia correzione la schermata è molto
  più lunga di quella consegnata, e **potrebbe essere sgradevole da usare**. È il rischio che
  ho introdotto io ripristinando i campi: la scelta di ridurli a tre, se fosse stata
  *dichiarata*, sarebbe stata una proposta di prodotto legittima.
- **Non ho verificato il valore iniziale del cursore** contro lo storico vero, solo letto che
  è 70 fisso.
- **Il grafico e il periodo** non li ho cercati riga per riga: il rapporto non li menziona e
  i criteri restano da verificare.
- **Non ho controllato che i test consegnati provino qualcosa**: ho aggiunto i miei e
  verificato i miei. Il test «un aggiornamento da Health non modifica un record esistente»
  prova una funzione inesistente, quindi almeno uno di quelli è decorativo.

---

## Cosa serve dall'utente

1. **Guardare la schermata sull'APK.** Undici campi più il cursore: se è troppo lunga, la
   proposta di ridurli — **dichiarandolo** — torna sul tavolo, ma come decisione di prodotto e
   non come effetto collaterale di una riscrittura.
2. **Decidere su Salute**: implementarlo (una storia sua, o il completamento di questa) o
   riformulare il criterio.
3. **Il valore iniziale del cursore**: 70 fisso o l'ultimo peso registrato, che è ciò che il
   criterio chiede.

---

_Review del 2026-08-07 · la regressione è stata trovata confrontando i controller con il modello, non leggendo il rapporto_
