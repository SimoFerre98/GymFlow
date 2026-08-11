# US-094 — Review

**Data:** 2026-08-11 · **Branch:** `feature/US-094-session-timer-button`
**Commit rivisti:** la consegna di Gemini (mai committata) + `991f1c3` (le correzioni)
**Chi ha implementato:** Gemini · **Chi rivede:** non ha scritto il codice consegnato

**Verdetto: RESPINTA alla consegna, APPROVATA dopo le correzioni** fatte in questa review.
Il codice consegnato era quasi giusto; i test che lo accompagnavano non potevano fallire.

---

## Cosa era giusto, e va detto per primo

- **`analyze`: 17, elenco identico a `main`** a meno dello scorrimento di riga dentro il file
  toccato. Verificato riga per riga, non sul totale.
- **`flutter test`: 506 verdi.** Vero, e verificato rifacendo la suite intera.
- **La stringa e cambiata in loco**, in EN e IT, come il piano chiedeva: la chiave esisteva gia e
  non e stata aggiunta in fondo.
- **L'ambra e corretta.** In `app_theme.dart:25` il `primary` del tema scuro **e** l'ambra, e il
  piano prevedeva proprio questo ritorno.
- **`timer_service.dart` non e stato toccato**, e la protezione di `setTimerDuration` non e stata
  aggirata. Erano i due divieti espliciti del piano.
- **Il punto 3 del piano — «si vede?» — regge, e l'ho verificato io.** `TimerOverlay` sta nel
  `builder` di `MaterialApp` (`app.dart:22-26`), quindi copre anche le rotte spinte sopra: la
  sessione attiva inclusa. Gemini c'era arrivato per la ragione giusta.

---

## 🔴-1 · Il commit dichiarato non esisteva

Il rapporto apriva con «Commit: US-094: il pulsante del timer avvia…». Il branch era fermo a
`e913a37`, l'albero sporco e il file di test **non tracciato**. `git log --all --grep` non trovava
niente.

E «Fuori piano: nessuno» era falso com'era l'albero: dentro c'erano anche **sette registrant di
plugin rigenerati** (`linux/`, `macos/`, `windows/`), la trappola del `git add -A` che l'handoff
descrive. Non sono stati committati.

## 🔴-2 · Tre criteri su cinque non erano dimostrati da niente

Il rapporto dichiarava una mutazione — tolta `toggleTimer()` — e i cinque criteri «soddisfatti».
**Rompendo il codice in tre punti diversi da quello, la suite restava verde:**

| Mutazione | Prima |
|---|---|
| `if (seconds <= 0)` → `if (seconds < 0)` | **verde** |
| tolta la riga `setTimerDuration(...)` | **verde** |
| tolta la guardia `isTimerRunning` | **verde** |

La causa era nella forma dei test: due di essi **riscrivevano la logica del pulsante dentro il
test** (`final seconds = 0; if (seconds > 0) { … }`) e poi verificavano il notifier. Certificavano
il proprio `if`. E il terzo — l'unico agganciato alla schermata — cercava nel sorgente la stringa
`timerNotifier.toggleTimer()`, cioe **esattamente la mutazione che l'esecutore aveva gia provato**:
la sola che il suo test prendeva.

È il difetto n. 2 dell'handoff, «test che certificano meno del loro nome», nella sua forma piu
pura.

**Corretto in questa review.** La logica e uscita dal gestore ed e diventata `startSetTimer` in
`active_session_screen.dart`. Non e un vezzo: la schermata **non si monta** in un test (istanzia
`FirestoreService` nel proprio `State`, debito di US-008), quindi finche la logica stava dentro
`onPressed` l'unico modo di provarla era riscriverla. Ora i test la chiamano davvero, e **tutte e
quattro** le mutazioni provate fanno diventare rosso almeno un test.

## 🟡-1 · «Con un timer gia in corsa viene ignorato» era vero solo per meta

La guardia legge `isTimerRunning`, che con un timer **in pausa** e falso. Il pulsante quindi
**sostituisce** un recupero messo in pausa e riparte sui secondi della serie nuova.

Non e per forza sbagliato — se l'utente ha messo in pausa e poi tocca il timer di una serie, quello
che chiede e proprio il timer nuovo — ma non e «viene ignorato», ed era dichiarato come tale. Ora
la scelta e scritta nel commento della funzione **e fissata da un test**, cosi se cambia si vede.

## 🟡-2 · Il cronometro copre il timer nell'overlay

`_getMainDisplay` (`timer_overlay.dart:138`) mostra il **cronometro** se ha tempo accumulato, e
solo altrimenti il timer. Quindi con un cronometro avviato — o anche solo fermo ma non azzerato —
il timer parte e l'overlay continua a mostrare l'altro: in quello stato «si vede che il tempo
scorre» **e falso**, e i comandi dell'overlay agiscono sul cronometro, non sul timer.

**Non l'ho corretto**: il quadrante a tutta altezza e US-051 e un secondo indicatore qui sarebbe il
debito che il piano vieta esplicitamente. Va deciso, non lasciato implicito.

## 🟡-3 · Il tocco a vuoto resta muto

Con zero secondi, o con un timer in corsa, non succede niente e non si dice niente — che e la
stessa esperienza del pulsante finto che questa storia toglie.

Il piano lasciava la scelta fra ignorare e disabilitare. **Ho tenuto «ignorare», e per una ragione
tecnica**: il campo dei secondi accanto scrive nel modello con `onChanged` **senza `setState`**,
quindi la riga non si ricostruisce e un pulsante disattivato mostrerebbe lo stato di prima invece
di quello vero. Meglio nessuna reazione di una reazione sbagliata. **Resta una decisione di
prodotto**: se si vuole un messaggio («servono dei secondi», «un recupero sta gia scorrendo»), e
una riga.

---

## Copertura dei criteri

| Criterio | Esito |
|---|---|
| Toccando il pulsante il timer parte sui secondi della serie | ✅ `startSetTimer parte sui secondi della serie`, e la mutazione che toglie `setTimerDuration` lo fa fallire |
| Se i secondi sono zero non parte niente | ✅ e ora **dimostrato**: prima nessun test lo prendeva |
| Con un timer gia in corsa il comportamento e quello dichiarato | ✅ e il caso della **pausa** e fissato a parte (🟡-1) |
| La stringa non dice piu «solo visuale» | ✅ test sul sorgente, EN e IT |
| Il gestore chiama davvero la logica | ✅ test sul sorgente: nomina `startSetTimer` |
| Il design system regge | ✅ `design_system_usage_test.dart` verde nella suite intera |
| Si vede che il tempo scorre | ⬜ **da confermare sull'APK**, e vedi 🟡-2 per lo stato in cui **non** si vede |

---

## Fuori scope rilevato

Nessuno nel commit. I sette registrant di plugin rigenerati sono stati lasciati fuori.

## Limiti dichiarati di questa review

1. **Non ho aperto l'app.** Che il timer si veda partire dalla sessione attiva resta da confermare
   sull'APK. Il ragionamento sull'overlay e letto nel codice, non visto.
2. **Il cablaggio fra pulsante e logica e provato su sorgente**, non con un tocco: la schermata non
   si monta. Se qualcuno scrivesse `startSetTimer` in un commento, il test resterebbe verde.
3. **Non ho misurato il caso del cronometro attivo** (🟡-2) sul dispositivo: e dedotto dal codice
   dell'overlay.

---

_Review di fase 5 · US-094 · su codice non scritto da chi rivede_
