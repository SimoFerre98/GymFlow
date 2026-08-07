# US-050 — Review

**Storia:** Riconoscere i record personali · **Epic:** EP-010 · 3 punti
**Branch:** `feature/US-050-personal-records` · **Base:** `main` `6b3f15e`
**Recensita il:** 2026-08-07 · **Chi:** orchestratore (non l'autore del codice)

**Verdetto: APPROVATA CON RISERVE.** Un rilievo bloccante sul funzionamento reale e uno
sulla fedeltà al mockup sono stati corretti in review. **Due criteri di accettazione su
sei non sono soddisfatti**, e uno dei due era stato spuntato: servono due decisioni.

---

## Premessa

Come US-047, questo lavoro non era su un branch: era non committato e mescolato con
quello di US-047 nella cartella principale. Il rapporto di consegna dichiarava gli
stessi numeri di US-047 (62 avvisi, 344 test) perché erano misurati sullo stesso mucchio:
**non erano i numeri di questa storia.** Quelli veri sono più sotto.

Il mucchio conteneva anche una modifica al backlog che **spuntava criteri non
soddisfatti**. Vedi la sezione sui criteri: è il rilievo più importante di questa review,
e non è nel codice.

---

## Verifica, rifatta

Misurata nel worktree `../GF050`.

| | Esito |
|---|---|
| `flutter analyze` | **63** — uguale al baseline |
| `flutter test` | **331 verdi**, di cui 16 nuovi |
| `flutter build apk --debug` | riuscita |

---

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| Il massimo è calcolato dalle serie completate, non da quelle pianificate | ✅ | `calculatePersonalBests` filtra su `isCompleted`. **Il test mancava** e l'ho aggiunto: vedi rilievo 🟡 3 |
| Il confronto tiene conto sia del carico sia delle ripetizioni | ❌ **non soddisfatto** | Il confronto guarda **solo il carico**, per scelta dichiarata nel piano. Era spuntato nel backlog del mucchio. Vedi 🔴 3 |
| Il superamento è segnalato alla chiusura della serie, senza interrompere | ✅ | La riga «+2,5 kg sul tuo massimo» compare nel foglio mentre imposti il carico, con tre test. Non funzionava nell'app vera: vedi 🔴 1 |
| La storia dei record per esercizio è consultabile | ❌ **fuori scope di questa storia** | Il piano la mette esplicitamente in US-068. È un criterio che non appartiene alla storia in cui è scritto. Vedi 🟡 4 |
| Al primo allenamento non si segnala alcun record | ✅ | Due test: massimo assente, ed esercizio nuovo dentro una sessione con altri record |
| Il calcolo è coperto da test, compresi i casi limite di parità | ✅ | Pareggio, carico inferiore, zero ripetizioni, corpo libero, storia vuota, serie non completate |

### Il criterio aperto di US-049

> «Un record superato durante la sessione è riportato con il valore precedente»

**Soddisfatto**, e va spuntato anche nel backlog di US-049. La card compare sotto lo
scontrino con il valore precedente e la sua data, con due test — uno che la mostra e uno
che verifica che senza record non compaia nulla.

Il piano avvertiva che «il posto sotto lo scontrino non è stato lasciato pronto». Verificato:
la card è stata inserita fra `WorkoutReceipt` e il pulsante «Chiudi», che è dove il piano
diceva. **E la condizione con cui US-049 è stata accettata regge:
`workout_summary_screen.dart` non contiene stringhe scritte a mano** — tutto passa da
`loc.t(...)`, con le chiavi in EN e IT.

---

## Rilievi

### 🔴 1 — Il record non si sarebbe segnalato nell'app vera

**Corretto.**

```dart
final personalBests = ref.read(personalBestsProvider);   // in _openSetEditor
```

`personalBestsProvider` è `autoDispose` e calcola i massimi da `dashboardSessionsProvider`,
che è uno **stream** su Isar. Una `ref.read` senza nessuno che lo ascolti lo costruisce
da freddo: lo stream non ha ancora emesso, `sessionsAsync.value` è `null`, la mappa
torna **vuota** — e poiché è `read` e non `watch`, il foglio non si ricostruisce quando
il dato arriva. Nessun record segnalato.

Funzionava soltanto per un caso fortunato: la dashboard, restando montata sotto la
schermata di sessione, tiene lo stream caldo e già emesso. Una correttezza che dipende
da quale schermata c'è sotto nello stack, e che non si vede leggendo questo file.

**I test non l'hanno preso** perché passano `personalBest:` direttamente al foglio,
scavalcando il provider. Provano il widget, non il collegamento.

Ora la schermata fa `ref.watch(personalBestsProvider)` in `build`, così il provider
resta vivo e caldo per tutta la sessione e la `ref.read` successiva trova il dato.

### 🔴 2 — La card contornata aveva un fondo, e le misure erano copiate

**Corretto.** `DESIGN-SPEC.md` descrive tre varianti di card e la contornata è
**trasparente con il solo bordo ambra**: è ciò che la distingue dalla piena. Con un
fondo (`surfaceContainerLow`) diventa una card normale con un bordo, e la distinzione
salta.

Le misure erano i pixel del mockup **copiati** invece che convertiti — lo stesso errore
di US-073 e della sparkline di US-047:

| | Mockup | Copiato | Convertito (× 1,36) |
|---|---|---|---|
| Raggio | 20 px | `cornerMd` = 16 | **`cornerLg` = 24** |
| Bordo | 1,4 px | `1.5` | **2** |
| Fondo pillola | accento 20% | `0.15` | **0.20** |

Il `1.5` era anche un letterale numerico in un file nuovo. Ora è una costante del
componente con la conversione scritta nel commento.

Nota: il testo secondario usava `onSurfaceVariant` **smorzato ancora al 70%**. Il
mockup dice «opacità .6», ma quello .6 è riferito a `paper`, cioè a `onSurface`:
applicarlo a `onSurfaceVariant`, che è già il ruolo del testo attenuato, smorza due
volte e finisce esattamente fra i testi sbiaditi che US-022 dovrà recuperare. Ora usa il
ruolo pieno, come il resto della stessa schermata.

### 🔴 3 — Un criterio non soddisfatto era stato spuntato

> «Il confronto tiene conto sia del carico sia delle ripetizioni»

**Il confronto guarda solo il carico.** `PersonalRecord.detect` documenta la regola:
«è record il carico più alto mai sollevato per almeno una ripetizione». Le ripetizioni
servono solo come filtro di validità (`reps >= 1`) e per il testo mostrato. Stesso carico
con più ripetizioni **non** è un record, ed è scritto nel piano come limite dichiarato.

La scelta è motivata bene nel piano — «record» deve essere una parola che l'utente
capisce senza spiegazioni, e un massimale stimato con Epley sposterebbe la soglia a ogni
cambio di ripetizioni. **Non discuto la scelta: discuto la spunta.** Nel backlog del
mucchio questo criterio era `[x]`, e non lo è.

Non l'ho riscritto: cambiare un criterio per farlo combaciare con l'implementazione è
ciò che il processo vieta esplicitamente. **Serve una decisione** — vedi in fondo.

### 🟡 4 — «La storia dei record è consultabile» non appartiene a questa storia

Il criterio è fra quelli di US-050, ma il piano di US-050 lo mette in **Fuori scope** e
lo assegna a US-068, che dipende da questa storia. Il backlog del mucchio lo lasciava
`[ ]` con la nota «demandata a US-068», che è la cosa onesta da fare, ma lascia la storia
con un criterio che non sarà mai soddisfatto dentro i suoi confini.

**Serve una decisione**: spostare il criterio su US-068, o tenere US-050 aperta.

### 🟡 5 — Il massimo non si aggiorna durante la sessione

I massimi vengono dalle sessioni **salvate**. Chi batte il record alla prima serie e poi
imposta un carico intermedio si vede segnalare un secondo record contro il massimo
vecchio: massimo 60, prima serie a 62,5 («+2,5»), seconda a 61 → «+1 sul tuo massimo»,
mentre il massimo di oggi è già 62,5.

Il riepilogo è corretto — `detectSessionRecords` prende la serie migliore della sessione
— quindi l'imprecisione vive solo nel foglio della serie, mentre ti alleni.

Non l'ho corretto: servirebbe un massimo di sessione tenuto in memoria, che è una
decisione di prodotto (il secondo «record» è un errore o è un incoraggiamento?) più che
un difetto di codice. **Da decidere**, eventualmente come storia sua.

### 🟡 6 — `PersonalRecord.detect` non è usato da nessuno

La funzione pura con la lista storica (`detect`, con `history`) è quella che il piano
descriveva nell'approccio, ed è coperta da due test — ma **l'app non la chiama**: il
codice usa `detectFromBest` e `detectSessionRecords`. È API testata e morta.

Non l'ho rimossa perché è la firma che il piano dichiara e US-068 potrebbe usarla, ma va
saputo: due dei test di questa storia provano codice che nessuno esegue.

### 🔵 7 — La variante contornata dovrebbe stare in `ExpressiveCard`

`ExpressiveCard` ha una sola variante, quella normale. Il mockup ne dichiara tre —
normale, piena, contornata — e questa storia ha dovuto costruire la contornata a mano
con un `Container`. Il posto giusto è il componente condiviso, ma toccarlo è fuori dai
file del piano: è materia di US-021 / US-022.

### 🔵 8 — I test cercano le traduzioni, non le chiavi

`expect(find.textContaining('sul tuo massimo'), ...)` e `find.text('RECORD')` legano il
test alla traduzione italiana: cambiare la parola rompe il test senza che sia cambiato
niente di sostanziale. Leggere l'etichetta da `Localization(Locale('it')).t('record_pill')`
prova la stessa cosa e resiste. L'ho fatto nei test di US-047; qui l'ho lasciato per non
allargare il diff su test che passano.

### 🔵 9 — `exerciseId` passato al foglio e mai usato

`SetEditorSheet` riceve `exerciseId` ma non lo legge: il confronto usa solo
`personalBest`. Parametro innocuo, ma è un'informazione che il foglio dichiara di volere
e non usa.

---

## Fuori piano rilevato

| Cosa | Giudizio |
|---|---|
| `test/unit/personal_record_test.dart` invece di `test/personal_record_test.dart` | Il piano diceva `test/personal_record_test.dart`. La cartella `test/unit/` **non esisteva**: questa storia la crea per un file solo, mentre tutti gli altri test del progetto stanno in `test/`. Non l'ho spostato — è una convenzione da decidere, non un difetto — ma è una divergenza dal piano non dichiarata |
| `workout_summary_screen.dart` invece di `workout_receipt.dart` | Il piano lasciava la scelta («o la schermata di US-049»). Scelta giusta: lo scontrino è un componente, la card dei record è un'altra cosa |
| `test/workout_receipt_test.dart` modificato | Non era nel piano, ma è il file dove vivono i test della schermata di riepilogo. Legittimo |
| `docs/BACKLOG.md` | Vedi 🔴 3: teneva una spunta non dovuta. Tenuto fuori dal branch, si aggiorna alla chiusura |

---

## Regressioni sospette

**Il foglio della serie di US-046.** `_PreviousSet` è passato da `Row` a `Column` per
ospitare la riga del confronto, e ora il blocco compare anche quando la serie precedente
**non** c'è ma un record sì (`previous != null || isRecord`), con `text: ''` e
l'etichetta che diventa «RECORD». I test di US-046 passano tutti, incluso quello sul
riferimento della serie precedente. Il caso «nessuna serie precedente + record» ha un
test.

**Il colore dei valori.** La riga del confronto usa `scheme.primary` (ambra), che è il
ruolo dell'azione. Qui indica un dato, non una cosa da fare. È però ciò che il mockup
disegna — nella card ambra il valore in evidenza è ambra — quindi non lo segnalo come
violazione della regola ambra/salmone: la regola parla dell'ambra usata **come sfondo**
di qualcosa che non è un'azione.

**`ref.watch` in un `build` che si ricostruisce ogni secondo.** La schermata chiama
`setState` al secondo per il cronometro. `ref.watch(personalBestsProvider)` è una lettura,
non un calcolo: i massimi si ricalcolano solo quando lo stream di Isar emette, non a ogni
ricostruzione.

---

## Limiti di questa review

- **Niente è stato provato su un dispositivo.** Nessuna sessione vera, nessun Firestore,
  nessun Isar con dati reali.
- **Il collegamento corretto in 🔴 1 non è stato visto funzionare.** Ho corretto la causa
  ragionando sul ciclo di vita dei provider, e i test continuano a passare, ma **nessun
  test copre il percorso vero** (schermata → provider → Isar → foglio). Sarebbe un test
  di integrazione con un Isar finto, e non l'ho scritto: è il buco più grande che lascio
  in questa review.
- **La card dei record nel riepilogo non è stata vista comparire in un'app vera.** Il
  test la mostra passandole i record a mano; nel percorso reale i record li calcola la
  schermata dallo stream di Isar. **Da confermare sull'APK**, ed è la prova che chiude il
  criterio di US-049.
- **La fedeltà al mockup è giudicata leggendo il CSS e convertendo**, non sovrapponendo
  immagini.

---

## Cosa serve dall'utente

1. **Il criterio sul confronto carico + ripetizioni** (🔴 3): riformularlo in «il
   confronto è sul carico sollevato», o aprire una storia per il massimale stimato. Oggi
   non è soddisfatto e **non va spuntato**.
2. **Il criterio sulla storia dei record** (🟡 4): spostarlo su US-068 o tenere aperta
   US-050.
3. **Il secondo record dentro la stessa sessione** (🟡 5): errore da correggere o
   comportamento accettabile?
4. **`test/unit/`**: nuova convenzione o file da spostare in `test/`?
5. **La prova sull'APK**: battere un massimo durante una serie e vedere la riga; chiudere
   l'allenamento e vedere la card sotto lo scontrino.

---

_Review del 2026-08-07 · US-050 · condotta sul diff, da chi non ha scritto il codice_
