# US-101 — Review

**Data:** 2026-08-11 · **Branch:** `feature/US-101-dashboard-appbar-collision`
**Commit rivisti:** `7e1db6b` (la consegna, riportata qui dal worktree di Gemini) + `d301318` (le correzioni)
**Chi ha implementato:** Gemini · **Chi rivede:** non ha scritto il codice consegnato

**Verdetto: RESPINTA alla consegna, APPROVATA dopo le correzioni.**
Il difetto che la storia chiude era ancora intero, e il test consegnato non poteva accorgersene.

---

## Cosa era giusto, e va detto per primo

- **La diagnosi era corretta**: il `title` della `SliverAppBar.large` era `null`, e dare alla barra
  compressa un titolo suo — una riga, troncata — è la metà giusta della soluzione. È rimasta.
- **`analyze`: 17, elenco identico a `main`.** Vero, verificato riga per riga.
- **`flutter test`: 504 verdi.** Vero, rifatto nel worktree.
- **Il `maxLines: 1` e l'`overflow: ellipsis` sul nome** erano il secondo difetto del piano, ed è
  stato chiuso.
- **La lettura del `ColorScheme` e dei token** non è stata toccata: nessun valore numerico nuovo.

---

## 🔴-1 · La correzione non scattava mai

La condizione consegnata:

```dart
final isCompressed = constraints.maxHeight
    <= kToolbarHeight + MediaQuery.paddingOf(context).top + 1.0;
```

`kToolbarHeight` è **56**. Ma la variante `large` si comprime a **64**
(`_LargeScrollUnderFlexibleConfig.collapsedHeight`, in `app_bar.dart`). Otto dp di differenza, e
`64 <= 57` è falso: **il blocco a due righe non veniva nascosto in nessuno stato.**

Misurato con una sonda, prima delle correzioni: dopo un trascinamento di 300 px il testo
«Bentornato,» era **ancora presente**, con rettangolo `LTRB(20, 1, 176.8, 21)` contro l'hamburger a
`LTRB(16, 20, 40, 44)`. **Si sovrappongono.** Cioè esattamente ciò che l'utente aveva segnalato.

## 🔴-2 · Il test consegnato restava verde anche senza correzione

Cercava il nome così:

```dart
find.descendant(of: find.byType(NavigationToolbar), matching: find.text(nome)).last
```

Quel titolo lo posiziona `NavigationToolbar` **fra** il cassetto e le azioni: per costruzione non
può intersecarli. Il widget che si sovrappone è un altro — il titolo dello spazio flessibile, che
sale insieme al fondo della barra — e il test non lo guardava mai.

Due misure lo dimostrano: il test passa **anche senza trascinare affatto**, e passava con il difetto
intero. È il difetto n. 2 dell'handoff, «test che certificano meno del loro nome».

## 🔴-3 · E anche con la soglia giusta non sarebbe bastato

Corretta la soglia — usando `FlexibleSpaceBarSettings.isScrolledUnder`, cioè lo stesso segnale con
cui Material fa comparire il titolo della toolbar — il blocco spariva, ma **troppo tardi**.

`FlexibleSpaceBar` tiene il proprio titolo a distanza fissa dal **fondo** della barra: mentre la
barra si accorcia, il titolo sale con lei. Misurato su `main`:

| Scorrimento | `top` del saluto | Sovrapposto all'hamburger |
|---|---|---|
| 20 px | 52.4 | no |
| **24 px** | **34.3** | **sì** |
| 32 px | 1.0 | sì |

**Bastano 24 px sugli 88 di corsa.** La sovrapposizione accade molto prima della compressione, e per
lo stesso motivo non si può risolvere con una dissolvenza: il saluto sparirebbe al primo tocco di
scorrimento.

**Corretto** ritagliando lo spazio flessibile sotto la fascia occupata dalle icone, con la fascia
letta da `FlexibleSpaceBarSettings.minExtent` invece che riscritta. A riposo non si sposta niente e
scorrendo il blocco viene mangiato dall'alto invece di essere disegnato sopra.

## 🟡-1 · Una strada scartata, e perché

Ho provato prima a spostare il blocco nello **sfondo** (`background`), che è come Material stessa
costruisce la large app bar. Funziona — nessuna sovrapposizione a nessuna posizione — ma
`FlexibleSpaceBar` **ingrandisce di 1,5 volte** il proprio `title` e non lo sfondo
(`expandedTitleScale`, valore predefinito). Il saluto passava da **255 a 177 dp** di larghezza:
un rimpicciolimento visibile di ciò che è già stato approvato sull'APK in US-062.

Riprodurre l'ingrandimento a mano costava un `Transform.scale` — che però non cambia il layout, e
spostava il blocco **dodici dp più in basso** — oppure un fattore sul carattere, che va in
assertion quando lo stile non ha una `fontSize` esplicita. Entrambe misurate.

Il ritaglio invece non tocca né posizione né dimensione: a riposo il rettangolo è
`LTRB(20, 67.5, 255.1, 97.5)`, **identico a `main`**, ed è quello che il test ora fissa.

## 🟡-2 · Cosa si vede mentre si scorre

Con il ritaglio il saluto viene **tagliato** progressivamente dalla linea delle icone invece di
sfumare. È la metafora dello «scroll under» di Material, e su 8 px di scorrimento è un passaggio
rapido — ma **è un giudizio che vuole l'occhio**, non una misura. Da confermare sull'APK.

---

## Copertura dei criteri

| Criterio | Esito |
|---|---|
| Scorrendo, saluto e nome non si sovrappongono a nessuna icona | ✅ e ora **dimostrato**: il ritaglio esiste, e tutte le icone stanno sopra la sua linea |
| Il nome lungo viene troncato con le ellissi | ✅ `maxLines` e `overflow` verificati su **tutte** le occorrenze del nome |
| Verificato con nome corto e nome lungo | ✅ |
| Da espanso il saluto resta dov'è | ✅ rettangolo confrontato con la misura presa su `main` |
| Si guarda bene | ⬜ **Da confermare sull'APK**, e vedi 🟡-2 |

**Mutazioni, tutte diverse da quelle dell'esecutore — che non ne aveva provata nessuna:** tolto il
ritaglio → rosso; tolto `maxLines` → rosso; spostata la posizione a riposo → rosso.

---

## Fuori scope rilevato

Nessuno: i due file del piano. I registrant di plugin rigenerati sono stati lasciati fuori dal
commit.

⚠️ **Il branch consegnato non era quello previsto.** Gemini ha lavorato in un worktree suo, su
`fix_dashboard_appbar_collision`, **e lo ha pushato** — il mandato diceva di non pushare. Il lavoro
è stato riportato su `feature/US-101-dashboard-appbar-collision`. Il branch remoto va cancellato.

## Limiti dichiarati di questa review

1. **Non ho aperto l'app.** Tutte le misure vengono da sonde in `flutter test` su una superficie di
   prova: la geometria è quella, ma il giudizio su come si legge scorrendo no.
2. **I test non guardano i pixel disegnati.** Provano che il ritaglio c'è e che le icone stanno
   sopra la sua linea — un'invariante, non uno screenshot. Se qualcuno cambiasse la posizione delle
   icone portandole sotto quella linea, il test lo direbbe; se cambiasse il colore del testo
   rendendolo illeggibile, no.
3. **Una sola misura di carattere.** Le prove girano alla dimensione di sistema predefinita: con il
   testo ingrandito il blocco è più alto, e il ritaglio ne taglia di più. Che resti leggibile non è
   verificato.

---

_Review di fase 5 · US-101 · su codice non scritto da chi rivede_
