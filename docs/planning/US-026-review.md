# US-026 — Review

**Storia:** Localizzare le stringhe delle schermate principali · **Epic:** EP-006 · 3 punti
**Branch:** `feature/US-026-localize-main-screens` · **Base:** `main` `403671a`
**Implementata da:** Agy (Antigravity), con l'utente come tramite
**Recensita il:** 2026-08-07

**Verdetto: APPROVATA.** Consegna pulita: numeri veri, whitelist motivata, controprova
fatta. **Non ho trovato niente da correggere nel codice** — è la prima volta in questa
sessione.

Un rilievo che non riguarda questa storia ma che questa storia ha reso visibile, ed è
grosso.

---

## Verifica

| | Dichiarato da Agy | Misurato da me |
|---|---|---|
| `flutter analyze` | 63 | **63**, zero avvisi nuovi rispetto a `main` ✅ |
| `flutter test` | 415 verdi | **415** ✅ |
| File | 5 | 5 ✅ |
| Fuori piano | nessuno | nessuno ✅ |
| Commit | presente | **committato** ✅ |

**La ricerca l'ho rifatta io**, con un'espressione mia su `Text`, `label`, `labelText`,
`hintText`, `helpText`, `tooltip`, `title` e `content` nei tre file, escludendo la whitelist:
**zero risultati**. L'affermazione «le stringhe letterali sono sparite» regge.

**Controprova mia, diversa dalla sua.** Agy ha inserito una stringa in `dashboard_screen.dart`.
Io l'ho rimessa in `active_session_screen.dart:422`, che è il file con undici stringhe su
dodici e quindi quello che conta: **il test diventa rosso**. Il controllo copre tutte e tre le
schermate, non solo quella dove l'esecutore ha provato.

*Nota di metodo:* al primo tentativo la mia sostituzione non ha agganciato niente e il test è
restato verde. Se non avessi controllato che la mutazione fosse davvero applicata, avrei
concluso che il test non funzionava. Una controprova che non modifica niente **dimostra
quanto una che non fallisce**: cioè nulla.

---

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| Le stringhe di dashboard, calendario e sessione attiva sono nel dizionario | ✅ | 23 chiavi nuove, ricerca indipendente a zero risultati |
| Ogni chiave in EN e IT | ✅ | Verificato nel diff: i due blocchi sono simmetrici. E il test del progetto lo controlla già |
| Con l'italiano nessun testo resta in inglese | ❌ **da confermare sull'APK** | Dichiarato correttamente: un test prova che **una chiave c'è**, non che dica la cosa giusta |
| Il ripiego su chiave mancante non fa crollare | ✅ | Test dedicato |
| I `??` morti su `loc.t` sono rimossi | ✅ | Verificato con una ricerca mia: nessun `loc.t(...) ??` nei tre file |

---

## Rilievi

### 🟡 1 — La schermata dove passi l'allenamento non ha mai preso il design system

Non è un difetto di questa storia, ed è il motivo per cui lo scrivo qui: **è emerso solo
perché US-026 ha aperto quel file**.

`active_session_screen.dart` contiene **21 valori scritti a mano** — colori letterali,
spaziature numeriche, raggi — e fra questi un `Text('Kg', style: TextStyle(color: Colors.grey))`.

US-022 ha convertito dashboard, calendario e lista allenamenti. **La sessione attiva non era
nel suo elenco**, e nemmeno in quello di US-023, che copre le «schermate secondarie». È
rimasta in mezzo: è la schermata più usata dell'app — è dove sei mentre ti alleni — e nessuna
storia la porta al design system.

US-046, US-047 e US-050 le hanno aggiunto pezzi nuovi e curati, quindi convivono un foglio
della serie con i token e una tabella con `Colors.grey`.

**Serve una storia.** Non l'ho aperta perché la decisione su dove metterla — dentro US-023 o
a parte — è dell'utente.

### 🔵 2 — «Kg» contro «kg»

La whitelist tiene `'Kg'` e `'Km'` come unità di misura, e la motivazione è corretta: sono
uguali nelle due lingue, localizzarle non cambierebbe niente.

Ma il resto dell'app scrive **`kg` minuscolo** — nel foglio della serie, nel riepilogo, nella
card dei record — e il simbolo internazionale è minuscolo in entrambe le lingue. Quindi la
sessione attiva scrive `Kg` e tutto il resto `kg`.

Fuori dallo scopo di questa storia. Va con il rilievo 🟡 1, quando quella schermata verrà
sistemata.

### 🔵 3 — La whitelist è fatta bene, e vale segnalarlo

È una `Map` da stringa a **motivazione**, non un elenco muto:

```dart
const allowedTechnicalStrings = {
  'Error: \$err': 'Errore tecnico di caricamento dati nella dashboard (log di debug…)',
  'Kg': 'Unità di misura del peso…',
  'Km': 'Unità di misura della distanza…',
};
```

È esattamente ciò che il piano chiedeva — «un elenco motivato è documentazione, un'eccezione
silenziosa è un buco» — e chi aggiungerà un'eccezione dovrà scriverne la ragione per
compilare.

---

## Regressioni sospette

**Le stringhe con un valore dentro sono state spezzate correttamente.** `'${n} Exercises'` è
diventato `'${n} ${loc.t('exercises_suffix')}'`: la parte fissa nella chiave, l'interpolazione
fuori. Il dizionario del progetto non fa sostituzioni, e provarci avrebbe prodotto
`'{count} Exercises'` a schermo.

**Non è stato localizzato ciò che non si vede.** Nessuna chiave tocca i valori delle `enum`,
i nomi dei campi Firestore o i dati salvati: verificato nel diff. Era il rischio scritto nel
piano.

**Il flusso di fine allenamento** ha molte stringhe nuove — titolo, corpo, conferma data,
conferma ora — ed è lo stesso flusso che nel recupero di US-047 era stato riscritto per
sbaglio e riportato indietro. Questa volta il diff cambia **solo le stringhe**: la logica dei
selettori di data è intatta.

---

## Limiti di questa review

- **Le traduzioni italiane le ho lette, non provate.** «Termina Allenamento», «Ottimo lavoro!
  Salvare questo allenamento?», «Aggiungi serie» sono corrette e nel tono giusto, ma
  **leggerle in un diff non è vederle a schermo**, dove possono andare a capo male o uscire
  dal pulsante. `CONFERMA ORA DI FINE` è lungo il doppio dell'originale e sta in un
  selettore di data: **è il primo posto da guardare**.
- **Non ho verificato che ogni chiave nuova sia davvero usata.** Una chiave tradotta e mai
  chiamata è innocua ma è peso morto, e il test del progetto controlla il verso opposto.
- **Niente è stato provato sul dispositivo.**

---

## Cosa serve dall'utente

1. **La prova sull'APK con l'app in italiano**: la sessione attiva dall'inizio alla fine,
   compreso il dialogo di chiusura e i due selettori di data. È lì che stanno undici stringhe
   su dodici.
2. **Una decisione sul rilievo 🟡 1**: la sessione attiva ha 21 valori scritti a mano e
   nessuna storia la copre. Storia nuova, o si allarga US-023?

---

_Review del 2026-08-07 · numeri rimisurati, ricerca e controprova indipendenti_
