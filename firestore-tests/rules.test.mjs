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
  collection,
  query,
  where,
  getDocs,
  deleteDoc,
  writeBatch,
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

// Regressione: createInvite ora cerca un invito pendente e non scaduto già
// esistente verso la stessa persona (userId/userId/status, tre uguaglianze —
// stesso schema già verificato per `workouts` più sotto) prima di crearne
// uno nuovo, per non duplicare la connessione se lo stesso invito parte due
// volte. La query deve restare permessa dalle regole.
test('invites: la query di createInvite per un duplicato pendente è permessa', async () => {
  await seed('invites/inv1', invitoPendente());
  const a = testEnv.authenticatedContext('a');
  const q = query(
    collection(a.firestore(), 'invites'),
    where('fromUserId', '==', 'a'),
    where('toUserId', '==', 'b'),
    where('status', '==', 'pending'),
  );

  const risultato = await assertSucceeds(getDocs(q));
  assert.equal(risultato.size, 1);
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

// Regressione: `deleteProgram` cercava le schede di un programma filtrando
// solo su `parentProgramId`. Le regole richiedono che ogni query dimostri
// `eMio()` (owner via `userId`): senza quel filtro la lettura veniva negata
// prima ancora del batch di cancellazione, con un vero errore Firebase per
// l'utente che provava a eliminare un programma.
test('workouts: una query senza filtro su userId viene negata, con userId passa', async () => {
  await seed('workouts/w1', { userId: 'a', parentProgramId: 'p1', name: 'Push' });
  await seed('workouts/w2', { userId: 'a', parentProgramId: 'p1', name: 'Pull' });
  const a = testEnv.authenticatedContext('a');

  await assertFails(
    getDocs(query(collection(a.firestore(), 'workouts'), where('parentProgramId', '==', 'p1'))),
  );

  await assertSucceeds(
    getDocs(
      query(
        collection(a.firestore(), 'workouts'),
        where('userId', '==', 'a'),
        where('parentProgramId', '==', 'p1'),
      ),
    ),
  );
});

// ── US-092: il consenso del cliente ───────────────────────────────────────
//
// Il trainer 't' segue il cliente 'c'; 'x' e' un estraneo. Il consenso e' un
// documento con id deterministico (`consents/t_c`) perche' le regole non
// sanno fare ricerche: per sapere se 't' puo' leggere i dati di 'c' devono
// costruire il percorso di UN documento noto.

const consenso = (grants = {}, overrides = {}) => ({
  trainerUserId: 't',
  clientUserId: 'c',
  inviteId: 'inv1',
  grants: { sessions: false, measurements: false, ...grants },
  updatedAt: Timestamp.now(),
  ...overrides,
});

const invitoTrainer = (overrides = {}) =>
  invitoPendente({
    fromUserId: 't',
    fromDisplayName: 'Tina',
    fromRole: 'trainer',
    toUserId: 'c',
    toDisplayName: 'Carlo',
    relationshipType: 'trainer_client',
    ...overrides,
  });

/** Un legame accettato fra 't' e 'c', con i dati del cliente gia' presenti. */
async function legameTrainerCliente(grants = {}, { statoInvito = 'accepted' } = {}) {
  await seed('invites/inv1', invitoTrainer({ status: statoInvito }));
  await seed('consents/t_c', consenso(grants));
  await seed('sessions/s1', {
    userId: 'c',
    workoutName: 'Push Day',
    startTime: Timestamp.now(),
  });
  await seed('sessions/s2', {
    userId: 'c',
    workoutName: 'Pull Day',
    startTime: Timestamp.now(),
  });
  await seed('users/c/measurements/m1', { userId: 'c', weight: 80 });
}

const sessioniDi = (ctx, clienteId) =>
  getDocs(query(collection(ctx.firestore(), 'sessions'), where('userId', '==', clienteId)));

const misureDi = (ctx, clienteId) =>
  getDocs(collection(ctx.firestore(), `users/${clienteId}/measurements`));

test('consenso: il cliente accetta e crea il consenso nello stesso batch', async () => {
  await seed('invites/inv1', invitoTrainer());
  const c = testEnv.authenticatedContext('c');
  const batch = writeBatch(c.firestore());
  batch.update(doc(c.firestore(), 'invites/inv1'), {
    status: 'accepted',
    respondedAt: Timestamp.now(),
  });
  batch.set(doc(c.firestore(), 'consents/t_c'), consenso({ sessions: true }));
  await assertSucceeds(batch.commit());
});

test('consenso: non puo esistere senza un invito accettato nello stesso batch', async () => {
  await seed('invites/inv1', invitoTrainer());
  const c = testEnv.authenticatedContext('c');
  // L'invito resta pendente: il consenso da solo non basta.
  await assertFails(setDoc(doc(c.firestore(), 'consents/t_c'), consenso({ sessions: true })));
});

test('consenso: un legame fra amici non puo avere un consenso', async () => {
  await seed('invites/inv1', invitoPendente({ fromUserId: 't', toUserId: 'c' }));
  const c = testEnv.authenticatedContext('c');
  const batch = writeBatch(c.firestore());
  batch.update(doc(c.firestore(), 'invites/inv1'), {
    status: 'accepted',
    respondedAt: Timestamp.now(),
  });
  batch.set(doc(c.firestore(), 'consents/t_c'), consenso({ sessions: true }));
  await assertFails(batch.commit());
});

test('consenso: il trainer non se lo concede da solo', async () => {
  await seed('invites/inv1', invitoTrainer({ status: 'accepted' }));
  const t = testEnv.authenticatedContext('t');
  // Neanche con l'invito gia' accettato: il consenso lo scrive il cliente.
  await assertFails(setDoc(doc(t.firestore(), 'consents/t_c'), consenso({ sessions: true })));

  const batch = writeBatch(t.firestore());
  batch.set(doc(t.firestore(), 'consents/t_c'), consenso({ sessions: true, measurements: true }));
  await assertFails(batch.commit());
});

test('consenso: un estraneo non puo crearlo ne per se ne per altri', async () => {
  await seed('invites/inv1', invitoTrainer());
  const x = testEnv.authenticatedContext('x');
  await assertFails(setDoc(doc(x.firestore(), 'consents/t_c'), consenso({ sessions: true })));
  await assertFails(
    setDoc(doc(x.firestore(), 'consents/t_x'), consenso({ sessions: true }, { clientUserId: 'x' })),
  );
});

test('consenso: un cliente non puo falsificarne uno per i dati di un altro utente', async () => {
  // L'attacco: 'c' ha un invito vero da 't', e scrive `consents/t_x` dichiarando
  // 'x' come cliente. Se passasse, `consensoDi('x', ...)` troverebbe un consenso
  // con un invito accettato e 't' leggerebbe i dati di 'x', che non ha mai
  // invitato nessuno. Lo ferma il controllo `clientUserId == request.auth.uid`:
  // nessun altro controllo lo isola, e per questo ha il suo test.
  await seed('invites/inv1', invitoTrainer());
  await seed('sessions/sx', { userId: 'x', workoutName: 'Di X', startTime: Timestamp.now() });
  await seed('users/x/measurements/mx', { userId: 'x', weight: 70 });
  const c = testEnv.authenticatedContext('c');
  const batch = writeBatch(c.firestore());
  batch.update(doc(c.firestore(), 'invites/inv1'), {
    status: 'accepted',
    respondedAt: Timestamp.now(),
  });
  batch.set(
    doc(c.firestore(), 'consents/t_x'),
    consenso({ sessions: true, measurements: true }, { clientUserId: 'x' }),
  );
  await assertFails(batch.commit());

  const t = testEnv.authenticatedContext('t');
  await assertFails(sessioniDi(t, 'x'));
  await assertFails(misureDi(t, 'x'));
});

test('consenso: l id deve essere trainer_cliente, e riferirsi all invito giusto', async () => {
  await seed('invites/inv1', invitoTrainer());
  const c = testEnv.authenticatedContext('c');
  const batch = writeBatch(c.firestore());
  batch.update(doc(c.firestore(), 'invites/inv1'), {
    status: 'accepted',
    respondedAt: Timestamp.now(),
  });
  // Un id che non e' `trainer_cliente` non si puo' costruire dal percorso.
  batch.set(doc(c.firestore(), 'consents/altro-id'), consenso({ sessions: true }));
  await assertFails(batch.commit());
});

test('consenso: lo leggono il cliente e il trainer, nessun altro', async () => {
  await legameTrainerCliente({ sessions: true });
  const c = testEnv.authenticatedContext('c');
  const t = testEnv.authenticatedContext('t');
  const x = testEnv.authenticatedContext('x');
  await assertSucceeds(getDoc(doc(c.firestore(), 'consents/t_c')));
  await assertSucceeds(getDoc(doc(t.firestore(), 'consents/t_c')));
  await assertFails(getDoc(doc(x.firestore(), 'consents/t_c')));
});

test('consenso: solo il cliente cambia i grants, e nient altro del documento', async () => {
  await legameTrainerCliente();
  const c = testEnv.authenticatedContext('c');
  const t = testEnv.authenticatedContext('t');

  await assertSucceeds(
    updateDoc(doc(c.firestore(), 'consents/t_c'), {
      grants: { sessions: true, measurements: false },
      updatedAt: Timestamp.now(),
    }),
  );
  // Il trainer non puo' ne' accendere ne' spegnere.
  await assertFails(
    updateDoc(doc(t.firestore(), 'consents/t_c'), {
      grants: { sessions: true, measurements: true },
      updatedAt: Timestamp.now(),
    }),
  );
  // Neanche il cliente puo' cambiare chi e' il trainer o quale invito lo regge.
  await assertFails(
    updateDoc(doc(c.firestore(), 'consents/t_c'), { trainerUserId: 'x' }),
  );
  await assertFails(updateDoc(doc(c.firestore(), 'consents/t_c'), { inviteId: 'altro' }));
});

test('consenso: dopo lo scioglimento i grants non si possono piu cambiare', async () => {
  await legameTrainerCliente({ sessions: true }, { statoInvito: 'revoked' });
  const c = testEnv.authenticatedContext('c');
  await assertFails(
    updateDoc(doc(c.firestore(), 'consents/t_c'), {
      grants: { sessions: true, measurements: true },
      updatedAt: Timestamp.now(),
    }),
  );
});

test('consenso: lo cancellano il cliente o il trainer, non un estraneo', async () => {
  await legameTrainerCliente();
  const x = testEnv.authenticatedContext('x');
  await assertFails(deleteDoc(doc(x.firestore(), 'consents/t_c')));

  const t = testEnv.authenticatedContext('t');
  await assertSucceeds(deleteDoc(doc(t.firestore(), 'consents/t_c')));

  await seed('consents/t_c', consenso());
  const c = testEnv.authenticatedContext('c');
  await assertSucceeds(deleteDoc(doc(c.firestore(), 'consents/t_c')));
});

test('dati: senza alcun consenso concesso il trainer non legge niente', async () => {
  await legameTrainerCliente({ sessions: false, measurements: false });
  const t = testEnv.authenticatedContext('t');
  await assertFails(sessioniDi(t, 'c'));
  await assertFails(getDoc(doc(t.firestore(), 'sessions/s1')));
  await assertFails(misureDi(t, 'c'));
  await assertFails(getDoc(doc(t.firestore(), 'users/c/measurements/m1')));
});

test('dati: con le sessioni concesse il trainer legge le sessioni e NON le misure', async () => {
  await legameTrainerCliente({ sessions: true, measurements: false });
  const t = testEnv.authenticatedContext('t');
  const sessioni = await assertSucceeds(sessioniDi(t, 'c'));
  assert.equal(sessioni.size, 2);
  await assertSucceeds(getDoc(doc(t.firestore(), 'sessions/s1')));
  await assertFails(misureDi(t, 'c'));
  await assertFails(getDoc(doc(t.firestore(), 'users/c/measurements/m1')));
});

test('dati: con le misure concesse il trainer legge le misure e NON le sessioni', async () => {
  await legameTrainerCliente({ sessions: false, measurements: true });
  const t = testEnv.authenticatedContext('t');
  const misure = await assertSucceeds(misureDi(t, 'c'));
  assert.equal(misure.size, 1);
  await assertFails(sessioniDi(t, 'c'));
  await assertFails(getDoc(doc(t.firestore(), 'sessions/s1')));
});

test('dati: la revoca vale subito — la stessa query che passava ora e negata', async () => {
  await legameTrainerCliente({ sessions: true, measurements: true });
  const t = testEnv.authenticatedContext('t');
  const c = testEnv.authenticatedContext('c');

  await assertSucceeds(sessioniDi(t, 'c'));
  await assertSucceeds(misureDi(t, 'c'));

  // Il cliente spegne solo le sessioni.
  await assertSucceeds(
    updateDoc(doc(c.firestore(), 'consents/t_c'), {
      grants: { sessions: false, measurements: true },
      updatedAt: Timestamp.now(),
    }),
  );
  await assertFails(sessioniDi(t, 'c'));
  await assertSucceeds(misureDi(t, 'c'));

  // E poi anche le misure.
  await assertSucceeds(
    updateDoc(doc(c.firestore(), 'consents/t_c'), {
      grants: { sessions: false, measurements: false },
      updatedAt: Timestamp.now(),
    }),
  );
  await assertFails(misureDi(t, 'c'));
});

test('dati: sciogliere il legame — invito revocato e consenso cancellato — chiude tutto', async () => {
  await legameTrainerCliente({ sessions: true, measurements: true });
  const t = testEnv.authenticatedContext('t');
  const c = testEnv.authenticatedContext('c');
  await assertSucceeds(sessioniDi(t, 'c'));

  const batch = writeBatch(c.firestore());
  batch.update(doc(c.firestore(), 'invites/inv1'), { status: 'revoked' });
  batch.delete(doc(c.firestore(), 'consents/t_c'));
  await assertSucceeds(batch.commit());

  await assertFails(sessioniDi(t, 'c'));
  await assertFails(misureDi(t, 'c'));
});

test('dati: se il consenso resta ma l invito e revocato, l accesso e comunque chiuso', async () => {
  // La cintura: non ci si affida al fatto che qualcuno ricordi di cancellare
  // il consenso. Qui lo scioglie il trainer, che il consenso del cliente non
  // lo puo' toccare — e senza questo controllo resterebbe in grado di leggere.
  await legameTrainerCliente({ sessions: true, measurements: true });
  const t = testEnv.authenticatedContext('t');
  await assertSucceeds(sessioniDi(t, 'c'));

  await assertSucceeds(
    updateDoc(doc(t.firestore(), 'invites/inv1'), { status: 'revoked' }),
  );

  await assertFails(sessioniDi(t, 'c'));
  await assertFails(getDoc(doc(t.firestore(), 'sessions/s1')));
  await assertFails(misureDi(t, 'c'));
});

test('dati: un estraneo, o il trainer di un altro cliente, non legge niente', async () => {
  await legameTrainerCliente({ sessions: true, measurements: true });
  await seed('sessions/s9', { userId: 'd', workoutName: 'Altro', startTime: Timestamp.now() });
  await seed('users/d/measurements/m9', { userId: 'd', weight: 70 });

  const x = testEnv.authenticatedContext('x');
  await assertFails(sessioniDi(x, 'c'));
  await assertFails(misureDi(x, 'c'));

  // Il consenso di 'c' non apre 'd': il percorso del consenso dipende dal
  // cliente di cui si chiedono i dati.
  const t = testEnv.authenticatedContext('t');
  await assertFails(sessioniDi(t, 'd'));
  await assertFails(misureDi(t, 'd'));
});

test('dati: il trainer non puo leggere le sessioni di tutti senza dire di chi', async () => {
  await legameTrainerCliente({ sessions: true });
  const t = testEnv.authenticatedContext('t');
  await assertFails(getDocs(collection(t.firestore(), 'sessions')));
});

test('dati: il trainer non scrive mai sui dati del cliente, qualunque cosa sia concessa', async () => {
  await legameTrainerCliente({ sessions: true, measurements: true });
  const t = testEnv.authenticatedContext('t');

  await assertFails(updateDoc(doc(t.firestore(), 'sessions/s1'), { workoutName: 'Rubato' }));
  await assertFails(deleteDoc(doc(t.firestore(), 'sessions/s1')));
  await assertFails(
    setDoc(doc(t.firestore(), 'sessions/s3'), {
      userId: 'c',
      workoutName: 'Inventata',
      startTime: Timestamp.now(),
    }),
  );
  await assertFails(updateDoc(doc(t.firestore(), 'users/c/measurements/m1'), { weight: 1 }));
  await assertFails(deleteDoc(doc(t.firestore(), 'users/c/measurements/m1')));
  await assertFails(setDoc(doc(t.firestore(), 'users/c/measurements/m3'), { userId: 'c', weight: 1 }));
});

test('dati: il cliente legge e scrive i propri come prima', async () => {
  await legameTrainerCliente();
  const c = testEnv.authenticatedContext('c');
  await assertSucceeds(sessioniDi(c, 'c'));
  await assertSucceeds(misureDi(c, 'c'));
  await assertSucceeds(updateDoc(doc(c.firestore(), 'sessions/s1'), { workoutName: 'Mio' }));
});

test('dati: un legame fra amici accettato non apre le sessioni ne le misure', async () => {
  await seed('invites/inv1', invitoPendente({ fromUserId: 't', toUserId: 'c', status: 'accepted' }));
  await seed('sessions/s1', { userId: 'c', workoutName: 'Push', startTime: Timestamp.now() });
  await seed('users/c/measurements/m1', { userId: 'c', weight: 80 });
  const t = testEnv.authenticatedContext('t');
  await assertFails(sessioniDi(t, 'c'));
  await assertFails(misureDi(t, 'c'));
});

// Prova che il test gira davvero contro l'emulatore, non contro un progetto
// vero: un id progetto "demo-*" e' l'unico che l'SDK accetta senza credenziali
// reali, quindi un fallimento qui indicherebbe un ambiente configurato male
// piuttosto che una regola sbagliata.
test('ambiente: progetto emulatore, non reale', () => {
  assert.match(PROJECT_ID, /^demo-/);
});
