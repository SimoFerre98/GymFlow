# US-042 — Review

**Verdetto:** APPROVATA CON RISERVE
**Diff esaminato:** `git diff main...HEAD` · 14 file, +1780 / −15
**Verifica:** `flutter analyze` **66 avvisi, zero errori** (baseline invariato) · `flutter test` **195 test verdi** (erano 102) · `flutter build apk --debug` **riuscita**

La riserva non riguarda il codice: riguarda **un criterio che questa storia non può dimostrare da
sola** e uno che richiede la prova sul telefono. Sono i punti 1 e 6 della tabella qui sotto.

---

## Copertura dei criteri

| # | Criterio | Esito | Prova |
|---|---|---|---|
| 1 | Esiste un widget unico che decide quale immagine mostrare, **usato da tutte le schermate** | ⚠️ **parziale, per costruzione** | `ExerciseImage` esiste ed è l'unico punto che decide. Ma è usato **solo dal catalogo del design system**: portarlo nelle liste è letteralmente il primo criterio di US-043, e anticiparlo avrebbe reso impossibile dire quale storia ha fatto cosa. **Non spuntabile qui.** Si chiude con US-043 |
| 2 | Ordine rispettato: utente → curata → miniatura → segnaposto | ✅ | `exercise_media_test.dart`, gruppo «catena completa dei candidati»: 10 test, incluso il caso con tutti e tre gli anelli presenti che verifica la lista esatta. Più il cammino a schermo in `exercise_image_test.dart` |
| 3 | La miniatura è costruita dall'identificativo, senza che nessuno la carichi | ✅ | `heroCandidates` e `thumbnailCandidates` derivano da `YouTubeVideo.thumbnailUrl`, che è una funzione pura sull'ID. Nessuna richiesta di rete serve per ottenerla |
| 4 | Il segnaposto deriva colore e sagoma dal gruppo muscolare, mai un rettangolo vuoto | ✅ | `muscle_group_visuals_test.dart`: 22 test sui nomi reali dei **due** vocabolari, più determinismo del ripiego e unicità di tinte e sagome. `exercise_image_test.dart` verifica che anche un esercizio **senza gruppi** disegni una sagoma |
| 5 | Un'immagine che non si carica ripiega sull'anello successivo | ✅ | `exercise_image_test.dart`, gruppo «cammino della catena»: 5 test, incluso il percorso completo dei tre anelli e il caso in cui tutti falliscono |
| 6 | Senza rete si mostra la cache, e in sua assenza il segnaposto | ⚠️ **metà provata, metà da confermare** | Il ramo «in sua assenza il segnaposto» è coperto da test. Il ramo «si mostra la cache» **non è dimostrabile in un widget test**: richiede una prima visita con rete, un riavvio e la modalità aereo. Da confermare sull'APK |
| 7 | Le immagini remote sono memorizzate in cache: la seconda visita non ripete la richiesta | ✅ **strutturale, con una verifica in più** | Il provider predefinito è `CachedNetworkImageProvider` (test). E soprattutto: ho letto il sorgente del package (`cached_network_image_provider.dart:176`) per verificare che `==` confronti l'URL. Se non lo facesse, ogni ricostruzione avrebbe riavviato il caricamento — cioè il contrario del criterio. **Verificato, non dedotto** |
| 8 | (aggiunto) La sagoma è leggibile sul segnaposto | ✅ | `contrast_test.dart`: 21 test nuovi. Ogni tinta contro il neutro della sagoma ≥ 3:1 (WCAG 1.4.11), **sia sulla tinta piena sia sull'estremo scuro del gradiente** |

---

## Cosa ha trovato la review

### 🔴 Un difetto reale, trovato dai test e corretto

**Un solo fallimento consumava due anelli.** Il test «lo stesso fallimento non consuma due anelli»
è fallito con tre richieste invece di due.

Causa: `Image` conserva la propria eccezione nello stato. Cambiando solo il provider, l'elemento
veniva riusato e `errorBuilder` scattava di nuovo con l'errore **vecchio** appena l'anello cambiava.
Con tre anelli e un solo errore, la catena arrivava al terzo saltando il secondo.

