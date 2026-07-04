import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { Timestamp, doc, getDoc, setDoc } from 'firebase/firestore';
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
      startedAt: Timestamp.fromDate(new Date('2026-07-01T08:00:00Z')),
      targetEndedAt: Timestamp.fromDate(new Date('2026-07-02T00:00:00Z')),
      actualEndedAt: Timestamp.fromDate(new Date('2026-07-02T00:00:00Z')),
      fastingResult: 'Completed',
    }),
  );
  await assertSucceeds(getDoc(sessionRef));
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
