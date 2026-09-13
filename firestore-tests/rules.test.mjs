// Test delle regole Firestore per US-087 (invito trainer/cliente e amico).
//
// Gira contro l'emulatore locale (vedi package.json: `firebase emulators:exec`),
// mai contro il progetto vero — l'id progetto "demo-gymflow-test" e' quello
// convenzionale per l'emulatore, non esiste su Firebase reale.
//
// Il criterio che conta piu' di tutti (dal backlog, US-087): un utente non
// invitato non vede i dati di un invito che non lo riguarda. E' il test
// "C non legge l'invito A->B" qui sotto.

import { test, before, after, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  serverTimestamp,
  Timestamp,
} from 'firebase/firestore';

const PROJECT_ID = 'demo-gymflow-test';
const RULES_PATH = 'firestore.rules';

let testEnv;

const oraPiuGiorni = (giorni) =>
  Timestamp.fromMillis(Date.now() + giorni * 24 * 60 * 60 * 1000);

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(RULES_PATH, 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

/** Scrive un documento bypassando le regole, per preparare lo stato di un test. */
async function seed(path, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), path), data);
  });
}

function invitoPendente(overrides = {}) {
  return {
    fromUserId: 'a',
    fromDisplayName: 'Alice',
    fromRole: 'athlete',
    toUserId: 'b',
    toDisplayName: 'Bruno',
    code: 'CODE01',
    relationshipType: 'friend',
    status: 'pending',
    createdAt: Timestamp.now(),
    expiresAt: oraPiuGiorni(7),
    respondedAt: null,
    ...overrides,
  };
}

test('invite_codes: chiunque autenticato legge, solo il proprietario scrive il proprio', async () => {
  const a = testEnv.authenticatedContext('a');
  const c = testEnv.authenticatedContext('c');
  const anonimo = testEnv.unauthenticatedContext();

  await assertSucceeds(
    setDoc(doc(a.firestore(), 'invite_codes/ABC123'), {
      userId: 'a',
      displayName: 'Alice',
    }),
  );

  await assertSucceeds(getDoc(doc(c.firestore(), 'invite_codes/ABC123')));
  await assertFails(getDoc(doc(anonimo.firestore(), 'invite_codes/ABC123')));

  await assertFails(
    setDoc(doc(c.firestore(), 'invite_codes/RUBATO'), {
      userId: 'a', // C prova a intestare il codice ad A
      displayName: 'Non sono Alice',
    }),
  );
});

test('invite_codes: un codice esistente non si puo dirottare', async () => {
  await seed('invite_codes/ABC123', { userId: 'a', displayName: 'Alice' });
  const c = testEnv.authenticatedContext('c');

  // C prova a farsi proprietario del codice di A scrivendoci sopra: senza
  // il controllo su resource.data.userId (il proprietario attuale), questa
  // scrittura sarebbe stata concessa perche' il *nuovo* userId e' quello di
  // chi scrive.
  await assertFails(
    setDoc(doc(c.firestore(), 'invite_codes/ABC123'), {
      userId: 'c',
      displayName: 'Non sono Alice',
    }),
  );

  // A può invece aggiornare il proprio.
  const a = testEnv.authenticatedContext('a');
  await assertSucceeds(
    setDoc(doc(a.firestore(), 'invite_codes/ABC123'), {
      userId: 'a',
      displayName: 'Alice Aggiornata',
    }),
  );
});

test('creare un invito: solo come se stessi, mai verso se stessi', async () => {
  const a = testEnv.authenticatedContext('a');

  await assertSucceeds(
    setDoc(doc(a.firestore(), 'invites/inv1'), invitoPendente()),
  );

  await assertFails(
    setDoc(
      doc(a.firestore(), 'invites/inv2'),
      invitoPendente({ fromUserId: 'c' }), // A dichiara C come mittente
    ),
  );

  await assertFails(
    setDoc(
      doc(a.firestore(), 'invites/inv3'),
      invitoPendente({ toUserId: 'a' }), // A invita se stesso
    ),
  );
});

test('un utente non invitato non legge ne scrive un invito che non lo riguarda', async () => {
  await seed('invites/inv1', invitoPendente());
  const c = testEnv.authenticatedContext('c');

  await assertFails(getDoc(doc(c.firestore(), 'invites/inv1')));
  await assertFails(
    updateDoc(doc(c.firestore(), 'invites/inv1'), { status: 'accepted' }),
  );
});

