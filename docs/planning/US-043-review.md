# US-043 — Review

**Verdetto:** APPROVATA CON RISERVE
**Diff esaminato:** `git diff main...HEAD` · 14 file, +1000 / −31
**Verifica:** `flutter analyze` **66 avvisi, zero errori** (baseline invariato) · `flutter test` **214 test verdi** (erano 195) · `flutter build apk --debug` e `--profile` **riuscite**

La riserva è **una sola e concreta**: il criterio sui 55 fps non è ancora misurato. La misura è
preparata e richiede il telefono sbloccato — vedi la sezione finale. Non è spuntato.

---

## Copertura dei criteri

| # | Criterio | Esito | Prova |
|---|---|---|---|
| 1 | Le liste di esercizi mostrano la miniatura secondo la catena di ripiego | ✅ nel codice, **da confermare a schermo** | Le tre schermate usano `ExerciseThumbnail`: `exercise_library_screen.dart:195`, `workout_creator_screen.dart:603`, `active_session_screen.dart:320`. La catena è coperta dai 20 test di US-042; la risoluzione per identificativo ha 4 test suoi. Che si vedano davvero è una prova a schermo |
| 2 | Un esercizio con video porta un indicatore riconoscibile sulla miniatura | ✅ | 5 test: video vero → indicatore; **sola ricerca → nessun indicatore**; niente → nessuno; URL non YouTube → nessuno; più l'etichetta di accessibilità. Contrasto del simbolo sul fondo del badge ≥ 3:1 in entrambi i temi |
| 3 | Lo scorrimento di una lista di 100 esercizi resta sopra i 55 fps in profile mode | ⚠️ **non misurato** | APK profile costruito e installato, lista dei 100 pronta nel catalogo, procedura di misura scritta. **Manca l'esecuzione**: il telefono è bloccato e non tocco un blocco protetto. Le tre leve strutturali sono in codice e verificate da test (`decodeWidth`, `itemExtent`, `select`), ma **una leva non è una misura** |
| 4 | Le immagini si caricano progressivamente senza far saltare il layout | ✅ | Test: la misura della miniatura è identica prima del fotogramma, dopo un `pump` e dopo un secondo. E un esercizio con immagine e uno senza occupano lo stesso spazio, quindi i nomi non si allineano su due colonne |
| 5 | La miniatura ha dimensione e forma dai token del design system | ✅ | 4 test: il lato è `sizing.thumbnailMd`, gli angoli sono `shape.cornerMd`, `decodeWidth` combacia con la misura. Un valore scritto a mano li farebbe fallire |

---

## Cosa ha trovato la review

### 🔴 Il provider trascinava Firebase dentro i test — e ha rivelato un limite reale

Il primo test di `ExerciseThumbnailById` è fallito con
`[core/no-app] No Firebase App '[DEFAULT]' has been created`: guardare l'indice risale a
`currentUserIdProvider`, che chiama `AuthService()` e quindi Firebase.

Nei test si risolve con un override dell'indice, che è anche ciò che ha permesso di provare il caso
**positivo** — un esercizio presente nell'indice mostra il suo indicatore — che senza lo stub non
era verificabile.

Ma il limite resta e va detto: **`ExerciseThumbnailById` non è disegnabile senza Firebase
inizializzato.** Nell'app è sempre inizializzato in `main.dart` prima di `runApp`, quindi non è un
difetto operativo; è un vincolo da conoscere per chi scriverà i primi test di schermata. La causa è
`currentUserIdProvider`, che istanzia `AuthService()` a mano — debito di US-008 e US-009, non
introdotto qui.

### 🔴 Il baseline degli avvisi si era alzato a 68, e la causa non era ovvia

Il provider scritto come funzione (`@riverpod Stream<...> exercises(ExercisesRef ref)`) fa emettere
al generatore un typedef su `AutoDisposeStreamProviderRef`, **deprecato**: due avvisi in più.
Sei dei 66 avvisi del baseline sono esattamente questi, sui provider scritti prima.

