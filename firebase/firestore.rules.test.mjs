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
  writeBatch,
} from 'firebase/firestore';
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';

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
      startTime: Timestamp.fromDate(new Date('2026-07-01T08:00:00Z')),
      targetEndTime: Timestamp.fromDate(new Date('2026-07-02T00:00:00Z')),
      actualEndTime: Timestamp.fromDate(new Date('2026-07-02T00:00:00Z')),
    }),
  );
  await assertSucceeds(getDoc(sessionRef));
});

test('an active Fasting Session requires an atomic owner state write', async () => {
  const ownerDb = testEnv.authenticatedContext('owner-user').firestore();
  const sessionRef = doc(
    ownerDb,
    'appAccounts/owner-user/fastingSessions/session-1',
  );
  const stateRef = doc(
    ownerDb,
    'appAccounts/owner-user/personalFastingActivity/current',
  );
  const activeSession = {
    startTime: Timestamp.fromDate(new Date('2026-07-01T08:00:00Z')),
    targetEndTime: Timestamp.fromDate(new Date('2026-07-02T00:00:00Z')),
  };

  await assertFails(setDoc(sessionRef, activeSession));

  const batch = writeBatch(ownerDb);
  batch.set(sessionRef, activeSession);
  batch.set(stateRef, { activeSessionId: 'session-1' });
  await assertSucceeds(
    batch.commit(),
  );

  await assertSucceeds(getDoc(sessionRef));
  await assertSucceeds(getDoc(stateRef));
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
      startTime: Timestamp.fromDate(new Date('2026-07-01T08:00:00Z')),
      targetEndTime: Timestamp.fromDate(new Date('2026-07-02T00:00:00Z')),
      actualEndTime: Timestamp.fromDate(new Date('2026-07-02T00:00:00Z')),
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
      startTime: Timestamp.fromDate(new Date('2026-07-01T08:00:00Z')),
      targetEndTime: Timestamp.fromDate(new Date('2026-07-02T00:00:00Z')),
      actualEndTime: Timestamp.fromDate(new Date('2026-07-02T00:00:00Z')),
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
