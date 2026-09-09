# GymFlow — specifiche visive della direzione "Immersivo / Toxic Forest"

**Questo documento non è più estratto da un mockup: è estratto dal codice.** La direzione
precedente (Material 3 Expressive, palette Indigo) aveva tre mockup HTML come fonte autorevole; la
direzione attuale, "Immersivo / Toxic Forest", è stata scritta direttamente in `lib/` — e il codice
è sopravvissuto a un incidente (il PC su cui era stato scritto è andato perso) mentre i documenti di
riferimento no. **`docs/adr/002-immersivo-toxic-forest.md`** e **`docs/design/05-immersivo-toxic-forest.html`**
sono citati per nome da un commento in testa a `lib/src/core/theme/app_palette.dart` come i
documenti ufficiali di questa direzione, ma non sono mai stati committati e non sono recuperabili
dal codice (non essendo file compilati). Finché non si ritrovano, **questo documento e il codice
stesso sono la fonte più affidabile disponibile**.

L'unico materiale di riferimento visivo superstite è
[`docs/design/GymFlow Immersivo Impostazioni.html`](design/GymFlow%20Immersivo%20Impostazioni.html)
— non un mockup nel formato dei precedenti, ma l'estratto di una conversazione di design ("Turno 3")
che mostra le schermate Impostazioni e le 4 palette a confronto sulla Home. Si apre in un browser.

---

## I quattro stili (`AppThemeStyle`)

Selezionabili da Impostazioni → Aspetto. **`toxicForest` è il default** (`theme_provider.dart`).
Ogni stile fissa sfondo, superfici, bordo, un colore per le **azioni** (`defaultAccent`) e uno per i
**dati vitali** (`defaultTertiary`) — mai lo stesso ruolo, in nessuno stile: se un'azione e un dato
condividessero il colore, l'occhio perderebbe il modo di distinguerli. Valori in
`lib/src/core/theme/app_palette.dart`.

| Stile | Sfondo | Superficie card | Superficie sollevata | Bordo | Azione | Dati vitali |
|---|---|---|---|---|---|---|
| **GymFlow Classico** | `#221E3A` | `#48426D` | `#5A5389` | `#6F68A6` | `#F0C38E` ambra | `#F1AA9B` salmone |
| **Digital Pulse** | `#0F172A` | `#2E1065` | `#3B1B7D` | `#581C87` | `#F472B6` magenta | `#C084FC` lilla¹ |
| **Toxic Forest** (default) | `#0B2027` | `#143540` | `#1E4B5A` | `#286274` | `#EEF800` giallo neon | `#80B918` verde bosco |
| **Deep Sea Neon** | `#000814` | `#003566`¹ | `#004B80`¹ | `#0A4F8A` | `#FFC300` oro | `#FFD60A` giallo brillante |

¹ Due valori si scostano deliberatamente dai riferimenti visivi originari, per accessibilità
(commento in `app_palette.dart`): il lilla di Digital Pulse era `#A855F7` nel materiale di
riferimento ma non supera 4,5:1 su nessuna superficie scura di quella palette (3,85:1 sulla card);
la superficie di Deep Sea Neon ha scambiato ruolo con la sua sollevata rispetto a una versione
precedente del codice (`ab08290`).

Ogni stile ha anche **6 preset di colore per l'accento** (`accentPresets`, scelto dall'utente in
Impostazioni → Aspetto con anteprima live su una card reale) — il primo preset è sempre
`defaultAccent`, il secondo `defaultTertiary`, gli altri completano la famiglia cromatica. **Il
colore dei dati vitali non cambia mai con l'accento scelto**: se cambiasse anche quello, la
distinzione azione↔dato sparirebbe. Ogni preset supera 4,5:1 su sfondo e superficie card,
verificato da `test/contrast_test.dart`.

Il tema chiaro non è un'inversione meccanica: l'accento crudo di nessuno dei 4 stili regge il
contrasto per il testo su fondo chiaro, quindi i ruoli testuali usano varianti scurite
(`accentOnLight`, `tertiaryOnLight`), definite per stile in `app_palette.dart`.

---

## Mappatura sul `ColorScheme` (`app_theme.dart`)

Il tema **non** è generato con `ColorScheme.fromSeed`: i colori sono scelti a mano, i contrasti
delle coppie usate sono già verificati, e derivarli da un seme unico li perderebbe. Tema scuro:

| Ruolo | Valore |
|---|---|
| `primary` / `onPrimary` | accento scelto / `style.darkBackground` |
| `secondary` | `style.defaultTertiary` @80% — supporto, non un'azione |
| `tertiary` / `onTertiary` | `style.defaultTertiary` / `style.darkBackground` — **dati vitali** |
| `surface`, `surfaceContainer` | `style.darkSurface` |
| `surfaceContainerLowest/Low` | `style.darkBackground` |
| `surfaceContainerHigh/Highest` | `style.darkSurfaceHigh` |
| `outline` | `style.darkOutline` |
| `onSurface` | `AppPalette.paper` (bianco freddo virato teal, non bianco puro) |

