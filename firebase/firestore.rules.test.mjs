import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
} from 'firebase/firestore';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import {
  loadEndedFastingSessions,
  saveEndedFastingSession,
} from './personal_fasting_activity_repository.mjs';

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-fasting-app',
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: readFileSync('firestore.rules', 'utf8'),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

after(async () => {
  await testEnv.cleanup();
});

test('Personal Fasting Activity is readable and writable by its owner', async () => {
  const ownerDb = testEnv.authenticatedContext('owner-user').firestore();
  const sessionRef = doc(
    ownerDb,
    'appAccounts/owner-user/fastingSessions/session-1',
  );

  await assertSucceeds(
    setDoc(sessionRef, {
      startedAt: Timestamp.fromDate(new Date('2026-07-01T08:00:00Z')),
      targetEndedAt: Timestamp.fromDate(new Date('2026-07-02T00:00:00Z')),
      actualEndedAt: Timestamp.fromDate(new Date('2026-07-02T00:00:00Z')),
      fastingResult: 'Completed',
    }),
  );
  await assertSucceeds(getDoc(sessionRef));
});

test('signed-in owner can save and load an ended Fasting Session', async () => {
  const ownerDb = testEnv.authenticatedContext('owner-user').firestore();
  const endedSession = {
    id: 'session-1',
    startTime: new Date('2026-07-01T08:00:00Z'),
    targetEndTime: new Date('2026-07-02T00:00:00Z'),
    actualEndTime: new Date('2026-07-02T01:30:00Z'),
    fastingResult: 'Completed',
  };

  await assertSucceeds(
    saveEndedFastingSession({
      db: ownerDb,
      ownerUid: 'owner-user',
      session: endedSession,
    }),
  );
  const savedSession = await getDoc(
    doc(ownerDb, 'appAccounts/owner-user/fastingSessions/session-1'),
  );

  await assertSucceeds(
    loadEndedFastingSessions({ db: ownerDb, ownerUid: 'owner-user' }),
  );
  const loadedSessions = await loadEndedFastingSessions({
    db: ownerDb,
    ownerUid: 'owner-user',
  });

  assert.equal(savedSession.get('startedAt') instanceof Timestamp, true);
  assert.equal(savedSession.get('targetEndedAt') instanceof Timestamp, true);
  assert.equal(savedSession.get('actualEndedAt') instanceof Timestamp, true);
  assert.deepStrictEqual(loadedSessions, [endedSession]);
});

test('Personal Fasting Activity rejects unauthenticated access', async () => {
  const guestDb = testEnv.unauthenticatedContext().firestore();
  const sessionRef = doc(
    guestDb,
    'appAccounts/owner-user/fastingSessions/session-1',
  );

  await assertFails(getDoc(sessionRef));
  await assertFails(
    setDoc(sessionRef, {
      startedAt: Timestamp.fromDate(new Date('2026-07-01T08:00:00Z')),
    }),
  );
});

test('Personal Fasting Activity rejects a different signed-in user', async () => {
  const otherUserDb = testEnv.authenticatedContext('other-user').firestore();
  const sessionRef = doc(
    otherUserDb,
    'appAccounts/owner-user/fastingSessions/session-1',
  );

  await assertFails(getDoc(sessionRef));
  await assertFails(
    setDoc(sessionRef, {
      startedAt: Timestamp.fromDate(new Date('2026-07-01T08:00:00Z')),
    }),
  );
  await assertFails(
    getDocs(collection(otherUserDb, 'appAccounts/owner-user/fastingSessions')),
  );
});

test('Firestore rules default-deny unrelated backend paths', async () => {
  const ownerDb = testEnv.authenticatedContext('owner-user').firestore();
  const circleRef = doc(ownerDb, 'fastingCircles/circle-1');

  await assertFails(getDoc(circleRef));
  await assertFails(
    setDoc(circleRef, {
      name: 'Morning Circle',
    }),
  );
});
