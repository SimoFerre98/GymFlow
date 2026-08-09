# US-077 — Review

**Storia:** Le date localizzate non fanno crollare la lista degli allenamenti · **Epic:** EP-003 · 1 punto
**Branch:** `fix/US-077-intl-date-formatting` · **Base:** `main` `83ebdd5`
**Implementata da:** Agy (Antigravity), con l'utente come tramite
**Recensita il:** 2026-08-07 · **Chi:** orchestratore, che non ha scritto il codice

**Verdetto: APPROVATA.** Il diff è di 32 righe, fa esattamente quello che il piano
chiedeva, e non tocca niente fuori dai due file previsti.

**È la prima storia del progetto implementata da un esecutore esterno**, e vale annotare
come è andata: bene, con un buco nella verifica che la review ha colmato.

---

## Verifica, rifatta

Il rapporto di consegna dichiarava `analyze: sconosciuto`, perché `flutter pub get` si è
interrotto per **permessi mancanti sui symlink su Windows**. Quindi il controllo più
importante del progetto — il baseline degli avvisi — non era stato eseguito. L'ho fatto io.

| | Dichiarato da Agy | Misurato da me |
|---|---|---|
| `flutter analyze` | **sconosciuto** | **63**, e il confronto riga per riga con `main` dà **zero avvisi nuovi** |
| `flutter test` | 350 verdi | **350 verdi** ✅ |
| File toccati | 2 | 2 ✅ |
| Fuori piano | nessuno | nessuno ✅ |

**Il numero dei test coincide e il baseline regge.** Il rapporto era onesto dove non
sapeva, che è la cosa che conta: ha scritto «sconosciuto» invece di inventare 63.

---

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| Una scheda con data di inizio e fine non solleva eccezioni | ✅ **in due pezzi** | Vedi il rilievo 🟡 1: il test funzionale prova che `intl` funziona una volta inizializzato, il test sul sorgente prova che `main` lo inizializza. La schermata vera non è montabile |
| La scelta è dichiarata | ✅ | Test sul sorgente su `lib/main.dart`. **Controprova rifatta da me**: togliendo la chiamata il test diventa rosso, e con la chiamata torna verde |
| Nessun altro punto usa `DateFormat` con una locale non inizializzata | ✅ | Agy ha dichiarato il test troppo fragile e si è limitato a un `grep`, che è **esattamente la via d'uscita che il piano autorizzava**. Il `grep` l'ho rifatto io: `program_list_screen.dart:254` è l'unico punto con un argomento di locale. Tutti gli altri usano `DateFormat('pattern')` senza locale, che è sicuro |

---

## Rilievi

### 🟡 1 — Solo uno dei due test è un guardiano

Il primo test chiama `initializeDateFormatting()` **da sé**, quindi passerebbe anche se
`main.dart` non inizializzasse niente: prova che `intl` funziona una volta inizializzato,
cosa che non era in dubbio. Il vero guardiano della regressione è il secondo, quello sul
sorgente.

Agy l'ha capito e l'ha scritto nel rapporto: alla riga «Test rotto» dice che togliendo la
chiamata **è il test sul sorgente** a diventare rosso. È la risposta giusta, e mostra che
sapeva quale dei due stesse reggendo il criterio.

Ho aggiunto ai test il commento che lo dice, perché fra sei mesi non è ovvio, e perché
qualcuno potrebbe «semplificare» il test sul sorgente credendolo ridondante.

*Perché non ho chiesto di più:* la schermata delle schede non si monta in un test —
Firebase e stream dentro `build`, che sono US-008÷US-012 — quindi la prova a due pezzi è la
migliore disponibile a un punto di costo.

### 🔵 2 — `await` su una funzione sincrona

`await initializeDateFormatting();`. La funzione restituisce `void`: l'attesa non serve, e
il piano l'aveva scritto in anticipo fra i rischi («se il compilatore chiede un `await`,
hai importato la cosa sbagliata»). Il compilatore non lo chiedeva. Rimosso, insieme
all'`async` del test che esisteva solo per lui.

Non cambia niente al comportamento, ma un `await` inutile fa credere a chi legge che ci sia
un'operazione asincrona da aspettare.

### 🔵 3 — Le altre date dell'app restano in inglese

Questa storia rimuove il crash, non localizza le date. I nove punti che usano
`DateFormat('MMM d, yyyy')` e simili **senza** argomento di locale continuano a formattare
con la locale predefinita, cioè in inglese, anche con l'app in italiano. `initializeDateFormatting()`
carica i dati ma non cambia la locale predefinita.

Non è una regressione — era già così — e non è questa storia. Appartiene a **US-026** e
**US-027**, che localizzano le stringhe delle schermate. Lo scrivo perché ora che i dati
sono caricati la correzione è diventata banale: basta `Intl.defaultLocale`.

### 🔵 4 — Il peso del pacchetto non è stato misurato

`date_symbol_data_local` porta i dati di tutte le locale. Il piano lo aveva dichiarato come
prezzo accettato e aveva detto esplicitamente che misurarlo **non** era un criterio. Non è
stato misurato, coerentemente. Se un giorno il peso del pacchetto diventasse un tema, la
riduzione alle sole EN e IT è un cambio di una riga.

---

## Fuori piano rilevato

**Nessuno.** Due file previsti, due file toccati. In particolare `program_list_screen.dart`
non è stato toccato — il piano lo vietava perché è aperto sul branch di US-022 — e i mesi
scritti a mano di `workout_summary_screen.dart` sono ancora al loro posto, come chiesto.

---

## Regressioni sospette

**L'ordine nel `main`.** `initializeDateFormatting()` sta fra
`WidgetsFlutterBinding.ensureInitialized()` e `Firebase.initializeApp`, che è dove il piano
suggeriva. Non dipende da Firebase e Firebase non dipende da lei.

**Le date già formattate senza locale.** Verificato che `initializeDateFormatting()` carica
i dati senza toccare la locale predefinita: i nove punti che usano `DateFormat('pattern')`
si comportano esattamente come prima. Nessuna data cambia aspetto a sorpresa.

---

## Limiti di questa review

- **La schermata non è stata aperta con una scheda che ha le date.** È la prova che
  chiuderebbe il criterio per davvero, e richiede di creare una scheda con data di inizio
  sul dispositivo. **Da confermare sull'APK.**
- **Non ho verificato l'aumento di peso dell'APK** rispetto a prima, coerentemente col
  piano che lo escludeva.
- **Il problema dei symlink che ha bloccato `flutter pub get` da Agy non è stato
  investigato.** Se si vuole delegare di nuovo, quello va risolto: un esecutore che non può
  eseguire `analyze` consegna senza il controllo che questo progetto considera decisivo.

---

## Nota sul primo giro di delega

Cosa ha funzionato: il piano è stato seguito alla lettera, i confini rispettati, i commit
in italiano con il codice storia, e le due righe che avevo aggiunto al formato del rapporto
— «Test rotto» e «Dubbi» — hanno prodotto esattamente l'informazione che servivano a
produrre.

Cosa va sistemato prima del prossimo giro: **i permessi sui symlink su Windows**, altrimenti
ogni consegna arriverà con `analyze: sconosciuto` e il baseline resterà una verifica che fa
solo chi rivede.

---

_Review del 2026-08-07 · US-077 · numeri rimisurati, controprova rifatta_
