# Riferimenti visivi

Mockup approvati dal prodotto il 2026-08-06, prima dell'inizio del ridisegno. Sono **pagine HTML autonome**: si aprono con un doppio clic, senza server né dipendenze.

Servono a rispondere alla domanda "come deve venire questa schermata" senza doverla ricostruire a memoria o dipendere da un servizio esterno.

| File | Contenuto |
|---|---|
| [`01-direzione-visiva.html`](01-direzione-visiva.html) | Sei schermate sulla palette Indigo: home, sessione, statistiche, serie, riepilogo, scheda esercizio. Catena delle immagini e contrasti misurati |
| [`02-schermate-app.html`](02-schermate-app.html) | Nove schermate: libreria, nuovo esercizio, tipi di allenamento, timer, pillola, notifica, calendario, obiettivi, traguardi, peso, impostazioni, scheda |
| [`03-timer-e-movimento.html`](03-timer-e-movimento.html) | **Timer funzionante**: si avvia, si mette in pausa, cambia modalità. Più il repertorio delle micro-interazioni e l'integrazione con la Now Bar |

## Come leggerli

Ogni schermata ha sotto una didascalia che spiega **la decisione** che incorpora, non solo cosa mostra. È quella la parte che serve durante l'implementazione: il layout si può dedurre guardando, il motivo no.

Il terzo file è interattivo di proposito. Le animazioni del timer — cifre che rotolano, pulsante che muta forma, onde concentriche — si giudicano provandole, non descrivendole. Le curve usate sono le stesse dei token di US-033: `Easing.standard`, `Easing.emphasizedDecelerate`, più una curva elastica per i cambi di forma.

## Quanto sono vincolanti

**Vincolanti.** Decisione del prodotto, 2026-08-06: *«voglio assolutamente che la grafica rispetti i mock»*. Dove il mockup e il codice divergono, **si corregge il codice** — anche quando significa disfare qualcosa di già scritto, come ha fatto US-073.

Questo capovolge quanto scritto qui in precedenza («vince il design system»). I token restano il **modo** in cui i valori entrano nel codice — nessun numero scritto a mano nei widget — ma il **valore** lo decide il mockup: se il mockup disegna una card su `ink-700` e il token dice `ink-800`, si cambia il token.

Restano non vincolanti solo: le sagome degli esercizi (sono segnaposto), i dati mostrati (esempi inventati), e i pixel presi alla lettera.

**I pixel non si copiano mai**: i mockup disegnano un telefono da 282 o 320 px a seconda del file, il telefono reale è 384 dp. La conversione, elemento per elemento, è in [`../DESIGN-SPEC.md`](../DESIGN-SPEC.md) — che è il documento da leggere prima di scrivere un widget.

## Storie che li realizzano

| Mockup | Storie |
|---|---|
| Home, sessione, statistiche | EP-010, EP-014 |
| Serie a cursori, riepilogo, record | US-046, US-049, US-050 |
| Scheda esercizio con progressione | US-068 |
| Libreria e nuovo esercizio | US-065, US-043 |
| Tipi di allenamento | EP-013 |
| Timer, pillola, notifica, Now Bar | EP-011 |
| Calendario, obiettivi, traguardi, peso, impostazioni | US-064, EP-012, US-066, US-067 |

Sono anche pubblicati come artifact su claude.ai, ma quei link sono privati e possono scadere: **la copia autorevole è questa**.
