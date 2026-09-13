// Legge il ruleset attivo di cloud.firestore dall'API, invece di fidarsi del
// solo "Deploy complete!" (criterio esplicito di US-087).
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
  console.log('Contiene "match /invites/{inviteId}":', hasInvites);
  console.log('Contiene "match /invite_codes/{code}":', hasInviteCodes);
  console.log('Lunghezza ruleset attivo:', text.length, 'caratteri');

  if (!hasInvites || !hasInviteCodes) {
    console.error('Il ruleset attivo NON contiene le regole attese.');
    process.exit(1);
  }
  console.log('Verificato: il ruleset attivo sul progetto reale contiene le nuove regole.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
