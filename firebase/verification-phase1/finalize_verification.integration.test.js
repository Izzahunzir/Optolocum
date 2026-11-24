'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createHash, randomUUID } = require('node:crypto');
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, FieldPath } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { finalizeVerification } = require('./finalize_verification');
const { verifyStorageDocument } = require(process.env.VERIFICATION_ADMIN_MODULE);

test('trusted finalization validates the actual object and serializes duplicate requests', { timeout: 60000 }, async t => {
  assert.equal(process.env.GCLOUD_PROJECT, 'demo-optolocum-verification');
  assert.equal(process.env.FIRESTORE_EMULATOR_HOST, '127.0.0.1:8188');
  assert.equal(process.env.FIREBASE_STORAGE_EMULATOR_HOST, '127.0.0.1:9298');
  const app = initializeApp({ projectId: 'demo-optolocum-verification', storageBucket: 'demo-optolocum-verification.appspot.com' }, randomUUID());
  const db = getFirestore(app), bucket = getStorage(app).bucket();
  t.after(async () => { await db.terminate(); await deleteApp(app); });
  const uid = `synthetic-${randomUUID()}`, id = 'a'.repeat(40);
  const data = Buffer.from('%PDF-1.7\nsynthetic evidence');
  const sha256 = createHash('sha256').update(data).digest('hex');
  const fields = { fullName: 'Synthetic Locum', email: 'test@example.invalid', nric: '990101010101', phoneNumber: '0123456789', gender: 'Female', dateOfBirth: '1999-01-01', highestEducation: 'Degree', course: 'Optometry' };
  const sorted = Object.fromEntries(Object.keys(fields).sort().map(key => [key, fields[key]]));
  const fingerprint = createHash('sha256').update(JSON.stringify([uid, 'locum', sorted, sha256, 'evidence.pdf'])).digest('hex');
  const path = `verification_documents/${uid}/${id}/document`;
  const revision = db.collection('verification_submissions').doc(uid).collection('revisions').doc(id);
  await revision.set({ uid, accountType: 'locum', schemaVersion: 1, submittedFields: fields, verificationStatus: 'pending', fingerprint,
    document: { path, name: 'evidence.pdf', contentType: 'application/pdf', size: data.length, sha256 },
    state: 'draft', createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp() });
  const args = { db, bucket, uid, submissionId: id, verifyStorageDocument, FieldValue, FieldPath };
  await assert.rejects(finalizeVerification(args));
  assert.equal((await revision.get()).data().state, 'draft');
  await bucket.file(path).save(data, { metadata: { contentType: 'application/pdf', metadata: { sha256 } } });
  const results = await Promise.all([finalizeVerification(args), finalizeVerification(args)]);
  assert.ok(results.every(result => result.state === 'submitted'));
  const submitted = (await revision.get()).data();
  const profile = (await db.collection('locum_profiles').doc(uid).get()).data();
  assert.equal(submitted.state, 'submitted');
  assert.ok(submitted.submittedAt);
  assert.equal(profile.verificationStatus, 'pending');
  await db.collection('locum_profiles').doc(uid).update({ verificationStatus: 'approved' });
  await finalizeVerification(args);
  assert.equal((await db.collection('locum_profiles').doc(uid).get()).data().verificationStatus, 'approved');
});
