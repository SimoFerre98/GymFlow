# Review US-034

**Verdetto:** APPROVATA CON RISERVE
**Data:** 2026-08-06 · **Diff:** 3 file nuovi, 4 modificati, 2 file di test

> La riserva è **prevista dal piano, non una sorpresa**: cambiando l'app da chiara a scura, i testi grigi ancora scritti a mano nelle schermate perdono contrasto. Sono US-022 e US-023 a sistemarli. Vedi in fondo.

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| `ColorScheme` scuro sulla palette, ambra primario | ✅ | Ruoli assegnati a mano; test sui contrasti di ogni ruolo |
| Salmone su un ruolo distinto | ✅ | `tertiary`; test verifica che non coincida con `primary` |
| Esiste il tema chiaro coerente | ✅ | Test dedicato: tutti i ruoli testuali del chiaro superano AA |
| Il tema scuro è predefinito | ✅ | `ThemeSettings.themeMode` vale `ThemeMode.dark` |
| Varianti emphasized per display, headline, title | ✅ | Test su presenza e peso maggiore rispetto allo stile base |
| Emphasized dal font in uso, senza seconda famiglia | ✅ | Test: `fontFamily` coincide con quella del `TextTheme` |
| Cifre a larghezza fissa per le metriche | ✅ | Test: i tre stili contengono `FontFeature.tabularFigures` |
| Colori a mano sostituiti dai ruoli | ✅ | Ricerca: zero `Color(0xFF...)` fuori da `app_palette.dart` e `app_theme.dart` |
| Contrasti verificati da test automatico | ✅ | **35 test** in `contrast_test.dart` |
| Preset limitati ai valori che superano AA | ✅ | Sei preset, ognuno verificato su tre coppie: fondo, card, e come sfondo di bottone |

## La decisione che conta

**Il `ColorScheme` è assemblato a mano, non generato da `fromSeed`.** Vale la pena difendere la scelta perché va contro la prassi comune.

`fromSeed` deriva tutti i ruoli algoritmicamente da un colore. Qui i colori sono cinque, scelti dal prodotto, con i contrasti già misurati coppia per coppia. Passarli a `fromSeed` significherebbe **buttarli via** e riottenere altri valori — probabilmente armoniosi, certamente non quelli approvati.

`DynamicSchemeVariant.expressive` resta invece la strada giusta per il **colore personalizzato dell'utente**: là si ha un solo colore di partenza, e la derivazione algoritmica è esattamente ciò che serve. La distinzione è annotata nel codice.

## Rilievi

### 🔴 Bloccanti

Nessuno.

### 🟡 Da valutare

1. **Il tema chiaro non è un'inversione della palette.** Ambra e salmone su fondo bianco non raggiungono 4,5:1 come testo: sarebbero illeggibili. Il chiaro usa quindi `amberOnLight` e `salmonOnLight` — versioni scurite — per i ruoli testuali, e conserva gli originali sui contenitori, dove funzionano da sfondo.

   È una divergenza fra i due temi, ma è **imposta dalla fisica del contrasto**, non una scelta stilistica: qualunque altra soluzione avrebbe prodotto testo illeggibile in chiaro. Documentata nel codice.

### 🔵 Suggerimenti

2. **I test verificano rapporti minimi, non valori esatti.** Un test che pretendesse `13,05:1` si romperebbe a ogni ritocco impercettibile. Questi si rompono solo quando il contrasto scende sotto la soglia, cioè quando c'è un problema vero. Il messaggio di errore riporta il valore misurato e il livello raggiunto, così chi lo legge sa subito quanto manca.

3. **`AppPalette` contiene solo valori**, l'assegnazione ai ruoli sta nel tema. Chi si chiede "di che colore è un bottone" guarda il tema; chi cerca il valore esatto dell'ambra guarda la palette. Separare i due piani evita che la palette diventi il posto dove si decide anche il significato.

4. **La tipografia emphasized è nei token, non nel `TextTheme`.** Material 3 Expressive la definisce come slot a sé; `TextTheme` non li prevede. Inventarne uno dentro sarebbe stata una forzatura: sta dove US-033 ha messo tutto ciò che il framework non offre.

5. **`ExpressiveTypography` senza `TextTheme` restituisce stili nulli**, non valori inventati. Un default arbitrario sembrerebbe una scelta di design mentre sarebbe solo un riempitivo. Un test lo blocca.

6. **Il tema definisce ora 18 componenti** — bottoni, chip, campi, dialoghi, slider, navigazione — invece dei 4 di prima. È lavoro che US-021, US-022 e US-023 non dovranno più fare a mano schermata per schermata.

## Fuori scope rilevato

Nessuno. Nessuna schermata è stata modificata: applicare i token è US-022 e US-023.

## Regressioni sospette

| Verifica | Esito |
|---|---|
| `flutter analyze` | **66 issue, zero errori** — esattamente il baseline |
| `flutter test` | **66 verdi**, da 25: 41 nuovi fra contrasti e tipografia |
| `flutter build apk --debug` | Completa |
| Installazione sul telefono | ➖ Il dispositivo si è scollegato durante la verifica. L'APK è stato consegnato |
| Preferenze salvate | Le chiavi di `SharedPreferences` non cambiano. **Chi ha già scelto un colore se lo ritrova** — anche se non è più fra i preset, resta valido |

## La riserva, esplicita

L'app passa da chiara a scura. Le schermate contengono ancora **decine di `Colors.grey[...]` e `Colors.white` scritti a mano**, ereditati da quando il fondo era chiaro. Su fondo indigo alcuni di quei testi avranno contrasto scarso.

**Era previsto**: il piano lo elenca fra i rischi accettati, e sono US-022 e US-023 a sostituirli con i ruoli del `ColorScheme`. Ma va detto chiaro invece di essere scoperto sul telefono: **provando questa build, alcune schermate secondarie appariranno sbiadite**. Le tre schermate principali sono le prime a essere sistemate.

Il catalogo del design system, raggiungibile dal menu, mostra la palette applicata correttamente: è il punto migliore da cui giudicare la direzione.
