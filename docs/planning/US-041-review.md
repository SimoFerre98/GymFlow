# Review US-041

**Verdetto:** APPROVATA
**Data:** 2026-08-06 · **Diff:** 2 file nuovi, 1 modificato, 1 file di test, 1 dataset

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| Campi per immagine utente, immagine curata e video | ✅ | `userImageUrl`, `imageUrl`, `videoUrl`, più `videoSearchQuery` |
| Campi opzionali, nessuna migrazione | ✅ | Test: un documento senza i campi nuovi resta valido |
| Riconosce watch, youtu.be, shorts, embed | ✅ | Test per ciascuna forma, più `live` e `youtube-nocookie` |
| Un URL non riconosciuto viene rifiutato | ✅ | Test su domini estranei, lunghezze sbagliate, stringhe non-URL |
| Identificativo estraibile da funzione pura, con test | ✅ | `YouTubeVideo` senza dipendenze da Flutter, **36 test** |
| Serializzazione senza perdita | ✅ | Test di andata e ritorno su tutti i campi |

## Il bug che i test hanno trovato

Vale la pena raccontarlo perché è il motivo per cui questa logica è stata scritta come funzioni pure testabili.

Il controllo del dominio usava `host.endsWith('youtube.com')`. Sembra corretto, e passa tutti i casi ovvi. Ma **`notyoutube.com` finisce per `youtube.com`**: un URL come `https://notyoutube.com/watch?v=dQw4w9WgXcQ` veniva accettato come video YouTube valido, e l'app avrebbe costruito una miniatura da `img.youtube.com` per un video che non esiste.

Il test `un altro dominio non e YouTube` l'ha fatto emergere subito. **Corretto** con un confronto sul dominio esatto o su un suo sottodominio, e la stessa correzione applicata a `searchQueryOf`, che aveva la variante ancora più permissiva `contains('youtube')`.

Aggiunto un test dedicato che copre `notyoutube.com`, `myyoutube.com` e `m.youtube.com` — quest'ultimo **deve** essere accettato, essendo il dominio mobile reale.

Un mio test era invece sbagliato: verificava che `youtu.be/troppocorto` fosse rifiutato, ma "troppocorto" sono esattamente 11 caratteri, quindi è una forma valida. Corretto il test, non il codice, con una nota che spiega l'inganno.

## Rilievi

### 🔴 Bloccanti

Nessuno.

### 🟡 Da valutare — riguarda il materiale, non il codice

1. **Nessuno dei 43 URL forniti è un video: sono tutte ricerche YouTube.** Verificato sul file: 43 occorrenze di `search_query`, zero di `watch?v=` o `youtu.be`.

   Conseguenza concreta: **il terzo anello della catena di ripiego non produce nulla**. La miniatura si ricava dall'identificativo del video, e una ricerca non ne ha. Gli esercizi della libreria curata mostreranno il segnaposto finché non avranno un video scelto o un'immagine.

   Non l'ho aggirato inventando qualcosa. Ho aggiunto `videoSearchQuery` come campo distinto: l'app apre la ricerca, che è meno buono che aprire l'esecuzione ma molto meglio che offrire nulla. `hasSpecificVideo` permette alla UI di distinguere le due promesse invece di fingere che siano la stessa cosa.

   Sostituire le ricerche con video scelti resta un lavoro incrementale: ogni URL sostituito guadagna la miniatura senza toccare il codice.

2. **Compatibilità con dati già importati.** Se un documento Firestore avesse una ricerca dentro `videoUrl` — plausibile per importazioni precedenti — verrebbe letto come video e produrrebbe una miniatura inesistente. `fromMap` lo riconosce e lo sposta nel campo giusto, senza migrazione dei dati. Coperto da test.

### 🔵 Suggerimenti

3. **`YouTubeVideo` è un file separato senza dipendenze da Flutter.** È la parte più facile da sbagliare — cinque forme di URL, e la miniatura dipende da una sola di esse. Funzioni pure significano test rapidi, ed è quello che ha fatto emergere il bug del dominio.

4. **La catena di ripiego è nel modello, non nei widget.** `thumbnailUrl` e `heroImageUrl` decidono una volta per tutte, così US-042 e US-043 non ripetono la logica in ogni schermata.

5. **`heroImageUrl` chiede `maxresdefault`**, non disponibile per ogni video. Chi la usa deve gestire il fallimento del caricamento: è un criterio esplicito di US-042.

## Fuori scope rilevato

Il dataset `assets/data/exercises_seed.json` con i 43 esercizi estratti. Appartiene a US-045, ma è stato prodotto qui perché è ciò che ha permesso di scoprire il problema degli URL: senza guardare i dati reali, il modello sarebbe stato progettato su un'ipotesi sbagliata. **Il file è dati, non codice**: nessuno lo legge ancora.

## Regressioni sospette

| Verifica | Esito |
|---|---|
| `flutter analyze` | **66 issue, zero errori** — baseline |
| `flutter test` | **102 verdi**, da 66: 36 nuovi |
| Build e installazione | ✅ SM-S948B |
| Esercizi esistenti in Firestore | Test: un documento senza i campi nuovi resta valido, nessuna migrazione |
| `type` serializzato | Passato da `toString().split('.')` a `.name`: stesso risultato, forma più diretta. Test di andata e ritorno lo conferma |

## Dati estratti dal materiale

43 esercizi, 12 gruppi muscolari:

| Gruppo | N | | Gruppo | N |
|---|---|---|---|---|
| dorso | 10 | | quadricipiti | 3 |
| petto | 9 | | femorali | 3 |
| spalle | 6 | | glutei | 2 |
| bicipiti | 5 | | addome | 2 |
| tricipiti | 4 | | trapezio | 1 |
| spalle posteriori | 3 | | polpacci | 1 |

Sei esercizi hanno più di un gruppo muscolare. Uno è di tipo `timed` (plank), gli altri 42 `strength`. Tutte le 43 query di ricerca sono state recuperate correttamente.
