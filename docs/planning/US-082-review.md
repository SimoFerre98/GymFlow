# US-082 — Review

**Data:** 2026-08-10 · **Branch:** `feature/US-082-active-session-design-system`
**Commit rivisti:** `d6a1042` (consegna) + `5270fed` (correzioni fatte in review)
**Chi ha implementato:** Gemini/Agy · **Chi rivede:** non ha scritto il codice

**Verdetto: APPROVATA CON RISERVE** — la consegna è la più pulita finora, e i due rilievi sono
entrambi giudizi, non sviste: un valore del mockup conservato invece che convertito, e l'ambra
messa su un abbozzo. Corretti in review.

---

## Numeri, misurati nel worktree

| | Dichiarato | Misurato |
|---|---|---|
| `flutter analyze` | 56 | **56** |
| `flutter test` | 447 verdi | **447 verdi** |
| File toccati | 3 | 3, tutti previsti dal piano |

**L'elenco degli avvisi è identico riga per riga a quello di `main`.** `localization_provider.dart`
non è stato aperto, come chiedeva il piano: le due storie in parallelo non si sono pestate i
piedi.

---

## 🔴-1 · Il padding della card conservava i pixel del mockup — corretto

Come consegnato, `active_session_screen.dart:353`:

```dart
padding: EdgeInsets.all(expressive.spacing.sm + expressive.spacing.xs),
```

`sm` è 8 e `xs` è 4: **la somma vale 12**, cioè esattamente il letterale che c'era prima. Non
esiste un token da 12, e i due sono stati sommati per riprodurlo.

Perché è un difetto e non una scelta di stile: `DESIGN-SPEC.md` ha una riga dedicata a questo
valore preciso —

| Elemento nel mockup | px | dp | Token |
|---|---|---|---|
| Padding card | 12 | **16** | `spacing.md` = 16 |

I 12 **sono i pixel del mockup**, e in dp diventano 16. Conservarli significa che la card resta
un quarto più compatta di com'è disegnata. **È la prima causa di difetti di questo progetto** —
successa in US-073, US-047 e US-050 — e qui è arrivata in una forma nuova e più difficile da
vedere: invece di scrivere `12`, si sommano due token fino a ottenere 12. **La guardia passa**,
perché non c'è nessun letterale numerico, e il valore sbagliato sopravvive con l'aspetto di un
uso corretto del design system.

Va detto in difesa dell'esecutore che il piano non gli aveva dato questa riga: gli chiedeva di
tradurre i letterali e gli dava la mappa dei colori, non quella delle spaziature. Il piano era
incompleto su questo punto.

**Corretto in `5270fed`**: `spacing.md`, con un commento che spiega perché non è 12.

⚠️ **Limite della guardia, da mettere agli atti**: `design_system_usage_test.dart` cerca
letterali numerici e non sa valutare il **valore** di un'espressione. `spacing.sm + spacing.xs`
la attraversa per costruzione — non serve una mutazione per dimostrarlo, il codice consegnato ne
era la prova con la suite verde. Se questo caso si ripresentasse, la difesa non è il test: è la
review.

---

## 🟡-1 · L'ambra su un abbozzo, accanto all'unica azione vera — corretto

Il rapporto spiega la scelta così:

> La riga 684 indicava l'icona del pulsante per avviare il timer della serie. Trattandosi di
> un'azione scatenata al tocco dell'utente (`onPressed`), è stato scelto il ruolo
> `scheme.primary`.

Il ragionamento è difendibile e il piano offriva quel ramo. Ma si ferma alla firma del gestore
senza leggere cosa contiene. Il gestore, `:686-692`:

```dart
onPressed: () {
  // Start a mini timer? For now just visual.
  ToastUtils.showInfo(context, loc.t('timer_started_msg'));
},
```

E la chiave: `'timer_started_msg': 'Timer avviato (solo visuale)'`.

**Il pulsante non avvia nessun timer, e lo dichiara.** Da segnalare che *non* è una bugia — ero
partito dal sospetto che dicesse «avviato» mentendo, e ho verificato prima di scriverlo: il
messaggio è onesto. Ma un controllo che annuncia di non fare niente **non è «cosa fare
adesso»**, che è l'unico significato dell'ambra in questa palette.

E c'è la circostanza che decide: **nella stessa schermata l'ambra è già sul pulsante «Termina»**
(`:317`), che è l'azione primaria della sessione. Dopo la consegna c'erano due ambra, una sul
gesto che chiude l'allenamento e una su un abbozzo. La regola del progetto dice perché conta più
della singola schermata: se l'ambra compare su qualcosa che non è un'azione, l'occhio impara a
ignorarla.

**Corretto in `5270fed`**: `onSurfaceVariant`, come il resto dei controlli non primari della
schermata, con un commento che dice di rimetterla ambra quando il timer esisterà.

**Deroga dichiarata**: il piano suggeriva `scheme.secondary` per il caso «né azione né dato
vitale». Non l'ho usato perché `secondary` non è uno dei cinque colori del prodotto in
`DESIGN-SPEC.md` — è una tinta che il `ColorScheme` genera e che nessuno ha deciso.
`onSurfaceVariant` è il ruolo che questa schermata usa già per tutto ciò che non è primario.

