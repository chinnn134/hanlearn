import { after, before, beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
} from 'firebase/firestore';

let environment;

before(async () => {
  environment = await initializeTestEnvironment({
    projectId: 'demo-hanlearn-rules-tests',
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

beforeEach(async () => environment.clearFirestore());
after(async () => environment?.cleanup());

function client(uid, email) {
  return environment.authenticatedContext(uid, { email }).firestore();
}

function profile(email, displayName = 'Người học') {
  return {
    displayName,
    email,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };
}

test('owner creates, reads, and changes only the display name', async () => {
  const alice = client('alice', 'alice@example.invalid');
  const reference = doc(alice, 'users/alice');
  await assertSucceeds(setDoc(reference, profile('alice@example.invalid')));
  const created = await assertSucceeds(getDoc(reference));
  assert.equal(created.data().displayName, 'Người học');
  assert.ok(created.data().createdAt instanceof Timestamp);
  await assertSucceeds(updateDoc(reference, {
    displayName: 'Alice',
    updatedAt: serverTimestamp(),
  }));
  const updated = await assertSucceeds(getDoc(reference));
  assert.equal(updated.data().displayName, 'Alice');
  assert.equal(updated.data().createdAt.toMillis(), created.data().createdAt.toMillis());
});

test('guest and another account cannot access a profile', async () => {
  const alice = client('alice', 'alice@example.invalid');
  const bob = client('bob', 'bob@example.invalid');
  const guest = environment.unauthenticatedContext().firestore();
  await assertSucceeds(setDoc(doc(alice, 'users/alice'), profile('alice@example.invalid')));
  await assertFails(getDoc(doc(bob, 'users/alice')));
  await assertFails(updateDoc(doc(bob, 'users/alice'), {
    displayName: 'Bob', updatedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(bob, 'users/alice'), profile('bob@example.invalid')));
  await assertFails(getDoc(doc(guest, 'users/alice')));
  await assertFails(getDocs(collection(alice, 'users')));
  await assertFails(deleteDoc(doc(alice, 'users/alice')));
});

test('invalid profile fields, types, timestamps, and email are rejected', async () => {
  const alice = client('alice', 'alice@example.invalid');
  const reference = doc(alice, 'users/alice');
  await assertFails(setDoc(reference, { ...profile('alice@example.invalid'), role: 'admin' }));
  await assertFails(setDoc(reference, profile('other@example.invalid')));
  await assertFails(setDoc(reference, profile('alice@example.invalid', 42)));
  await assertFails(setDoc(reference, {
    ...profile('alice@example.invalid'), createdAt: Timestamp.now(),
  }));
  await assertSucceeds(setDoc(reference, profile('alice@example.invalid')));
  await assertFails(updateDoc(reference, {
    role: 'admin', updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(reference, {
    email: 'other@example.invalid', updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(reference, {
    displayName: 'x'.repeat(81), updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(reference, { displayName: 'No timestamp' }));
});

test('signed-in users read vocabulary but no client writes it', async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'vocabulary/sample'), {
      hanzi: '学习', pinyin: 'xuéxí', meaningVi: 'học tập',
    });
  });
  const alice = client('alice', 'alice@example.invalid');
  const bob = client('bob', 'bob@example.invalid');
  const guest = environment.unauthenticatedContext().firestore();
  await assertSucceeds(getDoc(doc(alice, 'vocabulary/sample')));
  await assertSucceeds(getDoc(doc(bob, 'vocabulary/sample')));
  await assertFails(getDoc(doc(guest, 'vocabulary/sample')));
  await assertFails(setDoc(doc(alice, 'vocabulary/new'), { hanzi: '新' }));
  await assertFails(updateDoc(doc(alice, 'vocabulary/sample'), { hanzi: '改' }));
  await assertFails(deleteDoc(doc(alice, 'vocabulary/sample')));
  await assertFails(setDoc(doc(alice, 'users/alice/saved_words/sample'), { vocabId: 'sample' }));
});

test('saved words are idempotent references owned by one UID', async () => {
  const alice = client('alice', 'alice@example.invalid');
  const bob = client('bob', 'bob@example.invalid');
  const guest = environment.unauthenticatedContext().firestore();
  const reference = doc(alice, 'users/alice/saved_words/ocd_test');
  const valid = {
    vocabId: 'ocd_test',
    savedAt: serverTimestamp(),
    masteryLevel: 0,
  };
  await assertSucceeds(setDoc(reference, valid));
  await assertSucceeds(getDoc(reference));
  await assertSucceeds(getDocs(collection(alice, 'users/alice/saved_words')));
  await assertFails(getDoc(doc(bob, 'users/alice/saved_words/ocd_test')));
  await assertFails(getDoc(doc(guest, 'users/alice/saved_words/ocd_test')));
  await assertFails(setDoc(doc(bob, 'users/alice/saved_words/new'), valid));
  await assertFails(setDoc(doc(alice, 'users/alice/saved_words/wrong'), valid));
  await assertFails(setDoc(doc(alice, 'users/alice/saved_words/extra'), {
    ...valid, vocabId: 'extra', role: 'admin',
  }));
  await assertFails(updateDoc(reference, { masteryLevel: 1 }));
  await assertFails(deleteDoc(doc(bob, 'users/alice/saved_words/ocd_test')));
  await assertSucceeds(deleteDoc(reference));
});

test('review schedules are private, typed, and advance one review at a time', async () => {
  const reviewedAt = new Timestamp(1_795_200_000, 0);
  const dueAt = new Timestamp(1_795_286_400, 0);
  const nextDueAt = new Timestamp(1_795_372_800, 0);
  const valid = {
    vocabId: 'ocd_test',
    dueAt,
    intervalDays: 1,
    lastReviewedAt: reviewedAt,
    reviewCount: 1,
    updatedAt: serverTimestamp(),
  };
  const alice = client('alice', 'alice@example.invalid');
  const bob = client('bob', 'bob@example.invalid');
  const guest = environment.unauthenticatedContext().firestore();
  const reference = doc(alice, 'users/alice/review_schedule/ocd_test');

  await assertSucceeds(setDoc(reference, valid));
  await assertSucceeds(getDoc(reference));
  await assertSucceeds(getDocs(collection(alice, 'users/alice/review_schedule')));
  await assertFails(getDoc(doc(bob, 'users/alice/review_schedule/ocd_test')));
  await assertFails(getDoc(doc(guest, 'users/alice/review_schedule/ocd_test')));
  await assertFails(setDoc(doc(alice, 'users/alice/review_schedule/wrong'), valid));
  await assertFails(setDoc(doc(bob, 'users/alice/review_schedule/ocd_test'), valid));
  await assertFails(setDoc(doc(alice, 'users/alice/review_schedule/bad'), {
    ...valid, vocabId: 'bad', intervalDays: 366,
  }));
  await assertFails(setDoc(doc(alice, 'users/alice/review_schedule/count'), {
    ...valid, vocabId: 'count', reviewCount: 2,
  }));
  await assertFails(updateDoc(reference, {
    dueAt: nextDueAt,
    intervalDays: 2,
    lastReviewedAt: reviewedAt,
    reviewCount: 3,
    updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(updateDoc(reference, {
    dueAt: nextDueAt,
    intervalDays: 2,
    lastReviewedAt: reviewedAt,
    reviewCount: 2,
    updatedAt: serverTimestamp(),
  }));
  await assertFails(deleteDoc(reference));
});

test('quiz results are append-only, private, and internally consistent', async () => {
  const valid = {
    score: 1,
    totalQuestions: 2,
    answeredQuestions: 1,
    skippedQuestions: 1,
    createdAt: serverTimestamp(),
    wordIds: ['ocd_test', 'friend_test'],
  };
  const alice = client('alice', 'alice@example.invalid');
  const bob = client('bob', 'bob@example.invalid');
  const guest = environment.unauthenticatedContext().firestore();
  const reference = doc(alice, 'users/alice/quiz_results/result_1');

  await assertSucceeds(setDoc(reference, valid));
  await assertSucceeds(getDoc(reference));
  await assertSucceeds(getDocs(collection(alice, 'users/alice/quiz_results')));
  await assertFails(getDoc(doc(bob, 'users/alice/quiz_results/result_1')));
  await assertFails(getDoc(doc(guest, 'users/alice/quiz_results/result_1')));
  await assertFails(setDoc(doc(bob, 'users/alice/quiz_results/result_2'), valid));
  await assertFails(setDoc(doc(alice, 'users/alice/quiz_results/bad_score'), {
    ...valid, score: 2,
  }));
  await assertFails(setDoc(doc(alice, 'users/alice/quiz_results/bad_skip'), {
    ...valid, skippedQuestions: 0,
  }));
  await assertFails(setDoc(doc(alice, 'users/alice/quiz_results/bad_words'), {
    ...valid, wordIds: ['ocd_test'],
  }));
  await assertFails(updateDoc(reference, { score: 0 }));
  await assertFails(deleteDoc(reference));
});
