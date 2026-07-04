import {
  Timestamp,
  collection,
  doc,
  getDocs,
  orderBy,
  query,
  setDoc,
} from 'firebase/firestore';

export async function saveEndedFastingSession({ db, ownerUid, session }) {
  if (!session.actualEndTime) {
    throw new Error(
      'Personal Fasting Activity persistence requires an ended Fasting Session',
    );
  }

  const sessionRef = doc(
    db,
    'appAccounts',
    ownerUid,
    'fastingSessions',
    session.id,
  );

  await setDoc(sessionRef, {
    startedAt: Timestamp.fromDate(session.startTime),
    targetEndedAt: Timestamp.fromDate(session.targetEndTime),
    actualEndedAt: Timestamp.fromDate(session.actualEndTime),
    fastingResult: session.fastingResult,
  });
}

export async function loadEndedFastingSessions({ db, ownerUid }) {
  const sessionsRef = collection(
    db,
    'appAccounts',
    ownerUid,
    'fastingSessions',
  );
  const snapshot = await getDocs(
    query(sessionsRef, orderBy('actualEndedAt', 'desc')),
  );

  return snapshot.docs.map((sessionDoc) => {
    const data = sessionDoc.data();

    return {
      id: sessionDoc.id,
      startTime: data.startedAt.toDate(),
      targetEndTime: data.targetEndedAt.toDate(),
      actualEndTime: data.actualEndedAt.toDate(),
      fastingResult: data.fastingResult,
    };
  });
}