---

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| Nessun colore letterale, a parte `Colors.transparent` | ✅ | La guardia ora sorveglia il file, e passa |
| Nessuna spaziatura, raggio o dimensione di carattere a mano | ✅ *con la riserva sopra*: nessun **letterale**, e dopo la correzione nessun valore sbagliato ricomposto |
| I token nuovi esistono e hanno il valore dichiarato | ✅ | `iconSm`/`iconMd`/`iconLg` = 16/20/24, con un test proprio. **Provato**: portando `iconMd` a 21 il test diventa rosso |
| Il comportamento non è cambiato | ✅ parziale | Nessun test esistente è stato modificato, e la suite passa. Vedi però 🔵-1: il titolo dell'`AppBar` cambia aspetto |
| I contrasti reggono | ✅ | `contrast_test.dart` verde: sono ruoli già verificati, non colori nuovi |
| Le intestazioni non sono più sbiadite | ⬜ **Da confermare sull'APK** | Non spuntato |

### Le mutazioni, scelte diverse da quella del rapporto

Il rapporto dichiarava di aver rimesso un `Colors.grey` alla riga 476 e di aver visto la guardia
arrossire — plausibile, e sarebbe la mutazione che la guardia prende più facilmente. Ne ho fatte
due altrove, per provare i pezzi *aggiunti* da questa storia:

| Mutazione, applicata al file vero e verificata prima di lanciare | Esito |
|---|---|
| `iconMd` da 20 a **21** | 🔴 rosso, `design_system_usage_test.dart:156`. Il test sui token non è decorativo |
| Il titolo dell'`AppBar` torna a `textTheme.titleMedium` | 🔴 rosso: «deve usare `expressive.typography.titleEmphasized`». Prova che il file è davvero nella lista sorvegliata e che l'ultimo test del file morde |

La seconda era il tranello che il piano annunciava, ed è stata gestita: il titolo usa
`titleEmphasized`.

---

## 🔵 Rilievi minori

| | Dove | Cosa |
|---|---|---|
| 1 | `:294` | Il titolo dell'`AppBar` passa da `titleMedium` + `bold` a `titleEmphasized`. È ciò che la guardia pretende, quindi è giusto — ma **è un cambio d'aspetto, non una traduzione di letterali**, e il rapporto lo dava per «comportamento non cambiato». Da guardare sull'APK insieme al resto |
| 2 | `:306` | `strokeWidth: 2` resta un letterale. Nessun token lo copre e la guardia non lo cerca. Lasciato |
| 3 | `:476-486`, `:571-580` | Le righe delle intestazioni sono diventate molto lunghe, con `Theme.of(context).colorScheme.onSurfaceVariant` ripetuto sei volte. In queste funzioni non esiste una variabile locale `scheme` come nelle altre schermate. Non lo correggo: `dart format` su questo repository riscrive centinaia di righe non toccate, e rientrare a mano sei righe non vale la review che ne segue |
| 4 | `test/design_system_usage_test.dart` | Una riga vuota in più in fondo al file |

---

## Checklist adversariale

| Voce | Esito |
|---|---|
| File fuori dal piano? | No. Tre file, esattamente quelli previsti |
| `localization_provider.dart` aperto? | **No** — era il vincolo per non collidere con US-027 |
| Le stringhe `#`, `Kg`, `Km` sono state toccate? | No, restano come sono: sono di US-027 |
| È diventato un ridisegno? | **No.** Il diff si legge riga per riga come «letterale → token», tranne il titolo dell'`AppBar` (🔵-1) |
| Sono stati cancellati campi, righe o funzioni? | No. Nessuna riduzione: era il rischio di US-066 e non si è ripetuto |
| Le tabelle delle tre modalità (forza, cardio, corpo libero) sono tutte e tre convertite? | Sì, verificate una per una nel diff |
| I token nuovi rompono `copyWith` o `lerp` della `ThemeExtension`? | No: `ExpressiveSizing` è una classe `const` di soli getter, come il piano prevedeva |
| Stream o Future dentro `build`? | Nessuno introdotto |
| Segreti, percorsi locali, avanzi di Gradle nei commit? | Nessuno: i commit elencano i file |

---

## Limiti dichiarati di questa review

1. **Non ho guardato la schermata.** Tutto il giudizio visivo — che le intestazioni si leggano,
   che il titolo con `titleEmphasized` non sia troppo grande, che la card col padding a 16 non
   spinga il contenuto oltre il bordo — richiede l'APK. La guardia dimostra **come è scritta** la
   schermata, non che il risultato sia leggibile: è il limite che il test stesso dichiara in
   testa.
2. **Il valore dei token scelti non è verificato da nessun test.** La guardia vieta i letterali;
   nessuno controlla che `spacing.sm` sia la scelta giusta invece di `md`. Se un giorno servisse
   una difesa automatica, è qui che manca — ed è il buco da cui è passato 🔴-1.
3. **Non ho verificato che i tre token nuovi siano usati con la semantica che dichiarano.**
   `iconMd` è usato per la girella di salvataggio, che è un indicatore e non un'icona: passa, ma
   è un'approssimazione.
4. **Il pulsante-abbozzo del timer resta nell'app.** L'ho reso onesto nel colore, non
   funzionante. Vedi il riepilogo: vale una riga di backlog, non una correzione dentro questa
   storia.
5. **I 56 avvisi** non sono stati esaminati: sono il debito di US-030.

---

_Review di fase 5 · US-082 · su codice non scritto da chi rivede_
