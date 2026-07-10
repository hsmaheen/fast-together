import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import assert from 'node:assert/strict';
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

async function seedCircle({
  circleId = 'circle-1',
  memberUids = ['member-1', 'member-2'],
} = {}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(doc(db, `fastingCircles/${circleId}`), {
      name: 'Morning Circle',
      createdByUid: memberUids[0],
      memberCount: memberUids.length,
      createdAt: Timestamp.fromDate(new Date('2026-07-01T00:00:00Z')),
      updatedAt: Timestamp.fromDate(new Date('2026-07-01T00:00:00Z')),
    });

    for (const uid of memberUids) {
      await setDoc(doc(db, `fastingCircles/${circleId}/members/${uid}`), {
        uid,
        circleId,
      });
    }
  });
}

test('Circle Members can read circle membership while non-members cannot', async () => {
  await seedCircle();
  const memberDb = testEnv.authenticatedContext('member-1').firestore();
  const nonMemberDb = testEnv.authenticatedContext('non-member').firestore();

  await assertSucceeds(getDoc(doc(memberDb, 'fastingCircles/circle-1')));
  await assertSucceeds(
    getDocs(collection(memberDb, 'fastingCircles/circle-1/members')),
  );
  await assertFails(getDoc(doc(nonMemberDb, 'fastingCircles/circle-1')));
  await assertFails(
    getDocs(collection(nonMemberDb, 'fastingCircles/circle-1/members')),
  );
});

test('a Circle Member can edit the Fasting Circle name', async () => {
  await seedCircle();
  const memberDb = testEnv.authenticatedContext('member-2').firestore();

  await assertSucceeds(
    updateDoc(doc(memberDb, 'fastingCircles/circle-1'), {
      name: 'Evening Circle',
      updatedAt: serverTimestamp(),
    }),
  );
});

test('an App Account owner can read the trusted Circle Membership index', async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(
        context.firestore(),
        'appAccounts/member-1/circleMembershipState/current',
      ),
      { circleIds: ['circle-1', 'circle-2'] },
    );
  });
  const ownerDb = testEnv.authenticatedContext('member-1').firestore();
  const otherMemberDb = testEnv
    .authenticatedContext('member-2')
    .firestore();
  const membershipStateRef = doc(
    ownerDb,
    'appAccounts/member-1/circleMembershipState/current',
  );

  await assertSucceeds(getDoc(membershipStateRef));
  await assertFails(
    getDoc(
      doc(
        otherMemberDb,
        'appAccounts/member-1/circleMembershipState/current',
      ),
    ),
  );
  await assertFails(
    setDoc(membershipStateRef, {
      circleIds: ['circle-1', 'circle-2', 'circle-3'],
    }),
  );
});

test('a Circle Member writes their current Shared Fasting Activity for members to read', async () => {
  await seedCircle();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'appAccounts/member-1'), {
      activeDeviceId: 'device-1',
    });
  });
  const sharingMemberDb = testEnv
    .authenticatedContext('member-1')
    .firestore();
  const otherMemberDb = testEnv
    .authenticatedContext('member-2')
    .firestore();
  const activityPath =
    'fastingCircles/circle-1/sharedFastingActivity/member-1';

  await assertSucceeds(
    setDoc(doc(sharingMemberDb, activityPath), {
      status: 'Fasting',
      startedAt: Timestamp.fromDate(new Date('2026-07-01T08:00:00Z')),
      targetEndedAt: Timestamp.fromDate(new Date('2026-07-02T00:00:00Z')),
      activeDeviceId: 'device-1',
      updatedAt: serverTimestamp(),
    }),
  );
  await assertSucceeds(getDoc(doc(otherMemberDb, activityPath)));
});

test('clients cannot bypass trusted four-member and five-membership limits', async () => {
  await seedCircle({
    memberUids: ['member-1', 'member-2', 'member-3', 'member-4'],
  });
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(
        context.firestore(),
        'appAccounts/member-1/circleMembershipState/current',
      ),
      {
        circleIds: [
          'circle-1',
          'circle-2',
          'circle-3',
          'circle-4',
          'circle-5',
        ],
      },
    );
  });
  const memberDb = testEnv.authenticatedContext('member-1').firestore();

  await assertFails(
    setDoc(doc(memberDb, 'fastingCircles/circle-1/members/member-5'), {
      uid: 'member-5',
      circleId: 'circle-1',
    }),
  );
  await assertFails(
    updateDoc(doc(memberDb, 'fastingCircles/circle-1'), {
      memberCount: 5,
      updatedAt: serverTimestamp(),
    }),
  );
  await assertFails(
    setDoc(
      doc(memberDb, 'appAccounts/member-1/circleMembershipState/current'),
      {
        circleIds: [
          'circle-1',
          'circle-2',
          'circle-3',
          'circle-4',
          'circle-5',
          'circle-6',
        ],
      },
    ),
  );
});

test('Circle Membership lifecycle writes are trusted-only', async () => {
  await seedCircle();
  const memberDb = testEnv.authenticatedContext('member-1').firestore();
  const membershipRef = doc(
    memberDb,
    'fastingCircles/circle-1/members/member-1',
  );

  await assertFails(
    updateDoc(membershipRef, {
      uid: 'member-1',
      circleId: 'circle-2',
    }),
  );
  await assertFails(deleteDoc(membershipRef));
  await assertFails(
    setDoc(doc(memberDb, 'fastingCircles/circle-1/members/member-3'), {
      uid: 'member-3',
      circleId: 'circle-1',
    }),
  );
});

