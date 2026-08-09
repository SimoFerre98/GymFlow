# US-022 — Review

**Storia:** Applicare il design system alle schermate principali · **Epic:** EP-005 · 3 punti
**Branch:** `feature/US-022-design-system-main-screens` · **Base:** `main` `52a3e50`
**Recensita il:** 2026-08-07

## ⚠️ Questa review è un'autoverifica

**L'ho implementata io.** Rileggo ciò che intendevo scrivere, che è il limite che
`HANDOFF.md` descrive e che la delega ad Agy serve a evitare. Le tre storie recensite oggi
su codice altrui hanno trovato **tre difetti che i test non prendevano**; qui quella lente
non c'è.

Quello che ho potuto fare per compensare: il criterio guida è **verificabile
meccanicamente** — 20 prove sul sorgente, con la controprova — quindi la parte più
importante non dipende dal mio giudizio. Quello che resta esposto è la **scelta dei ruoli**,
dove non c'è nessun test possibile e dove il giudizio è solo mio. Le decisioni sono elencate
sotto perché l'utente possa contraddirle.

**Verdetto: APPROVATA, con tre decisioni da confermare.**

---

## Verifica

| | Esito |
|---|---|
| `flutter analyze` | **63**, e il confronto riga per riga con `main` dà **zero avvisi nuovi** |
| `flutter test` | **368 verdi**, di cui **20 nuovi** |
| Valori a mano rimasti | `program_list` 0 · `calendar` 2 · `dashboard` 2 — e i quattro sono `Colors.transparent`, che il criterio ammette |
| Controprova | Rimessa un'ombra scritta a mano nella dashboard: **due test diventano rossi** |

Il conto di partenza, misurato prima di cominciare: **28 + 49 + 77 = 154 valori**, più di
quanto il piano stimasse (125), perché il piano era stato scritto prima di US-073.

---

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| Le tre schermate usano il componente card condiviso | ⚠️ **due su tre** | Test sul sorgente su `dashboard` e `program_list`. **Il calendario no**, e la ragione è nel rilievo 🟡 3 |
| Non esistono più `BoxDecoration` con ombre inline | ✅ | Test sul sorgente su tutte tre, con controprova. Le sei ombre — tre nel calendario, tre nella dashboard — vengono ora da `elevation.levelN(scheme.shadow)` e seguono il tema invece di essere nere per sempre |
| Le spaziature usano i token | ✅ | Test sul sorgente. **Ha trovato tre residui che il mio `grep` non prendeva**: vedi 🔵 5 |
| I colori provengono dai ruoli del `ColorScheme` | ✅ | Test sul sorgente, `Colors.transparent` escluso e motivato |
| L'aspetto resta corretto in tema chiaro e scuro | ❌ **da confermare sull'APK, nei due temi** | Nessuna delle tre schermate è montabile in un test: Firebase e stream dentro `build`, che sono US-008÷US-012 |
| La gerarchia emphasized è applicata ai titoli | ✅ | Test sul sorgente: `titleEmphasized` esisteva da US-033 e **non la usava nessuno** |

---

## Le tre decisioni che l'utente può contraddire

Non sono difetti: sono scelte che nessun test può giudicare e che ho preso io.

### 1. I colori delle tessere della dashboard

Erano **blu, arancione, viola, ambra, teal e rosso**. Nessuno in palette. Il criterio con cui
li ho riportati sui ruoli:

| Tessera | Prima | Ora | Perché |
|---|---|---|---|
| Sforzo percepito | ambra | **salmone** | È un dato vitale, ed è ciò a cui la palette riserva il salmone |
| Calorie | **rosso** | **salmone** | Idem. Il rosso era il ruolo dell'**errore** usato per un dato che va bene |
| Allenamenti, serie, volume, passi | blu, arancione, viola, teal | **indigo** | Sono conteggi: nessuno è un'azione, quindi nessuno porta l'ambra |
| Avvio rapido, avvio nel menu, giorno di oggi | blu / ambra | **ambra** | Sono le azioni, ed è l'unico significato dell'ambra |

**Il costo**: quattro tessere che avevano quattro tinte ora ne hanno due. La distinzione
resta affidata a icona e etichetta. **Se preferisci quattro tinte distinte è
un'estensione della palette**, non qualcosa che dovevo inventare: si cambia in cinque righe.

### 2. Gli eventi del calendario

Viola per gli amici, verde per il fatto, arancione per il da fare. Ora: **ambra** per il da
fare (è ciò che devi fare), **`onSurfaceVariant`** per il fatto (ciò che è concluso
arretra), **indigo** per gli eventi degli amici (non è una tua azione). Il salmone è restato
fuori: un evento in calendario non è un dato vitale.

US-064 «calendario che distingue i tipi» potrà rivedere questa scala con più informazione di
quanta ne abbia io adesso.

### 3. La pillola «ATTIVA» della lista allenamenti

Era **verde acceso**. Ora è ambra, perché indica la scheda su cui ti stai allenando adesso.
È l'unico punto dove ho usato l'ambra per qualcosa che non è un pulsante, e il ragionamento
è che «cosa fare adesso» include «dove sei».

---

## Rilievi

### 🟡 1 — Il calendario non usa la card condivisa, e non deve

Il criterio dice «le tre schermate usano il componente card condiviso». Il calendario **non
lo usa**, e il test sul sorgente lo verifica solo sulle altre due.