Riscritto come notifier di classe, che non genera quel typedef: **66**. La forma di classe non è un
vezzo, è ciò che tiene il conto degli avvisi dove deve stare — e i sei preesistenti diventano un
lavoro per US-030 invece di crescere.

### 🔴 Una miniatura da 56 dentro una cella da 72: sette pixel per parte

Il diff mostra `ListTile(leading: ExerciseThumbnail(...))`, e nessun test guardava una cella vera.
È il posto tipico di un `RenderFlex overflowed`. Aggiunti due test che montano un `ListTile` nelle
due forme reali — due righe come la libreria, tre righe come la scheda — e verificano che non venga
sollevata nessuna eccezione. **Passano**, ma la verifica non c'era e il rischio era reale.

### 🟡 Nella scheda il numero d'ordine è scomparso

`workout_creator_screen.dart:603`: il cerchio con `${index + 1}` è diventato la miniatura.

È deliberato — in una lista riordinabile la posizione **è** l'ordine, e la maniglia di trascinamento
resta in coda — ma è **informazione rimossa da una schermata**, non solo informazione aggiunta. Se
il numero serve (per leggere una scheda al telefono, per dettarla a qualcuno), va rimesso come
prefisso del titolo. È una decisione di prodotto, non tecnica.

### 🟡 `DesignCatalogScreen.isAvailable` non è più `kDebugMode`

Da `kDebugMode` a `!kReleaseMode`: senza questo, in profile mode la schermata non esiste e il
criterio 3 non è misurabile per definizione. Le build di release restano senza catalogo, che era il
punto di US-033. Ma è una decisione di US-033 modificata da US-043, e chi legge quella storia non
lo sa: **annotato qui perché sia rintracciabile**.

### 🔵 `itemExtent` è solo sulla lista di prova, non sulle liste vere

Il piano lo prevedeva «sulle liste a celle uguali». Nella libreria non è stato applicato: le celle
sono `Card` con sottotitolo di altezza variabile e un `Dismissible` attorno, e un'estensione
sbagliata **taglia il contenuto**. La leva che conta lì è `decodeWidth`, che è dove sta il costo
vero (decodificare 480 px per disegnarne 56). Deviazione dal piano, dichiarata.

### 🔵 L'indice apre l'ascolto di Firestore anche a chi guarda una sola miniatura

Aprire una scheda ora attiva lo stream degli esercizi. È lo stream che la libreria usa già e Riverpod
lo condivide, quindi non sono ascolti nuovi se le due schermate convivono — ma una scheda aperta da
sola oggi costa un ascolto che prima non costava. Accettato: è il prezzo di non denormalizzare.

---

## Fuori scope rilevato nel diff

Nessuna modifica fuori dall'elenco del piano. In particolare:

- I difetti noti delle tre schermate **non sono stati toccati**: stream dentro `build`, servizi
  istanziati a mano, `Colors.grey[...]`. Il diff su quei file è di 7, 14 e 21 righe.
- `build_runner` ha rigenerato tutti i `.g.dart`, ma **solo quello nuovo è cambiato**: verificato con
  `git show --stat`, gli altri non compaiono nel commit.

---

## Checklist adversariale