Corretto con una `ValueKey(url)` sull'`Image`: un elemento nuovo per ogni anello, stato pulito.
[`exercise_image.dart:169`](../../lib/src/ui/widgets/exercise_image.dart#L169)

Da notare: senza il test scritto **prima** di guardare il codice, questo difetto sarebbe arrivato
in produzione e si sarebbe manifestato come «a volte il segnaposto compare anche se l'immagine
curata esiste». Praticamente impossibile da diagnosticare a posteriori.

### 🔴 Un assert evitabile, trovato rileggendo il diff

`decodeWidth: 0` avrebbe fatto scattare l'assert interno di `ResizeImage` in debug. Nessun chiamante
oggi passa zero, ma US-043 calcolerà la larghezza dai token, e un token letto male vale zero.
Trattato come «nessuna richiesta di scala».
[`exercise_image.dart:143`](../../lib/src/ui/widgets/exercise_image.dart#L143)

### 🟡 Il catalogo del design system ora fa richieste di rete

La sezione nuova carica tre miniature reali da `img.youtube.com`. È deliberato — senza pixel veri
non si vede quale anello ha vinto — e vale **solo in debug**, perché la schermata è protetta da
`kDebugMode`. Ma è un cambiamento di natura di quella schermata, che finora era interamente
offline. Se dà fastidio, si sostituisce con tre asset locali, al prezzo di ~60 KB nell'APK.

### 🟡 Il segnaposto non cambia con il tema

Le sette tinte sono identiche in chiaro e in scuro. La ragione è nel piano: sta al posto di una
fotografia, e una fotografia non cambia quando l'app passa da chiaro a scuro. **Ma non è stato
giudicato a occhio nel tema chiaro**, solo misurato. Va guardato sull'APK. Se stona, la decisione
appartiene a US-022.

### 🔵 Il segnaposto resta disegnato sotto l'immagine

`frameBuilder` tiene il segnaposto nello `Stack` anche dopo che l'immagine è comparsa: garantisce
che non ci sia mai un buco, al prezzo di un gradiente e un'icona disegnati dietro pixel opachi.
Costa quanto gli elementi **visibili** (cinque o sei in una lista, non cento), quindi non è stato
ottimizzato. Se il criterio dei 55 fps di US-043 risultasse in bilico, questo è il primo posto dove
guardare: togliere il segnaposto al termine della dissolvenza richiede solo `AnimatedOpacity.onEnd`.

### 🔵 `ExerciseImageSize.hero` esiste e nessuno in `lib/` la usa

È l'altra metà del modello di US-041 (`heroImageUrl` esisteva già) e serve a US-044 e US-062.
Coperta da test, non da chiamanti. Se non venisse usata entro quelle due storie, va tolta.

---

## Fuori scope rilevato nel diff

| Modifica | Perché è lì |
|---|---|
| `macos/Flutter/GeneratedPluginRegistrant.swift` (+2) | **Generato da `flutter pub get`**, non scritto a mano: registra `sqflite_darwin`, che arriva con la dipendenza approvata. Il file è versionato nel repository, quindi lasciarlo fuori dal commit avrebbe reso il repository incoerente con `pubspec.lock`. macOS non è un target attivo |
| `pubspec.lock` (+88) | Conseguenza diretta della dipendenza |

Nessun'altra modifica fuori dall'elenco del piano. Le tre schermate con le liste di esercizi
**non sono state toccate**: `git diff main...HEAD --stat` non le contiene.

---

## Checklist adversariale

| Domanda | Risposta |
|---|---|
| Dato assente, lista vuota? | Coperto: nessun candidato → segnaposto; nessun gruppo muscolare → regione dal nome; nome vuoto → regione stabile. Tre test |
| Rete assente? | I candidati falliscono a uno a uno, resta il segnaposto. Nessuna eccezione propagata: `errorBuilder` è sempre fornito |
| Utente non autenticato? | Il widget non legge né Firestore né Auth. Riceve un `Exercise` e disegna |
| Risorse rilasciate? | Nessun controller, nessuna sottoscrizione, nessun timer. L'unica cosa asincrona è `addPostFrameCallback`, protetta da `mounted` |
| `Stream` o `Future` creato dentro `build`? | No. `ImageProvider` è un descrittore, non un caricamento: due provider uguali condividono lo stesso stream nella cache di Flutter (verificato sul sorgente, vedi criterio 7) |
| Effetti collaterali in `build`? | `_advanceFrom` è chiamato da `errorBuilder`, che gira **durante** la costruzione. Per questo non chiama `setState` direttamente ma rimanda al frame successivo. È l'unica via: l'errore di un'immagine si scopre solo mentre si disegna |
| Ciclo infinito possibile? | No: `_attempt` cresce e non torna indietro, e il segnaposto è terminale. Verificato dal test che conta le richieste quando tutti gli anelli falliscono |
| Riciclo delle celle in una lista? | Il rischio più concreto di questo widget, e ha due test suoi: un esercizio nuovo riparte dal primo anello, lo stesso esercizio non fa ripartire la catena |
| Convenzioni di `CLAUDE.md`? | Colori solo in `app_palette.dart`; spaziature e raggi da `context.expressive`; nessuna stringa visibile nuova (motivato: l'immagine è decorativa accanto al nome); `const` dove il compilatore lo consente |
| Segreti, credenziali, percorsi locali nel diff? | Nessuno. Gli unici indirizzi sono `img.youtube.com`, `youtube.com` e `gymflow.invalid` — un TLD riservato da RFC 2606, che non risolve mai |
| Comprensibile fra sei mesi senza contesto? | Il punto più opaco è la `ValueKey(url)` sull'`Image`: senza il commento sopra sembrerebbe superflua e qualcuno la toglierebbe, riaprendo il difetto. Il commento spiega cosa si rompe |
| Qualcosa può rompere una funzionalità non testata? | `thumbnailUrl` e `heroImageUrl` hanno cambiato implementazione. Chi li chiamava (nessuno in `lib/`, solo i test di US-041) ottiene lo stesso valore, **tranne** per URL non `http(s)`, che ora danno `null` invece della stringa. È il comportamento voluto e ha un test |

---

## Limiti dichiarati

1. **Il criterio 1 non è soddisfatto da questa storia** e non lo sarà finché US-043 non porterà il
   widget nelle liste. Non è spuntato.
2. **«Senza rete si mostra la cache» non è provato da un test.** Serve: prima visita con rete →
   chiusura dell'app → modalità aereo → riapertura. È una prova manuale, sull'APK.
3. **Nessuna immagine reale viene decodificata nei test.** I due provider finti falliscono o
   restano in attesa: bastano a verificare *la catena*, che è ciò che abbiamo scritto. Che Flutter
   sappia disegnare un JPEG non lo riverifichiamo. La conseguenza va detta: **il caso «l'immagine
   arriva e si vede» è verificato solo sull'APK**, nel catalogo.
4. **La pertinenza delle miniature non è giudicata.** Restano i 15 video su 43 e il limite di
   US-041: la pertinenza è valutata dal titolo, non guardando i video.
5. **Nessuna misura di prestazioni.** Il criterio sui fps è di US-043 e lì va affrontato.
6. **La review è un'autoverifica.** L'ha scritta chi ha scritto il codice. Ha trovato due difetti
   reali, ma il controllo vero resta la prova sull'APK.

---

## Da confermare sull'APK

Percorso: **menu → Design system → sezione «Immagini degli esercizi»**.

1. I primi tre riquadri mostrano **tre fotogrammi diversi**: dimostra che l'anello che vince è
   quello giusto e non sempre lo stesso.
2. Il quarto («curata rotta») mostra **la stessa immagine del primo**: il ripiego funziona con la
   rete vera, non solo con un provider finto.
3. Il quinto mostra il segnaposto del torace.
4. La fila delle sette regioni: colori distinguibili, sagome riconoscibili, nessuno stona con
   l'ambra.
5. **Cache e offline**: aprire la sezione con rete, chiudere l'app, attivare la modalità aereo,
   riaprire. I quattro riquadri devono mostrare ancora le immagini.
6. Lo stesso in tema chiaro, per il segnaposto.

---

_Review del 2026-08-06 · fase 5 del ciclo in [`WORKFLOW.md`](../WORKFLOW.md)_
