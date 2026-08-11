# US-028 — Review

**Data:** 2026-08-11 · **Branch:** `feature/US-028-contrast-aa`
**Commit rivisto:** `7673cd7`
**Chi ha implementato:** Gemini · **Chi rivede:** non ha scritto il codice

**Verdetto: APPROVATA.** È la prima consegna di questa serie in cui la sostanza regge alla verifica
senza correzioni. Restano due rilievi 🟡 sul **rapporto**, non sul codice.

---

## Cosa è vero, verificato e non creduto

- **`analyze`: 17, elenco identico a `main`.** Confrontato riga per riga.
- **`flutter test`: 495 verdi**, la suite intera.
- **Il buco che il piano indicava è stato chiuso**, ed è la parte che valeva: i sei preset ora sono
  misurati anche nel **tema chiaro**, dove l'accento finisce in `primaryContainer` e nessuno l'aveva
  mai guardato.
- **I quaranta numeri di `docs/design/contrasti.md` sono giusti.** Li ho ricalcolati tutti con una
  sonda indipendente: **coincidono al centesimo**, uno per uno, comprese le due righe delle coppie
  scure che il piano non nominava. Su questo progetto è un risultato: la lezione n. 5 dell'handoff
  è nata da numeri inventati mostrati come veri, e qui non ce ne sono.
- **Nessun colore è stato cambiato**, e non serviva: il preset peggiore misura 6.39:1 contro una
  soglia di 4.5. Il rischio più grosso del piano — ritoccare la palette per far passare una misura —
  non si è materializzato.
- **Nessun file fuori dai due previsti.** `app_theme.dart` non è stato aperto, come chiesto.

## La copertura non è diminuita, anche se i test sono sei in meno

I test dei preset erano tre per preset (diciotto) e diventano due (dodici): da qui i 495 invece dei
501. **Non è una perdita**, ed è stato verificato che le vecchie asserzioni ci siano ancora,
espresse attraverso il `ColorScheme` invece che sulle costanti della palette:

| Prima | Dopo | Equivalente? |
|---|---|---|
| `ratio(preset, indigo900)` | `ratio(s.primary, s.surfaceContainerLowest)` | ✅ `surfaceContainerLowest` **è** `indigo900` (misurato: 14.76 in entrambe le forme) |
| `ratio(preset, indigo800)` | `ratio(s.primary, s.surface)` | ✅ `surface` **è** `indigo800` (12.06) |
| `ratio(indigo900, preset)` | `ratio(s.onPrimary, s.primary)` | ✅ `onPrimary` **è** `indigo900` |

Ed è un miglioramento: ora si misura **ciò che l'applicazione usa davvero**, non ciò che si presume
usi. Se un giorno `surface` smettesse di essere `indigo800`, il test seguirebbe il tema invece di
restare indietro.

---

## 🟡-1 · La mutazione dichiarata non dimostra ciò che dice

> «Sostituito di proposito il preset `amber` con un grigio molto chiaro (`0xFFEEEEEE`). Il test ha
> intercettato immediatamente l'incoerenza.»

Il test è diventato rosso, ma **non per il contrasto**. Un grigio chiarissimo su fondo indaco ha un
rapporto altissimo: **supera tutte le soglie**. A farlo fallire è stato un altro test,
`il primo preset e l ambra predefinita` (`contrast_test.dart:109`), che confronta l'identità del
colore e non la sua leggibilità.

È la trappola descritta nell'handoff — «verifica che la mutazione sia davvero quella che credi» —
in una forma nuova: la mutazione era nel file giusto, ma colpiva un test diverso da quello che si
voleva provare. Un rosso non è una prova finché non si guarda **quale** test è diventato rosso.

**Rifatta in review, con due mutazioni che colpiscono i contrasti:**

| Mutazione | Esito |
|---|---|
| La menta diventa un indaco scuro `0xFF4A4470` | 🔴 `preset 2 nel tema scuro`, con la misura nel messaggio: **1.79:1** |
| Nel tema chiaro `onPrimaryContainer` diventa `amberMuted` | 🔴 `preset 0 nel tema chiaro`: **2.92:1** |

La seconda è quella che conta davvero: **fallisce solo il test nuovo**, e i vecchi restano verdi.
È la prova che la copertura aggiunta copre qualcosa che prima non era coperto.

## 🟡-2 · Un calo di sei test va spiegato quanto un aumento

Il rapporto scrive «495 verdi (erano 501)» e si ferma lì. Il numero è onesto, la spiegazione manca —
ed è la stessa regola che il progetto applica agli avvisi dell'analyzer: un calo può venire dal
codice che la storia riscriveva davvero, oppure da qualcosa che è sparito. Qui è il primo caso, ma
per saperlo ho dovuto leggere il diff.

## 🔵 Minori

| | Cosa |
|---|---|
| 1 | Tre `expect` in un test solo: se il primo fallisce, gli altri due non vengono misurati. Con sei preset e due temi, sapere **quante** coppie sono sotto soglia vale più che saperne una |
| 2 | Il piano chiedeva di segnalare le coppie che stanno sopra la soglia **di poco**. Il documento non lo fa: `testo secondario su superficie` nel tema chiaro misura **5.52:1** contro 4.5, ed è il margine più stretto di tutta l'interfaccia. È l'informazione utile alla prossima persona che ritocca `lightOnSurfaceDim` |
| 3 | Il documento non dice **come** sono stati prodotti i numeri. Il piano suggeriva di ricavarli dal test perché la tabella non possa divergere: sono corretti oggi, ma niente impedisce che domani non lo siano più |

---

## Copertura dei criteri

| Criterio | Esito |
|---|---|
| Testo su chiaro ≥ 4.5:1 | ✅ già coperto, e la citazione è giusta (`:215-236`) |
| Testo grande ≥ 3:1 | ✅ già coperto (`:145-213`, `Contrast.aaLarge`) |
| Il primario per testo è verificato o ha una variante accessibile | ✅ `amberOnLight` a 6.31:1, `salmonOnLight` a 6.93:1, misurati |
| Tutti i preset sono verificati | ✅ **e questa è la storia**: sei preset × due temi, e nel chiaro non lo erano |
| La verifica è documentata per i due temi | ✅ `docs/design/contrasti.md`, quaranta valori, tutti ricalcolati |

---

## Fuori scope rilevato

Nessuno.

## Limiti dichiarati di questa review

1. **Non ho aperto l'app.** Un rapporto di contrasto è una proprietà di due colori, non di uno
   schermo: dice che il testo è leggibile in teoria, non che lo sia in palestra con il sole. Il
   criterio nasce da lì, e nessun test lo copre.
2. **I contrasti misurati sono quelli dei ruoli del tema**, non quelli che le schermate usano
   davvero. Un `Colors.grey` ereditato — e ce ne sono ancora nelle schermate secondarie — non passa
   da nessuna di queste prove. È US-022 e US-023, ed è dichiarato nel piano come fuori scope.
3. **Non ho verificato le soglie scelte una per una.** Dove il test chiede AAA invece di AA ho preso
   per buona la scelta fatta quando la palette è stata definita.

---

_Review di fase 5 · US-028 · su codice non scritto da chi rivede_
