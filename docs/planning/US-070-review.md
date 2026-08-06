# US-070 — Review

**Verdetto:** APPROVATA
**Diff esaminato:** `git diff main...HEAD` · 6 file, +230 / −18
**Verifica:** `flutter analyze` **66 avvisi, zero errori** · `flutter test` **273 test verdi** (erano 267) · `flutter build apk --debug` **riuscita** · **provata sul telefono**

È la prima storia di questa sessione verificata **guardando l'app**, non solo i test.

---

## Copertura dei criteri

| # | Criterio | Esito | Prova |
|---|---|---|---|
| 1 | Esiste una voce nel menu principale che apre la libreria esercizi | ✅ **verificato sul telefono** | Voce «Esercizi» fra «Impostazioni» e «Obiettivi». Toccata: si apre la libreria |
| 2 | La voce e i testi sono localizzati in EN e IT | ✅ **verificato sul telefono** | A schermo: «Libreria esercizi», «Cerca esercizio», e il vuoto in italiano. Più 3 test sulle quattro chiavi in entrambe le lingue, incluso uno che verifica che le due lingue **non dicano la stessa cosa** — un copia-incolla dall'inglese passerebbe il resto |
| 3 | Aperta dal menu, la schermata è in consultazione | ✅ | Il menu costruisce `ExerciseLibraryScreen()` senza argomenti, e il default è `isSelecting: false`, verificato da un test |
| 4 | In consultazione, toccare un esercizio ne apre l'esecuzione | ⚠️ **non verificabile oggi** | Il codice c'è; **la libreria è vuota**, quindi non c'era nessuna cella da toccare. Vedi sotto |
| 5 | Il percorso esistente continua a funzionare | ⚠️ **da confermare** | `workout_creator_screen.dart:450` non è nel diff. Da provare aggiungendo un esercizio a una scheda |

---

## Cosa ha trovato la review, guardando l'app

### 🔴 La libreria è vuota: **zero esercizi**, non otto

Aprendo la voce nuova, il telefono mostra il messaggio di lista vuota. Non ci sono nemmeno gli otto
esercizi inglesi che davo per presenti: su questo account `seedDefaultExercises` non è mai stato
eseguito.

Cambia la lettura di tutto quello che è successo prima. La segnalazione dell'utente — *«l'app sta
rimanendo uguale»* — aveva **due cause sovrapposte**, non una:

1. la libreria non era raggiungibile (questa storia);
2. **la libreria è vuota**, quindi anche raggiungendola non ci sarebbe stato niente da vedere.

US-045 ha costruito l'import e l'ha lasciato dietro un pulsante che nessuno ha ancora premuto. Il
criterio 4 non è verificabile finché quel pulsante non viene premuto: **non si spunta**.

Il messaggio di lista vuota, per fortuna, dice cosa fare: «Carica la libreria dalle impostazioni,
oppure creane uno tuo». Non era un dettaglio di cortesia — è l'unica indicazione che l'utente ha.

### 🟡 Undici stringhe non tradotte, visibili a schermo

Guardando la dashboard sul telefono si legge **`rpe_label`** al posto di «Intensità media». Un
controllo su tutto il codice ha trovato **11 chiavi usate e mai definite**, in nessuna delle due
lingue:

`rpe_label` · `cancel` · `completed_at` · `error_connecting` · `error_deleting` · `event_deleted` ·
`friend_label` · `gymflow_user` · `login_required` · `no_workouts_create_first` · `scheduled_for`

`Localization.t` restituisce la chiave quando manca — una scelta giusta, che rende il problema
visibile invece di farlo sparire. Ma nessuno stava guardando.

**Fuori scope qui.** Aperta **US-071**.

---

## Fuori scope rilevato nel diff

Il diff tocca `exercise_library_screen.dart` più di quanto il titolo della storia suggerisca:
la classe passa da `StatefulWidget` a `ConsumerStatefulWidget`. Era necessario — la localizzazione
passa da un provider Riverpod — ed è **il minimo**: i servizi restano istanziati a mano e lo stream
resta dentro `build`, che sono US-008÷US-012.

---

## Checklist adversariale

| Domanda | Risposta |
|---|---|
| Il percorso vecchio si rompe? | `isSelecting: true` è ancora passato dalla creazione scheda, e il ramo `Navigator.pop(context, exercise)` è intatto |
| Due gesti sulla stessa cella? | In consultazione la cella e la miniatura fanno la stessa cosa: nessuna ambiguità. In scelta restano distinti, come da US-044 |
| Lista vuota? | È **il caso reale**, e il messaggio dice cosa fare |
| Utente non autenticato? | Il ramo esisteva già: «Please log in». Non localizzato, ma non introdotto qui |
| Convenzioni? | Le quattro stringhe nuove sono in EN e IT. La voce di menu segue la forma delle altre |
| Segreti nel diff? | Nessuno |

---

## Limiti dichiarati

1. **Il criterio 4 non è spuntato**: senza esercizi non c'era niente da toccare.
2. **`ExerciseLibraryScreen` non è montabile in un test** (servizi istanziati nei campi, stream in
   `build`): i test coprono la modalità e le chiavi, non la schermata.
3. **Il percorso di scelta non è stato riprovato** sul telefono.
4. La review è un'autoverifica — ma questa volta con l'app aperta davanti.

---

_Review del 2026-08-06 · fase 5 del ciclo in [`WORKFLOW.md`](../WORKFLOW.md)_
