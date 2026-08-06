# GymFlow — specifiche visive estratte dai mockup

**I mockup sono la fonte autorevole della grafica.** Stanno in
[`docs/design/`](design/), sono versionati nel repository, e si aprono in un browser:

| File | Contenuto |
|---|---|
| [`01-direzione-visiva.html`](design/01-direzione-visiva.html) | 6 schermate: home, sessione, statistiche, serie in corso, riepilogo, catena delle immagini |
| [`02-schermate-app.html`](design/02-schermate-app.html) | 9 schermate: libreria, nuovo esercizio, tipi di allenamento, timer, pillola, Now Bar, calendario, obiettivi, impostazioni |
| [`03-timer-e-movimento.html`](design/03-timer-e-movimento.html) | timer **funzionante**, repertorio delle micro-interazioni, Now Bar |

Questo documento è il loro **estratto operativo**: i valori che servono al codice, già convertiti.
Non sostituisce i mockup — quando c'è un dubbio si apre l'HTML e si guarda.

---

## ⚠️ La conversione da pixel del mockup a dp

**I numeri dell'HTML non si copiano.** E il fattore non è nemmeno uno solo: i primi due mockup
disegnano un telefono da 300 px, il terzo da 340. Verificato nei file, non dedotto.

| Mockup | Telaio | Cornice | Schermo disegnato | Fattore verso 384 dp |
|---|---|---|---|---|
| `01-direzione-visiva` | 300 px | 9 px | 282 px | **× 1,36** |
| `02-schermate-app` | 300 px | 9 px | 282 px | **× 1,36** |
| `03-timer-e-movimento` | 340 px | 10 px | 320 px | **× 1,20** |

Il telefono reale (S26 Ultra) è **384 dp** di larghezza logica: 1080 px reali diviso 2,8125 di
densità.

Chi legge `width: 40px` sulla miniatura e scrive `40` in Flutter la fa **un quarto più piccola** di
com'è disegnata. È l'errore più facile da fare con questi file, ed è il motivo per cui questo
documento esiste.

| Elemento nel mockup (file 01 e 02, × 1,36) | px | dp | Token |
|---|---|---|---|
| Miniatura esercizio | 40 | **54** | `sizing.thumbnailMd` = 56 ✅ |
| Raggio miniatura | 12 | **16** | `shape.cornerMd` = 16 ✅ |
| Indicatore video | 13 | **18** | `sizing.badge` = 20, accettabile |
| Raggio card | 20 | **27** | `shape.cornerLg` = 24, accettabile |
| Padding card | 12 | **16** | `spacing.md` = 16 — **oggi si usa `lg` = 20** |
| Raggio riga esercizio | 16 | **22** | fra `cornerMd` e `cornerLg` |
| Padding riga esercizio | 8 | **11** | `spacing.sm` = 8 o `md` = 16 |
| Raggio barra di navigazione | 20 | **27** | `cornerLg` |
| Pillole, pulsanti, chip | 99 | pieno | `cornerFull` ✅ |

---

## Colori, e a cosa corrispondono nel `ColorScheme`

I mockup usano cinque colori del prodotto. Tutti e cinque esistono già in `app_palette.dart`.

| Mockup | Valore | Dove va nel tema | Uso nei mockup |
|---|---|---|---|
| `--ink-900` | `#221E3A` | `surfaceContainerLowest` | **Sfondo dello schermo** |
| `--ink-800` | `#312C51` | `surface`, `surfaceContainer` | Telaio, testo su ambra |
| `--ink-700` | `#48426D` | `surfaceContainerHigh` | **Fondo delle card e delle righe** |
| `--ink-600` | `#5A5384` | `outline` | Estremo chiaro dei gradienti |
| `--amber` | `#F0C38E` | `primary` | Azione, valore in evidenza, elemento selezionato |
| `--salmon` | `#F1AA9B` | `tertiary` | Dati vitali **e indicatore video** |
| `--paper` | `#F7F5FB` | `onSurface` | Testo |

### ⚠️ Le card stanno su `ink-700`, non su `ink-800`

Nel mockup lo schermo è `ink-900` e le card sono `ink-700`: **due gradini di distacco**, non uno.
`ExpressiveCard` oggi usa `surfaceContainer` (= `ink-800`), quindi le card staccano meno di quanto
disegnato.

### ⚠️ L'indicatore video è salmone

`.play { background: var(--salmon); color: var(--ink-800); }` — pallino salmone con il triangolo
scuro, in basso a destra, 2 px dal bordo. Non un fondo scuro con il simbolo chiaro.

