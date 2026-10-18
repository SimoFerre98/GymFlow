// Legge il ruleset attivo di cloud.firestore dall'API, invece di fidarsi del
// solo "Deploy complete!" (criterio esplicito di US-087).
//
// US-092: oltre a cercare le regole attese, confronta il ruleset attivo con
// `firestore.rules` **riga per riga**. Cercare solo delle stringhe non prova
// niente su una regola nuova: la versione precedente di questo script dava
// «Verificato» anche prima del deploy, perche' le stringhe di US-087 c'erano
// gia'.
import { readFileSync } from 'node:fs';
import { requireAuth } from 'firebase-tools/lib/requireAuth.js';
import { getGlobalDefaultAccount } from 'firebase-tools/lib/auth.js';
import { listAllReleases, getRulesetContent } from 'firebase-tools/lib/gcp/rules.js';

const PROJECT_ID = 'gymflow-d5d09';

async function main() {
  const account = getGlobalDefaultAccount();
  if (!account) {
    throw new Error('Nessun account salvato da "firebase login" trovato nel configstore.');
  }
  const options = { project: PROJECT_ID, user: account.user, tokens: account.tokens };
  await requireAuth(options);

  const releases = await listAllReleases(PROJECT_ID);
  console.log('Release trovate:', releases.map((r) => r.name));
  const release = releases.find((r) => r.name.includes('cloud.firestore'));
  if (!release) {
    console.error('Nessuna release cloud.firestore trovata.');
    process.exit(1);
  }
  console.log('Release attiva:', release.name, '-> ruleset', release.rulesetName);

  const content = await getRulesetContent(release.rulesetName);
  const text = content[0].content;

  const hasInvites = text.includes('match /invites/{inviteId}');
  const hasInviteCodes = text.includes('match /invite_codes/{code}');
  const hasConsents = text.includes('match /consents/{consentId}');
  console.log('Contiene "match /invites/{inviteId}":', hasInvites);
  console.log('Contiene "match /invite_codes/{code}":', hasInviteCodes);
  console.log('Contiene "match /consents/{consentId}":', hasConsents);
  console.log('Lunghezza ruleset attivo:', text.length, 'caratteri');

  // Stesso testo del file locale, a meno di fine riga e spazi in coda.
  const normalizza = (t) =>
    t.replace(/\r\n/g, '\n').split('\n').map((r) => r.trimEnd()).join('\n').trim();
  const locale = readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8');
  const identico = normalizza(text) === normalizza(locale);
  console.log('Identico a firestore.rules locale:', identico);

  if (!hasInvites || !hasInviteCodes || !hasConsents) {
    console.error('Il ruleset attivo NON contiene le regole attese.');
    process.exit(1);
  }
  if (!identico) {
    console.error('Il ruleset attivo e\' DIVERSO da firestore.rules locale.');
    process.exit(1);
  }
  console.log('Verificato: il ruleset attivo sul progetto reale e\' identico a firestore.rules.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
