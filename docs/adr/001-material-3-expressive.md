# ADR-001 — Come ottenere Material 3 Expressive

**Data:** 2026-08-06 · **Stato:** accettata · **Storia:** US-033 · **Epica:** EP-005

## Contesto

La direzione di prodotto per l'interfaccia è **Material 3 Expressive**. Flutter non lo supporta, e non è una questione di tempi: dall'issue ombrello ufficiale [flutter/flutter#168813](https://github.com/flutter/flutter/issues/168813),

> "we are not actively developing Material 3 Expressive, and we will not be accepting contributions for Expressive features or updates at this time"

Il lavoro futuro avverrà nei package standalone in cui Material verrà scorporato — iniziativa avviata a luglio 2025, tracciata su flutter/flutter#101479 — senza date annunciate.

### Cosa esiste davvero nell'SDK in uso (Flutter 3.38.7)

Verificato ispezionando `packages/flutter/lib/src/material/`:

| Elemento Expressive | Stato | Riferimento |
|---|---|---|
| Palette expressive | ✅ nativo | `DynamicSchemeVariant.expressive` in `ColorScheme.fromSeed` |
| Token di durata e curve | ✅ nativo | `Durations` ed `Easing` in `motion.dart`, esportati da `material.dart` |
| Motion fisico a molla | ❌ assente | `page_transitions_theme.dart` lo dichiara esplicitamente non implementato |
| Libreria di forme (35) e morphing | ❌ assente | nessun `MaterialShapes`, nessun `ShapeMorph` |
| Tipografia emphasized | ❌ assente | — |
| 15 componenti nuovi o aggiornati | ❌ assenti | nessun button group, split button, FAB menu, loading indicator, toolbar |

## Opzioni valutate

### A — Package di terze parti per tutto

Stato reale dei candidati, verificato su pub.dev il 2026-08-06:

| Package | Versione | Pubblicato | Like | Download 30gg | SDK richiesto |
|---|---|---|---|---|---|
| `motor` (motion a molla) | 1.1.0 | 2025-12-02 | **238** | **77.299** | `>=3.5.0` ✅ |
| `m3e_collection` | 0.3.7 | 2025-11-12 | 33 | 822 | `>=3.5.0` ✅ |
| `m3e_design` | 0.2.1 | 2025-10-25 | 2 | 3.257 | `>=3.5.0` ✅ |
| `material3_expressive_loading_indicator` | 0.1.2 | 2026-05-09 | — | — | `^3.8.1` ✅ |
| `m3e_buttons` | 0.0.5 | 2026-07-28 | — | — | **`^3.11.1` ❌** |

Due fatti pesano:

- **`m3e_buttons` non è installabile**: richiede Dart `^3.11.1`, il progetto è su 3.10.7. Adottarlo imporrebbe un aggiornamento dell'SDK come prerequisito di una storia di UI.
- **La famiglia `m3e_*` è acerba**: tutte versioni `0.x`, adozione bassa (`m3e_collection`: 822 download in un mese). Un package `0.x` poco adottato può cambiare API senza preavviso o essere abbandonato, e diventerebbe una dipendenza strutturale dell'intera interfaccia.

`motor` è un caso a sé: 238 like e 77.000 download mensili sono numeri da libreria consolidata.

### B — Implementazione interna integrale

Controllo totale e nessun rischio di abbandono, ma significa riscrivere a mano 35 forme, il sistema di motion a molla e 15 componenti. Costo sproporzionato, e con alta probabilità di risultati peggiori di quelli di chi ci si è dedicato.

### C — Ibrido, per categoria

Ogni categoria di token o componente segue la strada più adatta:

| Categoria | Strada | Perché |
|---|---|---|
| Colore | **nativo** | `DynamicSchemeVariant.expressive` esiste ed è supportato |
| Durate e curve | **nativo** | `Durations` ed `Easing` esistono |
| Spaziature, raggi, elevazioni | **interno** | Sono valori, non comportamenti: scriverli costa poco e non giustifica una dipendenza |
| Tipografia emphasized | **interno** | Variazioni di peso e spaziatura sul font già in uso |
| Motion a molla | **package `motor`** | Maturo e adottato; riscriverlo sarebbe lavoro sprecato |
| Forme e morphing | **interno** — deciso il 2026-08-06 | `m3e_design` valutato leggendone il sorgente: non serve. Vedi sotto |
| Componenti | **interno, valutando caso per caso** | La famiglia `m3e_*` è acerba e una parte non è nemmeno installabile |

## Aggiornamento del 2026-08-06 — forme e morphing

La riga «da decidere in US-035» è chiusa, e la decisione è **interno**.

`m3e_design 0.2.1` è stato installato e **letto**, non giudicato dalla descrizione. Si installa
senza problemi con l'SDK del progetto — a differenza di `m3e_buttons` — ma non contiene ciò che
serve:

| Cosa promette il nome | Cosa contiene davvero |
|---|---|
| Libreria di forme Expressive | Due insiemi di `BorderRadius` (`round` e `square`, cinque misure ciascuno): rettangoli con raggi diversi |
| Morphing | **Niente**: `grep -rl morph` su tutto il package non trova nulla |
| 35 forme (cookie, sunny, pentagon…) | Nessuna. Nessun `ShapeBorder`, nessuna `Path` |

Nove file, 946 righe, quasi tutte token di colore, spaziatura e tipografia — cioè **ciò che
`ExpressiveTokens` fa già dal giorno di US-033**. Adottarlo aggiungerebbe una dipendenza `0.x` e la
sua transitiva `dynamic_color` per duplicare quello che abbiamo, senza risolvere il problema per cui
la si stava valutando.

Le forme e il morphing di US-035 vanno quindi costruiti. È coerente con il principio di questo
documento: quando una categoria non esiste né in Flutter né in un package maturo, si scrive
internamente e si espone da `ExpressiveTokens`, così che il giorno in cui esisterà davvero la
migrazione resti un lavoro su un file solo.

## Decisione

**Opzione C — ibrido, per categoria.**

Tutti i token, di qualunque provenienza, sono esposti da un unico punto: una `ThemeExtension` chiamata `ExpressiveTokens`, letta con `Theme.of(context).extension<ExpressiveTokens>()`.

I widget non sanno mai da dove arriva un token. Che sia nativo, interno o di un package, la lettura è identica.

## Conseguenze

**Positive**

- Nessuna dipendenza acerba nel percorso critico dell'interfaccia
- Nessun aggiornamento forzato dell'SDK
- I widget dipendono dall'astrazione, non dalla sorgente: cambiare la seconda non tocca i primi
- Quando arriverà il supporto ufficiale, la migrazione è la riscrittura di un solo file

**Negative**

- Le forme e i componenti vanno costruiti, e costano più che installarli
- I token interni vanno mantenuti allineati alle specifiche Material man mano che evolvono
- Va evitato che `ExpressiveTokens` diventi un contenitore indistinto: ci vanno solo i token del design system, non le costanti di una singola schermata

**Condizione di revisione**

Questa decisione va rivista se si verifica una di queste condizioni:

1. Flutter annuncia il supporto Expressive nei package standalone
2. La famiglia `m3e_*` raggiunge la 1.0 con adozione consistente
3. Il progetto aggiorna l'SDK oltre Dart 3.11, rendendo installabile `m3e_buttons`

## Riferimenti

- [flutter/flutter#168813](https://github.com/flutter/flutter/issues/168813) — issue ombrello Material 3 Expressive
- [docs.flutter.dev/ui/design/material](https://docs.flutter.dev/ui/design/material)
- [pub.dev/packages/motor](https://pub.dev/packages/motor) · [m3e_collection](https://pub.dev/packages/m3e_collection) · [m3e_design](https://pub.dev/packages/m3e_design)