---

## Componenti

### Riga esercizio (`.exr`) — **il componente più usato dell'app**

```
fondo ink-700 · raggio 22dp · padding 11dp · gap 12dp
├── miniatura 54dp, raggio 16dp, con indicatore video in basso a destra
├── colonna: nome (bold, ~14dp) + riga meta (dim, ~11dp: "4 × 8 · 60 kg" oppure "Petto · Tricipiti")
└── pillola del tipo o del gruppo (ambra / salmone / neutra)
```

Non è un `ListTile` dentro una `Card` di Material: è una **riga propria**, più compatta.

### Segnaposto della miniatura — **uniforme, non per gruppo muscolare**

```css
background: linear-gradient(150deg, var(--ink-600), var(--ink-800));
```

Gradiente indigo **uguale per tutti gli esercizi**, con sopra una sagoma a tratto (`stroke`, non
piena) in ambra, salmone o carta. Non sette tinte diverse per regione del corpo.

### Card (`.card`)

`fondo ink-700 · raggio 27dp · padding 16dp · gap 12dp`

Tre varianti:
- **normale**: fondo `ink-700`
- **piena** (`.card.solid`): fondo **ambra**, testo `ink-800` — «questo è il livello primario»
- **contornata** (`.card.outline`): trasparente, bordo ambra 1,4px — recupero, record

### Pillole (`.pill`)

`raggio pieno · maiuscolo · ~11dp · peso 700 · letter-spacing .04em`
Fondo = accento al **20%**, testo = accento pieno. Tre varianti: ambra, salmone, neutra
(`paper` al 13%).

### Pulsante d'azione (`.cta`)

`fondo ambra · testo ink-800 · raggio pieno · peso 800`, con un cerchio scuro a destra che contiene
la freccia. **Non un `FilledButton` rettangolare.**

### Etichette (`.lbl`)

`~11dp · maiuscolo · letter-spacing .06em · paper al 58%`

### Numeri (`.metric`)

**Monospaziato, cifre tabulari**, peso 700, letter-spacing −.02em. Corrisponde a
`typography.metric*`, che esiste da US-033.

### Barra di navigazione (`.nav`)

`margine 12dp · raggio 27dp · fondo ink-700 · icona selezionata in ambra, le altre al 42%`

---

## Movimento (dal mockup 03)

| Curva nel mockup | Token Flutter |
|---|---|
| `cubic-bezier(.2,0,0,1)` | `Easing.standard` → `motion.standardCurve` |
| `cubic-bezier(.05,.7,.1,1)` | `Easing.emphasizedDecelerate` → `motion.emphasizedCurve` |
| `cubic-bezier(.3,0,.8,.15)` | `Easing.emphasizedAccelerate` → `motion.exit` |
| `cubic-bezier(.34,1.56,.64,1)` | **elastica, non esiste in `Easing`** — è US-036 (`motor`) |

Micro-interazioni dichiarate:

1. **Cifre che rotolano** — quella che cambia esce in alto, la nuova entra dal basso, sfocatura
   minima. In Flutter: `AnimatedSwitcher` + `SlideTransition`. **Solo la cifra che cambia si muove.**
2. **Pulsante che muta forma** — da cerchio a rettangolo stondato quando parte, e si allarga
   (76 → 96 px). Curva elastica.
3. **Onde concentriche** — tre cerchi si espandono sfalsati di ~0,93 s mentre il timer scorre, fermi
   in pausa.
4. **Cursore che scivola** — nel segmentato l'ambra scorre sotto le etichette (0,48 s, emphasized
   decelerate) e il quadrante vira sul salmone.
5. **Valore che pulsa** — al cambio si ingrandisce del 24% e vira sull'ambra.

---

## Cosa nei mockup non è ancora nel backlog come dettaglio

- **Anello di avanzamento** della scheda in corso, sulla home (US-055 lo copre come schermata)
- **Griglia a tessere di dimensioni diverse** per le statistiche: «quello che conta occupa più
  spazio»
- **Scontrino** di fine allenamento con il bordo dentellato (US-049)
- **Cursori** per carico, ripetizioni e sforzo (US-046)
- **Segmentato** Tutti / Miei / Recenti e **chip per gruppo muscolare** nella libreria (US-065)
- **Ventaglio di carte** per le schede

---

_Estratto il 2026-08-06 dai tre mockup. Quando un mockup cambia, questo documento va rifatto._
