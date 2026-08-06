# US-021 — Review

**Verdetto:** APPROVATA
**Diff esaminato:** `git diff main...HEAD` · 5 file, +389 / −49
**Verifica:** `flutter analyze` **66 avvisi, zero errori** (baseline invariato) · `flutter test` **267 test verdi** (erano 253) · `flutter build apk --debug` **riuscita**

Nessun rilievo bloccante. È la prima storia di questa sessione senza riserve, per un motivo
preciso: non aggiunge comportamento, ne sposta uno che esisteva già.

---

## Copertura dei criteri

| # | Criterio | Esito | Prova |
|---|---|---|---|
| 1 | Esiste un widget card condiviso che copre i casi d'uso di `_buildBentoCard` | ✅ | I sei usi della dashboard sono passati a `ExpressiveCard` senza cambiare firma: passavano `child`, `title` e `onTap`, e sono i tre parametri del componente |
| 2 | Legge raggi, spaziature ed elevazione dai token, senza valori numerici propri | ✅ **con la prova forte** | Non basta confrontare con i valori di default: con `24` scritto a mano il confronto passerebbe lo stesso. Due test **sostituiscono i token** con altri (raggio 0, padding 60) e verificano che il disegno cambi. Più un test sull'ombra contro `elevation.level2(scheme.shadow)` |
| 3 | Supporta titolo opzionale e azione al tocco opzionale | ✅ | 6 test: senza titolo c'è un solo `Text`, con titolo due; senza azione `onTap` è nullo, con azione il tocco arriva e l'onda segue gli angoli |
| 4 | Rende correttamente sia in tema chiaro sia in tema scuro | ✅ | Montato con entrambi i temi, il fondo è `surfaceContainer` del tema in uso. **Più un terzo test che verifica che i due colori siano diversi**: senza, i primi due passerebbero anche se il componente ignorasse il tema |
| 5 | `_buildBentoCard` è rimosso da `dashboard_screen.dart` | ✅ | `grep -c` restituisce **0**, e il file compila |
| 6 | Il componente compare nella schermata di catalogo interna | ✅ nel codice, **da confermare sull'APK** | Sezione «Card» con le tre forme: senza titolo, con titolo, toccabile |

---

## Cosa ha trovato la review

### 🔴 Il primo test sul titolo verificava la cosa sbagliata

Confrontava lo stile del titolo con `AppTheme.darkTheme(...).textTheme.titleMedium?.fontSize` letto
**fuori dall'albero**, dove vale `null`: il `TextTheme` non è ancora stato fuso con la tipografia di
default. Il test falliva con «atteso null, trovato 16».

Il valore atteso ora si legge dentro l'albero con un `Builder`. La lezione è generale e vale per
chi scriverà i prossimi test di tema: **un `ThemeData` costruito a mano non è il tema che i widget
vedono**.

### 🟡 Un punto percentuale di ombra in più

Da `Colors.black` con alpha 0,05 a `scheme.shadow` con alpha 0,06 — lo stesso nero, un'opacità di
un punto più alta, invisibile a occhio ma **è un cambiamento a schermo**, e questa storia dichiarava
di non farne. Vale la pena saperlo guardando la dashboard.

### 🔵 `surfaceContainer` invece di `cardColor`

Coincidono oggi (entrambi `indigo800`), ma per ragioni diverse: `cardColor` è un campo che precede
Material 3 e che il tema **non imposta**, quindi funzionava per un valore di default. Se qualcuno
domani cambia lo schema, `surfaceContainer` lo segue e `cardColor` no.

### 🔵 La card resta a tre parametri

È il punto in cui un componente condiviso di solito comincia a marcire. Chi vorrà un quarto
parametro dovrebbe prima chiedersi se sta ancora disegnando la stessa card.

---

## Fuori scope rilevato nel diff

Nessuno. I difetti della dashboard — `Colors.black` nella pillola del toggle, `cardColor`, gli
stream — **sono ancora tutti lì**: il diff su quel file è la rimozione di 46 righe e la
sostituzione di cinque nomi.

---

## Checklist adversariale

| Domanda | Risposta |
|---|---|
| Dato assente? | Titolo nullo e azione nulla sono i casi normali, entrambi testati |
| Risorse rilasciate? | Nessuna risorsa creata: è un `StatelessWidget` |
| `Stream` o `Future` dentro `build`? | No |
| Effetti collaterali in `build`? | No |
| Convenzioni di `CLAUDE.md`? | Nessun valore numerico, nessun colore letterale (`MaterialType.transparency` invece di un colore trasparente), colori dai ruoli dello schema. **È la storia che quelle regole descrivevano** |
| Il componente si comporta bene in un albero senza token? | Sì: `context.expressive` ripiega sui default quando l'estensione non è registrata, come US-033 aveva previsto |
| Può rompere qualcosa di non testato? | La dashboard, che non ha test. Il rischio è visivo e circoscritto: stessi valori, stessa struttura |
| Segreti nel diff? | Nessuno |

---

## Limiti dichiarati

1. **La dashboard non ha test** e non ne ha ricevuti qui: la prova che non sia cambiata a schermo è
   guardarla.
2. **Le altre card dell'app** (libreria, schede, calendario) usano `Card` di Material e non sono
   state toccate: è US-022.
3. **La review è un'autoverifica**, e questa volta ha trovato un solo difetto — in un test, non nel
   codice.

---

## Da confermare sull'APK

1. **Dashboard**: le sei card devono essere identiche a prima. Se qualcosa si è spostato, è un
   difetto di questa storia.
2. **Menu → Design system → sezione «Card»**: le tre forme, e il tocco che risponde.

---

_Review del 2026-08-06 · fase 5 del ciclo in [`WORKFLOW.md`](../WORKFLOW.md)_