test('Shared Fasting Activity rejects non-members and writes for another member', async () => {
  await seedCircle();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'appAccounts/member-1'), {
      activeDeviceId: 'device-1',
    });
    await setDoc(
      doc(db, 'fastingCircles/circle-1/sharedFastingActivity/member-1'),
      {
        status: 'Not Fasting',
        activeDeviceId: 'device-1',
        updatedAt: Timestamp.fromDate(new Date('2026-07-01T00:00:00Z')),
      },
    );
  });
  const nonMemberDb = testEnv.authenticatedContext('non-member').firestore();
  const otherMemberDb = testEnv
    .authenticatedContext('member-2')
    .firestore();
  const activityPath =
    'fastingCircles/circle-1/sharedFastingActivity/member-1';

  await assertFails(getDoc(doc(nonMemberDb, activityPath)));
  await assertFails(
    getDocs(
      collection(
        nonMemberDb,
        'fastingCircles/circle-1/sharedFastingActivity',
      ),
    ),
  );
  await assertFails(
    setDoc(doc(otherMemberDb, activityPath), {
      status: 'Not Fasting',
      activeDeviceId: 'device-1',
      updatedAt: serverTimestamp(),
    }),
  );
});

test('Shared Fasting Activity stops exposing a former Circle Member', async () => {
  await seedCircle();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(
      doc(db, 'fastingCircles/circle-1/sharedFastingActivity/member-1'),
      {
        status: 'Fasting',
        startedAt: Timestamp.fromDate(new Date('2026-07-01T08:00:00Z')),
        targetEndedAt: Timestamp.fromDate(new Date('2026-07-02T00:00:00Z')),
        activeDeviceId: 'device-1',
        updatedAt: Timestamp.fromDate(new Date('2026-07-01T08:00:00Z')),
      },
    );
    await deleteDoc(
      doc(db, 'fastingCircles/circle-1/members/member-1'),
    );
  });
  const remainingMemberDb = testEnv
    .authenticatedContext('member-2')
    .firestore();

  await assertFails(
    getDoc(
      doc(
        remainingMemberDb,
        'fastingCircles/circle-1/sharedFastingActivity/member-1',
      ),
    ),
  );
  await assertFails(
    getDocs(
      collection(
        remainingMemberDb,
        'fastingCircles/circle-1/sharedFastingActivity',
      ),
    ),
  );
});

test('Shared Fasting Activity allows only current-status derivation data from the Active Device', async () => {
  await seedCircle();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'appAccounts/member-1'), {
      activeDeviceId: 'current-device',
    });
  });
  const memberDb = testEnv.authenticatedContext('member-1').firestore();
  const activityRef = doc(
    memberDb,
    'fastingCircles/circle-1/sharedFastingActivity/member-1',
  );
  const validFastingProjection = {
    status: 'Fasting',
    startedAt: Timestamp.fromDate(new Date('2026-07-01T08:00:00Z')),
    targetEndedAt: Timestamp.fromDate(new Date('2026-07-02T00:00:00Z')),
    activeDeviceId: 'current-device',
    updatedAt: serverTimestamp(),
  };

  await assertFails(
    setDoc(activityRef, {
      ...validFastingProjection,
      elapsedSeconds: 60,
    }),
  );
  await assertFails(
    setDoc(activityRef, {
      ...validFastingProjection,
      actualEndedAt: Timestamp.fromDate(new Date('2026-07-02T01:00:00Z')),
    }),
  );
  await assertFails(
    setDoc(activityRef, {
      ...validFastingProjection,
      activeDeviceId: 'superseded-device',
    }),
  );
  await assertFails(
    setDoc(activityRef, {
      ...validFastingProjection,
      targetEndedAt: Timestamp.fromDate(new Date('2026-07-01T07:00:00Z')),
    }),
  );
});

test('Not Fasting replaces timing data instead of retaining circle history', async () => {
  await seedCircle();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'appAccounts/member-1'), {
      activeDeviceId: 'device-1',
    });
  });
  const memberDb = testEnv.authenticatedContext('member-1').firestore();
  const activityRef = doc(
    memberDb,
    'fastingCircles/circle-1/sharedFastingActivity/member-1',
  );

  await assertSucceeds(
    setDoc(activityRef, {
      status: 'Fasting',
      startedAt: Timestamp.fromDate(new Date('2026-07-01T08:00:00Z')),
      targetEndedAt: Timestamp.fromDate(new Date('2026-07-02T00:00:00Z')),
      activeDeviceId: 'device-1',
      updatedAt: serverTimestamp(),
    }),
  );
  await assertSucceeds(
    setDoc(activityRef, {
      status: 'Not Fasting',
      activeDeviceId: 'device-1',
      updatedAt: serverTimestamp(),
    }),
  );
  const activity = await getDoc(activityRef);

  assert.equal(activity.get('status'), 'Not Fasting');
  assert.equal(activity.get('startedAt'), undefined);
  assert.equal(activity.get('targetEndedAt'), undefined);
});

test('Circle Membership never exposes another member Personal Fasting Activity', async () => {
  await seedCircle();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(
        context.firestore(),
        'appAccounts/member-1/fastingSessions/personal-session',
      ),
      {
        startedAt: Timestamp.fromDate(new Date('2026-07-01T08:00:00Z')),
      },
    );
  });
  const otherMemberDb = testEnv
    .authenticatedContext('member-2')
    .firestore();

  await assertFails(
    getDoc(
      doc(
        otherMemberDb,
        'appAccounts/member-1/fastingSessions/personal-session',
      ),
    ),
  );
  await assertFails(
    getDocs(
      collection(otherMemberDb, 'appAccounts/member-1/fastingSessions'),
    ),
  );
});
