'use strict';
const { before, beforeEach, after, test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, setDoc, updateDoc, deleteDoc, getDoc, getDocs, collection, serverTimestamp, Timestamp } = require('firebase/firestore');
const { ref, uploadBytes, getBytes, deleteObject, updateMetadata, listAll } = require('firebase/storage');

const projectId = 'demo-optolocum-verification';
const id = 'a'.repeat(40), secondId = 'b'.repeat(40), hash = 'c'.repeat(64);
const bytes = Buffer.from('%PDF-1.7\nsynthetic evidence');
const path = `verification_documents/locum/${id}/document`;
const personal = { fullName: 'Test', email: 'test@example.com', nric: '990101010101', phoneNumber: '0123456789', gender: 'Female', dateOfBirth: '1999-01-01', highestEducation: 'Degree', course: 'Optometry' };
const practice = { practiceType: 'Retail Optical Store', clinicName: 'Vision', registrationNumber: '12345', address: '22 Jalan Test', state: 'Johor', contactNumber: '0123456789', companyEmail: 'store@example.com' };
let env;
const db = (uid, claims = {}) => env.authenticatedContext(uid, claims).firestore();
const storage = (uid, claims = {}) => env.authenticatedContext(uid, claims).storage();
const revision = (database, uid = 'locum', revisionId = id) => doc(database, `verification_submissions/${uid}/revisions/${revisionId}`);
const draft = (uid = 'locum', revisionId = id) => ({
  uid, accountType: uid === 'locum' ? 'locum' : 'practice_owner', schemaVersion: 1,
  fields: uid === 'locum' ? personal : practice, fingerprint: hash,
  state: 'draft', createdAt: serverTimestamp(),
  ...(uid === 'locum' ? { document: { path: `verification_documents/${uid}/${revisionId}/document`, name: 'evidence.pdf', contentType: 'application/pdf', size: bytes.length, sha256: hash } } : {}),
});
const metadata = { contentType: 'application/pdf', customMetadata: { sha256: hash } };
const create = async (uid = 'locum', revisionId = id) => setDoc(revision(db(uid), uid, revisionId), draft(uid, revisionId));
const submit = async (uid = 'locum') => updateDoc(revision(db(uid), uid), { state: 'submitted', submittedAt: serverTimestamp() });

before(async () => {
  // Refuse execution without the exact isolated emulator endpoints.
  assert.equal(process.env.FIRESTORE_EMULATOR_HOST, '127.0.0.1:8188');
  assert.equal(process.env.FIREBASE_STORAGE_EMULATOR_HOST, '127.0.0.1:9298');
  env = await initializeTestEnvironment({ projectId,
    firestore: { host: '127.0.0.1', port: 8188, rules: fs.readFileSync('firestore.rules', 'utf8') },
    storage: { host: '127.0.0.1', port: 9298, rules: fs.readFileSync('storage.rules', 'utf8') },
  });
});
beforeEach(async () => {
  // rules-unit-testing clearStorage only removes root items. Evidence lives in
  // prefixes, so recursively clear this demo emulator's bucket between cases.
  await env.withSecurityRulesDisabled(async context => {
    async function clearFolder(folder) {
      const { items, prefixes } = await folder.listAll();
      await Promise.all(items.map(item => item.delete()));
      await Promise.all(prefixes.map(clearFolder));
    }
    await clearFolder(context.storage().ref());
  });
  await env.clearFirestore();
});
after(async () => { if (env) await env.cleanup(); });

