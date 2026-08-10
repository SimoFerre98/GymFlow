# US-068 — Review

**Storia:** Scheda esercizio con la progressione · **Epic:** EP-015 · 5 punti
**Branch:** `feature/US-068-exercise-detail` · **Base:** `main` `403671a`
**Implementata da:** Agy (Antigravity), con l'utente come tramite
**Recensita il:** 2026-08-07

**Verdetto: APPROVATA.** Le due trappole grosse — il ramo della selezione e i mezzi chili —
sono state evitate, e l'esecutore ha fatto **due** controprove sulle mutazioni giuste.
Corretti tre valori scritti a mano nelle etichette del grafico.

**Chiude il criterio che US-050 aveva lasciato aperto**: «la storia dei record per esercizio è
consultabile».

---

## Verifica

| | Dichiarato da Agy | Misurato da me |
|---|---|---|
| `flutter analyze` | 63 | **63**, zero avvisi nuovi ✅ |
| `flutter test` | 417 verdi | **417** ✅ |
| File | 5 | 5 ✅ |
| Fuori piano | nessuno | nessuno ✅ |
| Commit | `e39e60a`, con il codice | **committato** ✅ |

### Il ramo `isSelecting`, verificato sul diff

Era il rischio numero uno del piano: confonderlo romperebbe la creazione delle schede. Il
diff sulla libreria è di **otto righe** e tocca **solo** il ramo `else`:

```dart
if (widget.isSelecting) {
  Navigator.pop(context, exercise);          // <- intatto
} else {
  Navigator.push(... ExerciseDetailScreen ...) // <- era ExerciseVideoSheet.show
}
```

La miniatura continua ad aprire il video (`onThumbnailTap` non è toccato), quindi il gesto
rapido resta.

### Le controprove

**Le sue, due, sulle mutazioni che il piano chiedeva:**

| Mutazione | Esito dichiarato |
|---|---|
| `toInt()` sul peso | «i mezzi chili sopravvivono» → rosso, 62.0 invece di 62.5 |
| Rimosso `isCompleted` dal filtro | «solo le serie completate contano» → rosso, 120 kg da una serie non completata |

Sono esattamente le due classi di difetto che questo progetto ha già subito: il `toInt()` è il
difetto di US-049, e le serie non completate sono i carichi precompilati all'apertura di un
allenamento.

**La mia, una terza:** ho neutralizzato il filtro del periodo di un mese
(`ProgressionPeriod.oneMonth => true`) e il test «il periodo filtra correttamente le sessioni
vecchie» **diventa rosso**.

*Nota di metodo, per la seconda volta oggi:* il mio primo tentativo di mutazione non ha
agganciato niente — cercavo un `.where(... isAfter ...)` e il codice usa uno `switch` — e il
test è restato verde. **Una controprova che non modifica il codice non dimostra niente**, e
va controllato che la modifica sia davvero applicata prima di leggerne l'esito.

---

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| La scheda mostra immagine, video, gruppi muscolari e tipo | ✅ | Header con `ExerciseImage` e la sua catena di ripiego, e il video dal pulsante |
| Il grafico riporta l'andamento del carico massimo | ✅ | Un punto per sessione, il massimo del giorno, testato |
| Il periodo è selezionabile | ✅ | Un mese, tre mesi, tutto — testati tutti e tre, e la mia mutazione lo conferma |
| L'ultima sessione è riportata con le serie effettive | ✅ | Funzione dedicata, con test |
| Il record è indicato con la data | ✅ | Da `personalBestsProvider` di US-050, che porta carico, ripetizioni e data |
| Un esercizio senza storico mostra un invito | ✅ | Con zero punti compare la card d'invito **al posto** degli assi, che era la richiesta esplicita |
| I dati sono calcolati dallo storico locale, senza rete | ✅ **strutturale** | La sorgente è `dashboardSessionsProvider`, che legge Isar. Dichiarato, non provabile in un test |
| L'aspetto | ❌ **da confermare sull'APK** | Dichiarato correttamente |

---

## Rilievi

### 🟡 1 — Le etichette del grafico avevano tre valori scritti a mano

**Corretto.**

```dart
style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10, fontFamily: 'monospace')
padding: const EdgeInsets.only(top: 8.0)
```