| Domanda | Risposta |
|---|---|
| Dato assente, lista vuota? | Indice vuoto → segnaposto dal nome (test). Nome vuoto → regione stabile comunque. Esercizio cancellato → come indice vuoto |
| Utente non autenticato? | `Exercises.build` restituisce lista vuota se `currentUserIdProvider` è nullo, invece di chiedere a Firestore con un id nullo |
| Rete assente? | Cache su disco di US-042, e in sua assenza il segnaposto |
| Risorse rilasciate? | Nessuna risorsa nuova. I due provider sono `autoDispose`: l'ascolto si chiude quando l'ultima miniatura esce dall'albero |
| `Stream` o `Future` dentro `build`? | Lo stream vive nel provider, non in `build`. Nelle tre schermate gli stream preesistenti **restano dentro `build`**: è il debito di US-010÷US-012 e non è stato peggiorato |
| Effetti collaterali in `build`? | No |
| Ricostruzioni a cascata su cento celle? | Il punto a cui ho guardato di più. `select` sulla singola voce: l'arrivo di un esercizio non ricostruisce le celle degli altri. Senza, cento celle si ricostruivano a ogni aggiornamento dell'indice |
| Convenzioni di `CLAUDE.md`? | Servizi dai provider (il provider nuovo li prende da `firestoreServiceProvider`); nessun colore letterale; nessun valore numerico — la misura è un token nuovo, che è il motivo per cui è stato aggiunto; stringa nuova con chiave EN **e** IT |
| La stringa nuova è tradotta in entrambe le lingue? | Sì: `video_available` in `_en` e in `_it`. Il test la cerca per etichetta semantica in italiano, che è la lingua predefinita |
| Segreti o percorsi locali nel diff? | Nessuno. Gli unici indirizzi sono i quattro identificativi YouTube verificati e `gymflow.invalid` |
| Qualcosa può rompere una funzionalità non testata? | **La sessione attiva è la schermata più delicata dell'app** e non ha test. Il diff lì è di sette righe che aggiungono un widget dentro una `Row`: non toccano stato, cronometro né salvataggio. Da provare con una sessione vera |
| Comprensibile fra sei mesi? | Il punto opaco è perché i provider sono notifier di classe invece di funzioni: c'è un commento che lo spiega, altrimenti qualcuno li «semplificherebbe» e riporterebbe il baseline a 68 |

---

## Limiti dichiarati

1. **Il criterio 3 non è misurato.** Vedi sotto: è preparato, non eseguito.
2. **Nessuna delle tre schermate ha un test di schermata.** Non ne aveva prima e non ne ha ora:
   richiedono Firebase e i loro stream stanno dentro `build`. I test coprono il widget, non le
   schermate. La prova che le liste mostrino davvero le miniature **è sull'APK**.
3. **In Firestore ci sono otto esercizi, senza immagini né video.** Sul telefono la libreria mostrerà
   otto segnaposti e nessun indicatore: è il comportamento corretto, non un difetto. La libreria
   curata arriva con US-045.
4. **La lista dei 100 è materiale finto.** Misura il costo di decodifica e di scorrimento, non il
   comportamento con dati reali.
5. **La review è un'autoverifica.** Ha trovato tre difetti reali, di cui due che avrebbero superato
   il merge silenziosamente (il baseline a 68 e l'assenza di verifica sulla cella).

---

## La misura che manca, e come si fa

Tutto è pronto: **APK profile installato sul telefono** e lista dei 100 esercizi nel catalogo.
Serve il telefono sbloccato — un blocco protetto non lo tocco.

Percorso: **menu → Design system → «100 esercizi (prova di scorrimento)»**.

Poi, da qui:

```bash
adb shell dumpsys gfxinfo com.example.gymflow reset
# scorrere la lista per una decina di secondi, avanti e indietro
adb shell dumpsys gfxinfo com.example.gymflow | head -40
```

Lettura: 55 fps ⟺ **18,2 ms** per frame. Si guardano il 95° percentile dei tempi di frame e la
percentuale di frame «janky». Il telefono può disegnare a 120 Hz, quindi il suo bilancio è 8,3 ms:
un 95° percentile sotto 18,2 ms soddisfa il criterio con margine, sopra lo nega.

Se la misura non si può fare, il criterio resta **da confermare** con le tre prove strutturali, e
non si spunta.

### Da confermare sull'APK, oltre alla misura

1. **Libreria**: otto segnaposti, colori diversi per gruppo muscolare, nessun indicatore.
2. **Scheda**: le miniature compaiono e il numero d'ordine non c'è più — è il rilievo 🟡 da decidere.
3. **Sessione attiva**: la miniatura nella testata non ha spostato il pulsante di eliminazione, e il
   cronometro continua a scorrere.
4. **Lista dei 100**: le miniature con video hanno l'indicatore, quelle con URL rotto ripiegano sul
   segnaposto, il layout non salta durante il caricamento.

---

_Review del 2026-08-06 · fase 5 del ciclo in [`WORKFLOW.md`](../WORKFLOW.md)_