test('Locum draft, private upload and immutable submitted revision', async () => {
  await assertSucceeds(create());
  await assertSucceeds(uploadBytes(ref(storage('locum'), path), bytes, metadata));
  await assertSucceeds(submit());
  const saved = await getDoc(revision(db('locum')));
  assert.equal(saved.data().state, 'submitted');
  await assertFails(updateDoc(revision(db('locum')), { 'fields.fullName': 'Changed' }));
  await assertFails(updateDoc(revision(db('locum')), { submittedAt: serverTimestamp() }));
  await assertFails(deleteDoc(revision(db('locum'))));
});
test('Practice Owner submits details without document; resubmission creates a new revision', async () => {
  await assertSucceeds(create('owner'));
  await assertSucceeds(submit('owner'));
  await assertSucceeds(create('owner', secondId));
  await assertSucceeds(updateDoc(revision(db('owner'), 'owner', secondId), {state:'submitted', submittedAt:serverTimestamp()}));
  assert.equal((await getDocs(collection(db('owner'), 'verification_submissions/owner/revisions'))).size, 2);
});
test('users cannot read/list/write another user submission; anonymous denied', async () => {
  await create();
  await assertFails(getDoc(revision(db('other'))));
  await assertFails(getDocs(collection(db('other'), 'verification_submissions/locum/revisions')));
  await assertFails(setDoc(revision(db('other'), 'locum', secondId), draft('locum', secondId)));
  await assertFails(getDoc(revision(env.unauthenticatedContext().firestore())));
});
test('Admin reads evidence but cannot edit submissions or approve via client SDK', async () => {
  await create();
  await assertSucceeds(getDoc(revision(db('admin', { admin: true }))));
  await assertFails(updateDoc(revision(db('admin', { admin: true })), { state: 'verified' }));
  await assertFails(updateDoc(revision(db('locum')), { state: 'verified' }));
});
for (const field of ['verified', 'verificationStatus', 'reviewedBy', 'reviewedAt', 'decision', 'role', 'admin']) {
  test(`forged ${field} rejected on create and submit`, async () => {
    await assertFails(setDoc(revision(db('locum')), { ...draft(), [field]: field === 'admin' ? true : 'verified' }));
    await create();
    await assertFails(updateDoc(revision(db('locum')), {state:'submitted', submittedAt:serverTimestamp(), [field]:'forged'}));
  });
}
test('draft payload and document cannot be changed during finalization', async () => {
  await create();
  for (const patch of [{'fields.nric':'111111111111'}, {'document.path':'other'}, {accountType:'practice_owner'}, {fingerprint:'d'.repeat(64)}, {createdAt:serverTimestamp()}]) {
    await assertFails(updateDoc(revision(db('locum')), {state:'submitted', submittedAt:serverTimestamp(), ...patch}));
  }
});
test('invalid fields, schema, UID, timestamps, and document metadata rejected', async () => {
  for (const patch of [
    {uid:'other'}, {schemaVersion:2}, {state:'submitted', submittedAt:serverTimestamp()},
    {createdAt:Timestamp.fromMillis(1)}, {fields:{...personal, trustedRole:'admin'}},
    {fields:{...personal, nric:'bad'}}, {fields:{...personal, email:'bad'}},
    {document:{...draft().document, size:0}}, {document:{...draft().document, size:52428801}},
    {document:{...draft().document, path:'public/document'}},
    {document:{...draft().document, contentType:'text/html'}},
    {document:{...draft().document, name:'../../secret.pdf'}},
  ]) await assertFails(setDoc(revision(db('locum')), {...draft(), ...patch}));
  const noDoc = draft(); delete noDoc.document;
  await assertFails(setDoc(revision(db('locum')), noDoc));
  await assertFails(setDoc(revision(db('owner'), 'owner'), {...draft('owner'), document:draft().document}));
});
test('finalization must use server timestamp and correct transition', async () => {
  await create();
  await assertFails(updateDoc(revision(db('locum')), {state:'submitted', submittedAt:Timestamp.fromMillis(1)}));
  await assertFails(updateDoc(revision(db('locum')), {state:'pending'}));
});
test('account_management and nested Admin decisions are never client writable', async () => {
  for (const uid of ['locum', 'owner', 'admin']) {
    const database = db(uid, uid === 'admin' ? {admin:true} : {});
    await assertFails(setDoc(doc(database, `account_management/${uid}`), {verification:{status:'verified'}, role:'admin'}));
    await assertFails(setDoc(doc(database, `account_management/${uid}/reviews/x`), {decision:'verified'}));
  }
});
test('Storage rejects missing draft, another user, anonymous and directory listing', async () => {
  await assertFails(uploadBytes(ref(storage('locum'), path), bytes, metadata));
  await create();
  await assertFails(uploadBytes(ref(storage('other'), path), bytes, metadata));
  await assertFails(uploadBytes(ref(env.unauthenticatedContext().storage(), path), bytes, metadata));
  await assertFails(listAll(ref(storage('locum'), 'verification_documents/locum')));
});
test('Storage enforces size, content type and declared hash metadata', async () => {
  await create();
  await assertFails(uploadBytes(ref(storage('locum'), path), Buffer.from('short'), metadata));
  await assertFails(uploadBytes(ref(storage('locum'), path), bytes, {...metadata, contentType:'text/html'}));
  await assertFails(uploadBytes(ref(storage('locum'), path), bytes, {...metadata, customMetadata:{sha256:'wrong'}}));
  await assertFails(uploadBytes(ref(storage('locum'), path), bytes, {...metadata, customMetadata:{sha256:hash, role:'admin'}}));
});
test('Storage is private, create-only, and cannot be uploaded after submission', async () => {
  await create();
  const own = ref(storage('locum'), path);
  await assertSucceeds(uploadBytes(own, bytes, metadata));
  await assertSucceeds(getBytes(own));
  await assertSucceeds(getBytes(ref(storage('admin', {admin:true}), path)));
  await assertFails(getBytes(ref(storage('other'), path)));
  await assertFails(getBytes(ref(env.unauthenticatedContext().storage(), path)));
  await assertFails(uploadBytes(own, bytes, metadata));
  await assertFails(updateMetadata(own, {customMetadata:{sha256:'forged'}}));
  await assertFails(deleteObject(own));
  await submit();
  await assertFails(uploadBytes(own, bytes, metadata));
  await assertFails(deleteObject(ref(storage('admin', {admin:true}), path)));
});
test('Practice Owners cannot upload evidence', async () => {
  await create('owner');
  await assertFails(uploadBytes(ref(storage('owner'), `verification_documents/owner/${id}/document`), bytes, metadata));
});
test('submitted without upload is untrusted evidence, never an approval', async () => {
  // Firestore rules cannot inspect Storage. Phase 2 review must validate the
  // actual object before approval; this test documents that boundary explicitly.
  await create();
  await assertSucceeds(submit());
  await assertFails(uploadBytes(ref(storage('locum'), path), bytes, metadata));
  assert.equal((await getDoc(revision(db('locum')))).data().verificationStatus, undefined);
});