Due `fontSize: 10`, un padding numerico, e un **font monospaziato scritto a mano** — mentre il
progetto ha `ExpressiveTypography` che ottiene le cifre allineate con
`FontFeature.tabularFigures()` sul carattere del tema, senza cambiare famiglia.

Ora l'asse dei carichi usa `labelSmall` — il ruolo più piccolo del tema, che è la misura
giusta per un asse — con le cifre tabulari aggiunte **con lo stesso meccanismo** che usa il
design system, e il commento che spiega perché non c'è un token: sotto `metricSmall` (14 sp)
il design system non ha una misura, e le etichette di un asse sono piccole per natura.

Il resto delle 662 righe era pulito: dopo la correzione restano un `Colors.transparent` e
un'aritmetica sul token.

### 🔵 2 — Aritmetica sul token, ancora

`t.spacing.xs / 2` per ottenere 2. È il terzo file in cui compare — US-047, US-065, e ora
questo. Non è grave e non l'ho corretto, ma è diventato un modo di fare: se serve un valore
che i token non hanno, la risposta è aggiungere il token o accettare il letterale con la
ragione scritta, **non dividere**.

Vale la pena metterlo in `AGENTS.md` fra le convenzioni, altrimenti continuerà.

### 🔵 3 — `dynamic` per il record personale

`Widget _buildPersonalBestCard(..., dynamic personalBest)`. Il tipo è `PersonalBest`, esiste,
è importabile e ha i campi tipizzati. Con `dynamic` un errore di nome di campo diventa
un'eccezione a runtime invece di un errore di compilazione — proprio su una card che mostra
dati.

Non l'ho corretto perché il file è nuovo e la modifica è a rischio zero solo se ricompilo e
riprovo, ma **va sistemato**: è una riga.

### 🔵 4 — Il tocco sulla riga cambia comportamento, e nessuno lo saprà

Fino a ieri toccare un esercizio apriva il video. Ora apre la scheda, e il video sta dietro un
pulsante. È **voluto e giusto** — la riga non aveva una destinazione propria — ma è un
cambiamento di abitudine per chi usava l'app: il gesto che dava il video adesso dà altro.

Da guardare sull'APK: che il pulsante del video nell'header sia trovabile.

---

## Regressioni sospette

**La creazione di una scheda.** È il percorso che il ramo `isSelecting` serve, ed è intatto
nel diff. **Da provare a mano**: creare una scheda, aggiungere un esercizio, e verificare che
il tocco restituisca l'esercizio invece di aprire la sua pagina. È il rischio numero uno del
piano e nessun test lo copre.

**`exerciseLibraryViewFor` di US-076 e i filtri di US-065**: non toccati, il diff sulla
libreria è di otto righe.

**Il calcolo su molte sessioni.** `calculateProgressionPoints` gira dentro `build`. Con lo
storico di un utente vero — decine di sessioni — è una scansione lineare a ogni ricostruzione.
Oggi è irrilevante; con centinaia di sessioni andrebbe memoizzato, ed è US-017.

---

## Limiti di questa review

- **La schermata non è stata aperta.** Per una storia che aggiunge 662 righe di interfaccia,
  è il limite grosso: il grafico può essere illeggibile, le etichette sovrapporsi, la card
  dell'invito essere brutta. Niente di tutto questo è verificato.
- **Il caso «una sola sessione»** — che il piano segnalava fra i rischi, perché una linea con
  un punto non è una linea — **non l'ho verificato né nei test né a schermo**. Il rapporto non
  lo menziona.
- **Non ho letto le 662 righe della schermata riga per riga**: ho letto la struttura, cercato
  i valori a mano con un'espressione, e verificato il comportamento con una mutazione.
- **Il `dynamic` del rilievo 🔵 3 resta.**

---

## Cosa serve dall'utente

1. **La prova sull'APK**: Menu → Esercizi → toccare un esercizio che hai già fatto. Il
   grafico, il record con la data, l'ultima sessione. E un esercizio **mai fatto**, che deve
   mostrare l'invito e non degli assi vuoti.
2. **La prova che vale di più**: creare una scheda e aggiungerci un esercizio. Se il tocco
   apre la scheda invece di sceglierlo, questa storia ha rotto la creazione delle schede.

---

_Review del 2026-08-07 · numeri rimisurati, terza mutazione indipendente, tre valori a mano corretti_