Nel tema chiaro `primary` è `style.accentOnLight` (scurito, leggibile) e l'accento crudo scala a
`primaryContainer` — chi scrive `scheme.primary` aspettandosi il colore "vivo" dell'accento su
sfondo chiaro ottiene invece la variante scurita pensata per il testo: è voluto, vedi il commento in
testa a `AppTheme.lightTheme`.

---

## Principi "Immersivo": angoli vivi, filetto, bagliore

Diverso in ogni punto dalla direzione precedente (Material 3 Expressive: angoli morbidi, elevazione,
ombra). Tutto in `lib/src/core/theme/immersivo_tokens.dart`, letto da `context.immersivo` — **non
più `context.expressive`**, rimosso insieme a `ExpressiveTokens`.

- **Angoli vivi.** `ImmersivoShape` ha `radiusXs/Sm/Md/Lg/Xl` tutti a **0**. `radiusFull` (999)
  resta solo per elementi genuinamente circolari (avatar) — mai per pillole o badge, che nel
  redesign sono rettangoli. I confini si disegnano con un **filetto** (bordo 1px, colore
  `scheme.outline`), non con l'elevazione: card, dialog, input, tutti bordati così in
  `app_theme.dart`.
- **Bagliore (`glow`) al posto dell'ombra.** `ImmersivoElevation` espone tre livelli come liste di
  `BoxShadow` colorate (`level1` appena percettibile, `level2` stato selezionato/attivo, `level3`
  elementi flottanti come la barra di navigazione o l'overlay del timer) — mai un'ombra neutra
  direzionale.
- **Font Anton** (Google Fonts), condensato e tutto maiuscolo, per titoli e numeri protagonisti — la
  base testo resta Space Grotesk (`GoogleFonts.spaceGroteskTextTheme`). Non esiste più una scala
  "emphasized" separata per peso: l'enfasi è nella scelta del font, non in una variante più pesante
  dello stesso.
- **`ticker_marquee.dart`**, nuovo: uno striscione di statistiche che scorre orizzontalmente (es.
  "VOLUME 18,4 T / RECORD PANCA 92,5 KG / 4 SU 5 SESSIONI /"), usato sia in home sia nella
  schermata Timer per il riepilogo dei recuperi. Sostituisce la griglia statica di tessere della
  direzione precedente.
- **Scala delle spaziature** (`ImmersivoSpacing`, multipli di 4): `xs=4` (icona-etichetta),
  `sm=8` (elementi affini), `md=16` (padding standard), `lg=20` (riquadri grandi), `xl=24` (margine
  di schermata), `xxl=32` (fra sezioni), `bottomInset=100` (coda delle liste, sopra la barra
  flottante).
- **Le impostazioni sono spezzate in 5 file**, non più una schermata sola: `settings_screen.dart`
  resta l'indice (Account · Palestra · App) e rimanda a `appearance_settings_screen.dart` (tema,
  palette, accento, anteprima, aptica), `gym_settings_screen.dart` (dettagli palestra, posizione,
  soci in comune), `timer_settings_screen.dart` (recupero predefinito e per tipo di serie, feedback
  fine recupero), `general_settings_screen.dart` (lingua, unità, dati/privacy, info, uscita).

---

## Cosa verificare prima di fidarsi ciecamente di questo documento

- **Non è stato validato pixel per pixel contro un mockup**: senza `05-immersivo-toxic-forest.html`,
  i valori sopra vengono dal codice (fonte primaria, affidabile per *cosa fa* l'app) e dagli
  screenshot dell'app installata (fonte visiva, affidabile per *come appare*) — non da una specifica
  di design originale. Se e quando quel file si ritrova, riconciliare.
- **Regressione nota, non ancora decisa con il prodotto**: la card del record personale
  (`_RecordBar` in `workout_summary_screen.dart`) non mostra più le ripetizioni della serie che ha
  stabilito il record né la data del massimale precedente — informazioni che la direzione
  precedente mostrava. Verificare se è una semplificazione voluta della direzione Immersivo o una
  perdita da recuperare.
- **Il repertorio di movimento e le micro-interazioni** della direzione precedente (cifre che
  rotolano, pulsante che muta forma, onde concentriche, sfondo `.aura` del timer) non sono stati
  riverificati contro il codice recuperato: `lib/src/ui/widgets/timer_aurora.dart` e
  `time_dial.dart` esistono ancora nell'elenco dei file recuperati, ma se si comportano ancora come
  descritto nella direzione Indigo o sono stati adattati a Immersivo va controllato leggendo il
  sorgente, non assunto da questo documento.

---

_Riscritto il 2026-09-09, dal codice recuperato di `recovery/immersivo-toxic-forest` (ora in
`main`), non da un mockup. Quando `05-immersivo-toxic-forest.html` o `adr/002` si ritrovano, o
quando l'inventario completo degli screenshot dell'app è pronto, questo documento va riconciliato
con quel materiale._