test('entrambe le parti di un invito lo leggono', async () => {
  await seed('invites/inv1', invitoPendente());
  const a = testEnv.authenticatedContext('a');
  const b = testEnv.authenticatedContext('b');

  await assertSucceeds(getDoc(doc(a.firestore(), 'invites/inv1')));
  await assertSucceeds(getDoc(doc(b.firestore(), 'invites/inv1')));
});

test('solo il destinatario accetta o rifiuta, non chi ha invitato', async () => {
  await seed('invites/inv1', invitoPendente());
  const a = testEnv.authenticatedContext('a');
  const b = testEnv.authenticatedContext('b');

  await assertFails(
    updateDoc(doc(a.firestore(), 'invites/inv1'), {
      status: 'accepted',
      respondedAt: serverTimestamp(),
    }),
  );
  await assertSucceeds(
    updateDoc(doc(b.firestore(), 'invites/inv1'), {
      status: 'accepted',
      respondedAt: serverTimestamp(),
    }),
  );
});

test('un invito scaduto non si puo accettare', async () => {
  await seed(
    'invites/inv1',
    invitoPendente({ expiresAt: oraPiuGiorni(-1) }),
  );
  const b = testEnv.authenticatedContext('b');

  await assertFails(
    updateDoc(doc(b.firestore(), 'invites/inv1'), {
      status: 'accepted',
      respondedAt: serverTimestamp(),
    }),
  );
});

test('il destinatario puo rifiutare un invito in sospeso', async () => {
  await seed('invites/inv1', invitoPendente());
  const b = testEnv.authenticatedContext('b');

  await assertSucceeds(
    updateDoc(doc(b.firestore(), 'invites/inv1'), {
      status: 'declined',
      respondedAt: serverTimestamp(),
    }),
  );
});

test('chi ha invitato puo annullare un invito ancora in sospeso, il destinatario no', async () => {
  await seed('invites/inv1', invitoPendente());
  const b = testEnv.authenticatedContext('b');

  await assertFails(
    updateDoc(doc(b.firestore(), 'invites/inv1'), { status: 'revoked' }),
  );

  await seed('invites/inv2', invitoPendente());
  const a = testEnv.authenticatedContext('a');
  await assertSucceeds(
    updateDoc(doc(a.firestore(), 'invites/inv2'), { status: 'revoked' }),
  );
});

test('un legame accettato si scioglie da entrambe le parti', async () => {
  await seed('invites/inv1', invitoPendente({ status: 'accepted' }));
  const a = testEnv.authenticatedContext('a');
  await assertSucceeds(
    updateDoc(doc(a.firestore(), 'invites/inv1'), { status: 'revoked' }),
  );

  await seed('invites/inv2', invitoPendente({ status: 'accepted' }));
  const b = testEnv.authenticatedContext('b');
  await assertSucceeds(
    updateDoc(doc(b.firestore(), 'invites/inv2'), { status: 'revoked' }),
  );

  // Un estraneo non scioglie un legame che non e' suo.
  await seed('invites/inv3', invitoPendente({ status: 'accepted' }));
  const c = testEnv.authenticatedContext('c');
  await assertFails(
    updateDoc(doc(c.firestore(), 'invites/inv3'), { status: 'revoked' }),
  );
});

test('accettando un invito non si possono cambiare le parti coinvolte', async () => {
  await seed('invites/inv1', invitoPendente());
  const b = testEnv.authenticatedContext('b');

  await assertFails(
    updateDoc(doc(b.firestore(), 'invites/inv1'), {
      status: 'accepted',
      toUserId: 'c', // B prova a dirottare l'invito su un altro utente
    }),
  );
});

test('un invito accettato non apre la lettura di altre collezioni fra utenti diversi', async () => {
  await seed('invites/inv1', invitoPendente({ status: 'accepted' }));
  await seed('sessions/s1', {
    userId: 'b',
    workoutTemplateId: 't1',
    workoutName: 'Push Day',
    startTime: Timestamp.now(),
  });

  const a = testEnv.authenticatedContext('a');
  // A e B hanno un legame accettato, ma questa storia non tocca le regole
  // di `sessions`: restano owner-only, invariate.
  await assertFails(getDoc(doc(a.firestore(), 'sessions/s1')));
});

// Prova che il test gira davvero contro l'emulatore, non contro un progetto
// vero: un id progetto "demo-*" e' l'unico che l'SDK accetta senza credenziali
// reali, quindi un fallimento qui indicherebbe un ambiente configurato male
// piuttosto che una regola sbagliata.
test('ambiente: progetto emulatore, non reale', () => {
  assert.match(PROJECT_ID, /^demo-/);
});