Le sue righe sono **vetro sfocato con un bordo luminoso** — `BackdropFilter`, fondo al 30% o
50%, bordo `onSurface` al 5% — e `ExpressiveCard` porta un fondo opaco. Coprire il caso
significherebbe aggiungere parametri alla card condivisa, ed è **precisamente il punto in cui
un componente condiviso comincia a marcire**: lo diceva già la review di US-021, e il piano
di questa storia lo ripete fra le alternative scartate.

Il criterio resta **parzialmente soddisfatto e dichiarato tale**. La domanda vera — se il
vetro sfocato sia la direzione o un residuo — appartiene a US-064.

### 🟡 2 — Le larghezze fisse del segmentato della dashboard

`width: 300` per il contenitore e `width: 150` per la pillola dentro, con il commento
originale «Half of 300». Non le ho toccate: sono una scelta di impaginazione che precede il
design system, non un valore da token, e la seconda dipende dalla prima.

**Ma è un rischio vero**: su uno schermo stretto un segmentato da 300 dp fisso può uscire
dai margini. Cambiarlo significa renderlo responsivo, cioè **spostare un elemento**, e il
piano lo vieta esplicitamente («se qualcosa si muove a schermo oltre il colore e la
spaziatura, è un difetto di questa storia»). Va guardato sull'APK, e se dà problemi è una
storia sua.

### 🟡 3 — La dashboard usa `Colors.transparent` due volte, e una è discutibile

`Material(color: Colors.transparent)` nello storico serve a far disegnare l'onda del tocco
sopra la decorazione: è l'idioma corretto. `backgroundColor: Colors.transparent` sul foglio
modale è lo stesso caso. Li ho ammessi nel test perché «non disegnare niente» non è una
scelta di colore.

**Il rischio del test**: chi in futuro vorrà davvero un colore letterale può scrivere
`Colors.transparent` e passare. Non c'è modo di distinguere l'idioma dall'abuso leggendo il
sorgente, e l'alternativa — vietarlo del tutto — romperebbe tre usi legittimi.

### 🔵 4 — `titleEmphasized` era codice morto da US-033

Esisteva da quando il design system è stato fondato e **non la usava nessuno**. Ora è sui
titoli delle tre schermate. Vale annotarlo perché è il secondo token che scopro non usato
(dopo `typography.metric*`, che US-046 ha iniziato a usare): il design system è più grande
di ciò che le schermate ne prendono.

### 🔵 5 — Il mio `grep` era incompleto, e il test l'ha corretto

Durante il lavoro ho misurato i residui con un `grep` che **non copriva `EdgeInsets.only`**.
Quando ho scritto il test sul sorgente, con una regex più larga, sono usciti **tre residui
che credevo di aver finito**: i padding di coda della dashboard e del calendario, e un
margine orizzontale.

Lo scrivo perché è la dimostrazione del perché il criterio guida doveva essere un test e non
un controllo a mano: **il mio controllo a mano ha sbagliato**, e il test no.

### 🔵 6 — Un errore mio nel percorso, per completezza

Convertendo il calendario ho dimenticato l'import dei token e `flutter analyze` è passato a
**75** con dodici errori `undefined_getter`. Non l'ho visto subito perché avevo guardato solo
la coda dell'output del singolo file, e gli errori stavano più in alto. Da lì in poi ho
confrontato l'elenco completo con quello di `main` invece di leggere il totale.

---

## Regressioni sospette

**Le stringhe scritte nel codice restano.** `'Welcome back,'`, `'Start Workout'`,
`'Error loading programs'`, `'${...} Exercises'`: sono decine e il piano le mette
esplicitamente fuori scope. **Non le ho toccate**, quindi la dashboard continua a mostrare
testo inglese con l'app in italiano. Appartiene a US-026.

**`_buildStatCard` e `_buildStatColumn` ora prendono `BuildContext`.** Era necessario per
leggere i token, e i quattro più due chiamanti sono stati aggiornati. Nessun altro le chiama:
verificato con `grep`.

**I gradienti del calendario** usano già `colorScheme.surface`: non toccati.

**Il colore scelto dall'utente per una scheda** resta il suo. Solo il **ripiego** — il blu di
Material — è diventato un ruolo.

---

## Limiti di questa review

- **È un'autoverifica**, come scritto in apertura.
- **Niente è stato guardato sull'APK**, né in tema scuro né in tema chiaro. Ed è il criterio
  che conta di più per una storia che non cambia nessun comportamento: l'unica cosa che fa è
  cambiare l'aspetto, e l'aspetto non l'ho visto.
- **Il tema chiaro è il caso più esposto.** Tutte le mie scelte le ho ragionate sul tema
  scuro, che è quello predefinito. In tema chiaro `primary` è `amberOnLight`, un marrone
  scuro — `DESIGN-SPEC.md` avverte che chi lo usa come **fondo** ottiene una superficie che
  il mockup non prevede. Ho usato `primary` come fondo in due punti: il pulsante di avvio
  rapido e la pillola del segmentato. **Vanno guardati in tema chiaro.**
- **Non ho contato i valori a mano rimasti fuori dai pattern del test.** `width: 60`,
  `size: 32`, `blurRadius` dentro i gradienti: il test non li cerca, e non ho fatto un
  passaggio esaustivo a occhio su 1818 righe.

---

## Cosa serve dall'utente

1. **Le tre decisioni sui ruoli** qui sopra: confermarle o cambiarle.
2. **La prova sull'APK nei due temi**, con attenzione ai due fondi ambra in tema chiaro.
3. Uno sguardo al **segmentato da 300 dp** su schermo stretto.

---

_Review del 2026-08-07 · autoverifica dichiarata · il criterio guida è meccanico, le scelte di ruolo no_
