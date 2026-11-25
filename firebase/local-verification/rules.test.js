'use strict';
const { test, before, beforeEach, after } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, setDoc, updateDoc, deleteDoc, getDoc, getDocs, collection, query, where, serverTimestamp } = require('firebase/firestore');
let env;
const db = (uid, claims = {}) => env.authenticatedContext(uid, { auth_time: 200, ...claims }).firestore();
const ref = (database, path) => doc(database, path);
before(async () => {
  assert.equal(process.env.FIRESTORE_EMULATOR_HOST, '127.0.0.1:18080');
  assert.equal(process.env.GCLOUD_PROJECT, 'demo-optolocum-account-management');
  env = await initializeTestEnvironment({ projectId: 'demo-optolocum-account-management', firestore: {
    host: '127.0.0.1', port: 18080, rules: fs.readFileSync('firestore.candidate.rules', 'utf8'),
  } });
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async c => {
    const d = c.firestore();
    for (const [path, data] of Object.entries({
      'locum_profiles/locum': { fullName: 'Synthetic', email: 'locum@example.invalid', verificationStatus: 'unverified', createdAt: 1 },
      'practice_owner_profiles/owner': { fullName: 'Synthetic Owner', email: 'owner@example.invalid', phoneNumber: '0123456789', role: 'Manager', verificationStatus: 'unverified', createdAt: 1 },
      'account_management/locum': { trustedAccountType: 'locum' },
      'account_management/owner': { trustedAccountType: 'practice_owner' },
      'account_access/locum': { state: 'active', validAfter: 100 },
      'account_access/owner': { state: 'active', validAfter: 100 },
      'account_access/admin': { state: 'active', validAfter: 100 },
      'registration_intents/intent': { secretHash: 'synthetic' },
      'verification_upload_drafts/locum/requests/request': { submittedFields: { nric: 'synthetic' } },
      'verification_submissions/locum/revisions/first': { state: 'submitted', verificationStatus: 'pending' },
      'verification_submissions/owner/revisions/first': { state: 'submitted', verificationStatus: 'pending' },
      'verification_reviews/locum/revisions/first': { decision: 'rejected' },
      'job_postings/job': { clinicOwnerId: 'owner', status: 'available' },
      'job_postings/deleted': { clinicOwnerId: 'owner', status: 'deleted', deletedAt: 1 },
      'applications/old_locum': { jobId: 'deleted', locumId: 'locum', clinicOwnerId: 'owner', status: 'pending' },
      'applications/job_locum': { jobId: 'job', locumId: 'locum', clinicOwnerId: 'owner', status: 'pending' },
      'application_applicant_summaries/job_locum': { fullName: 'Synthetic', highestEducation: '', course: '', verificationStatus: 'unverified' },
    })) await setDoc(ref(d, path), data);
  });
});
after(async () => { if (env) await env.cleanup(); });

test('server-created profiles: own reads and edits, no forged status or privileged fields', async () => {
  for (const [uid, collectionName, edit] of [
    ['locum', 'locum_profiles', { phoneNumber: '0123456789' }],
    ['owner', 'practice_owner_profiles', { fullName: 'Updated' }],
  ]) {
    const own = db(uid), other = db('other'), p = `${collectionName}/${uid}`;
    await assertSucceeds(getDoc(ref(own, p)));
    await assertFails(getDoc(ref(other, p)));
    await assertFails(getDoc(ref(env.unauthenticatedContext().firestore(), p)));
    await assertSucceeds(updateDoc(ref(own, p), edit));
    for (const value of ['unverified', 'pending', 'approved', 'verified', 'rejected']) {
      if (value === 'unverified') continue; // unchanged field writes have no effect
      await assertFails(updateDoc(ref(own, p), { verificationStatus: value }));
    }
    await assertFails(updateDoc(ref(own, p), { admin: true }));
    await assertFails(deleteDoc(ref(own, p)));
    await assertFails(setDoc(ref(own, `${collectionName}/new-${uid}`), { verificationStatus: 'unverified' }));
  }
  await assertFails(setDoc(ref(db('new'), 'locum_profiles/new'), { verificationStatus: 'unverified' }));
  await assertFails(setDoc(ref(db('new'), 'practice_owner_profiles/new'), { verificationStatus: 'unverified' }));
  await env.withSecurityRulesDisabled(async c => updateDoc(ref(c.firestore(), 'locum_profiles/locum'), { verificationStatus: 'approved' }));
  await assertSucceeds(updateDoc(ref(db('locum'), 'locum_profiles/locum'), { phoneNumber: '0199999999', verificationStatus: 'approved' }));
  for (const field of ['fullName', 'nric', 'dateOfBirth', 'highestEducation', 'course'])
    await assertFails(updateDoc(ref(db('locum'), 'locum_profiles/locum'), { [field]: 'Changed' }));
  for (const field of ['clinicName', 'registrationNumber', 'practiceType', 'address'])
    await assertFails(updateDoc(ref(db('owner'), 'practice_owner_profiles/owner'), { [field]: 'Changed' }));
  await assertFails(updateDoc(ref(db('locum'), 'locum_profiles/locum'), { verificationStatus: 'unverified' }));
});

test('assignments, private intent and upload staging are server controlled', async () => {
  const admin = db('admin', { admin: true });
  for (const uid of ['locum', 'owner']) {
    const own = db(uid), path = `account_management/${uid}`;
    await assertSucceeds(getDoc(ref(own, path)));
    await assertFails(getDoc(ref(db('other'), path)));
    await assertFails(setDoc(ref(own, path), { trustedAccountType: 'practice_owner', admin: true }));
    await assertFails(updateDoc(ref(own, path), { trustedAccountType: 'other' }));
    await assertFails(deleteDoc(ref(own, path)));
  }
  await assertFails(setDoc(ref(db('new'), 'account_management/new'), { trustedAccountType: 'locum' }));
  await assertFails(updateDoc(ref(admin, 'account_management/locum'), { trustedAccountType: 'practice_owner' }));
  for (const actor of [db('locum'), admin, env.unauthenticatedContext().firestore()]) {
    for (const path of ['registration_intents/intent', 'verification_upload_drafts/locum/requests/request']) {
      await assertFails(getDoc(ref(actor, path)));
      await assertFails(setDoc(ref(actor, path), { secretHash: 'forged' }));
    }
  }
});

test('revision and review history is private and immutable to all clients', async () => {
  const admin = db('admin', { admin: true });
  for (const uid of ['locum', 'owner']) {
    const own = db(uid), path = `verification_submissions/${uid}/revisions/first`;
    await assertSucceeds(getDoc(ref(own, path)));
    await assertSucceeds(getDoc(ref(admin, path)));
    await assertFails(getDoc(ref(db('other'), path)));
    await assertFails(getDoc(ref(env.unauthenticatedContext().firestore(), path)));
    for (const actor of [own, admin]) {
      await assertFails(updateDoc(ref(actor, path), { verificationStatus: 'approved' }));
      await assertFails(deleteDoc(ref(actor, path)));
      await assertFails(setDoc(ref(actor, `verification_reviews/${uid}/revisions/new`), { decision: 'approved' }));
    }
  }
  await assertSucceeds(getDoc(ref(db('locum'), 'verification_reviews/locum/revisions/first')));
  await assertFails(getDoc(ref(db('owner'), 'verification_reviews/locum/revisions/first')));
  await assertSucceeds(getDoc(ref(admin, 'verification_reviews/locum/revisions/first')));
  await assertSucceeds(getDoc(ref(admin, 'locum_profiles/locum')));
  await assertSucceeds(getDoc(ref(admin, 'practice_owner_profiles/owner')));
});

test('job and application access retains history and prevents deleted-job applications', async () => {
  const owner = db('owner'), locum = db('locum'), other = db('other'), admin = db('admin', { admin: true });
  await env.withSecurityRulesDisabled(async c => {
    await deleteDoc(ref(c.firestore(), 'applications/job_locum'));
    await updateDoc(ref(c.firestore(), 'locum_profiles/locum'), { verificationStatus: 'approved' });
    await updateDoc(ref(c.firestore(), 'practice_owner_profiles/owner'), { verificationStatus: 'approved' });
  });
  await assertFails(getDoc(ref(env.unauthenticatedContext().firestore(), 'job_postings/job')));
  await assertSucceeds(setDoc(ref(owner, 'job_postings/new'), { clinicOwnerId: 'owner', status: 'available' }));
  await assertFails(setDoc(ref(other, 'job_postings/forged'), { clinicOwnerId: 'owner', status: 'available' }));
  await assertFails(setDoc(ref(owner, 'job_postings/forged'), { clinicOwnerId: 'owner', status: 'available', deletedAt: 1 }));
  await assertSucceeds(updateDoc(ref(owner, 'job_postings/job'), { title: 'Updated' }));
  await assertFails(updateDoc(ref(other, 'job_postings/job'), { title: 'Forged' }));
  for (const actor of [owner, admin]) {
    await assertFails(updateDoc(ref(actor, 'job_postings/job'), { status: 'deleted' }));
    await assertFails(deleteDoc(ref(actor, 'job_postings/job')));
    await assertFails(updateDoc(ref(actor, 'job_postings/deleted'), { status: 'available' }));
  }
  const application = jobId => ({ jobId, locumId: 'locum', clinicOwnerId: 'owner', status: 'pending', appliedAt: serverTimestamp() });
  await assertSucceeds(setDoc(ref(locum, 'applications/job_locum'), application('job')));
  await assertFails(setDoc(ref(locum, 'applications/deleted_locum'), application('deleted')));
  await assertFails(setDoc(ref(other, 'applications/job_locum'), application('job')));
  await assertSucceeds(getDoc(ref(locum, 'applications/old_locum')));
  await assertSucceeds(getDoc(ref(owner, 'applications/old_locum')));
  await assertFails(getDoc(ref(other, 'applications/old_locum')));
  await assertSucceeds(getDocs(query(collection(locum, 'applications'), where('locumId', '==', 'locum'))));
  await assertSucceeds(updateDoc(ref(owner, 'applications/job_locum'), { status: 'hired' }));
  await assertFails(updateDoc(ref(locum, 'applications/job_locum'), { status: 'completed' }));
  await assertSucceeds(updateDoc(ref(owner, 'applications/job_locum'), { status: 'completed' }));
  await assertFails(deleteDoc(ref(owner, 'applications/job_locum')));
});

test('active-session gates protect reads, edits and historical records for users and administrators', async () => {
  const owner = db('owner'), locum = db('locum'), admin = db('admin', { admin: true });
  await assertSucceeds(getDoc(ref(locum, 'job_postings/job')));
  await assertSucceeds(getDoc(ref(owner, 'application_applicant_summaries/job_locum')));
  await assertSucceeds(getDoc(ref(admin, 'verification_submissions/locum/revisions/first')));
  await assertSucceeds(setDoc(ref(locum, 'application_applicant_summaries/job_locum'), { fullName: 'Synthetic', highestEducation: '', course: '', verificationStatus: 'unverified' }));
  await assertSucceeds(updateDoc(ref(admin, 'job_postings/job'), { title: 'Admin edit' }));
  await assertSucceeds(updateDoc(ref(owner, 'job_postings/job'), { title: 'Active edit' }));
  for (const uid of ['locum', 'owner', 'admin']) {
    await env.withSecurityRulesDisabled(c => updateDoc(ref(c.firestore(), `account_access/${uid}`), { state: 'disabled' }));
  }
  for (const [actor, uid] of [[locum, 'locum'], [owner, 'owner'], [admin, 'admin']]) {
    for (const path of ['job_postings/job', 'applications/job_locum', 'locum_profiles/locum', 'verification_submissions/locum/revisions/first', 'verification_reviews/locum/revisions/first', 'application_applicant_summaries/job_locum', `account_management/${uid}`]) {
      await assertFails(getDoc(ref(actor, path)));
    }
    await assertFails(updateDoc(ref(actor, 'job_postings/job'), { title: 'Blocked' }));
    await assertFails(updateDoc(ref(actor, 'applications/job_locum'), { status: 'hired' }));
  }
  await assertFails(updateDoc(ref(locum, 'locum_profiles/locum'), { phoneNumber: '0100000000' }));
  await assertFails(updateDoc(ref(owner, 'practice_owner_profiles/owner'), { fullName: 'Blocked' }));
  await assertFails(setDoc(ref(locum, 'application_applicant_summaries/job_locum'), { fullName: 'Synthetic', highestEducation: '', course: '' }));
});

test('missing, malformed, in-progress and stale access fail closed across reads and updates', async () => {
  const owner = db('owner');
  const target = 'account_access/owner';
  const cases = [
    null, { state: 'active' }, { state: 'active', validAfter: -1 },
    { state: 'active', validAfter: '100' }, { state: 'active', validAfter: 200 },
    { state: 'active', validAfter: 201 }, { state: 'active', validAfter: 100, operation: 'enable' },
    { state: 'active', validAfter: 100, unexpected: true },
  ];
  for (const value of cases) {
    await env.withSecurityRulesDisabled(async c => {
      const access = ref(c.firestore(), target);
      if (value === null) await deleteDoc(access); else await setDoc(access, value);
    });
    await assertFails(getDoc(ref(owner, 'job_postings/job')));
    await assertFails(getDoc(ref(owner, 'practice_owner_profiles/owner')));
    await assertFails(updateDoc(ref(owner, 'job_postings/job'), { title: 'Denied' }));
    await assertFails(updateDoc(ref(owner, 'applications/job_locum'), { status: 'hired' }));
  }
  await env.withSecurityRulesDisabled(c => setDoc(ref(c.firestore(), target), { state: 'active', validAfter: 200, operation: null }));
  await assertFails(getDoc(ref(owner, 'job_postings/job')));
  const fresh = db('owner', { auth_time: 201 });
  await assertSucceeds(getDoc(ref(fresh, 'job_postings/job')));
  await assertSucceeds(updateDoc(ref(fresh, 'applications/job_locum'), { status: 'hired' }));
});

test('job permissions require approved status, correct trusted type and active session', async () => {
  const owner = db('owner'), locum = db('locum');
  const job = { clinicOwnerId: 'owner', status: 'available' };
  const application = { jobId: 'job', locumId: 'locum', clinicOwnerId: 'owner', status: 'pending', appliedAt: serverTimestamp() };
  await assertSucceeds(getDoc(ref(locum, 'job_postings/job')));
  for (const status of ['unverified', 'pending', 'rejected', 'verified']) {
    await env.withSecurityRulesDisabled(async c => {
      await updateDoc(ref(c.firestore(), 'locum_profiles/locum'), { verificationStatus: status });
      await updateDoc(ref(c.firestore(), 'practice_owner_profiles/owner'), { verificationStatus: status });
    });
    await assertFails(setDoc(ref(owner, 'job_postings/new'), job));
    await assertFails(setDoc(ref(locum, 'applications/job_locum'), { ...application, appliedAt: serverTimestamp() }));
  }
  await env.withSecurityRulesDisabled(async c => {
    await updateDoc(ref(c.firestore(), 'locum_profiles/locum'), { verificationStatus: 'approved' });
    await updateDoc(ref(c.firestore(), 'practice_owner_profiles/owner'), { verificationStatus: 'approved' });
    await updateDoc(ref(c.firestore(), 'account_management/locum'), { trustedAccountType: 'practice_owner' });
    await updateDoc(ref(c.firestore(), 'account_management/owner'), { trustedAccountType: 'locum' });
  });
  await assertFails(setDoc(ref(owner, 'job_postings/new'), job));
  await assertFails(setDoc(ref(locum, 'applications/job_locum'), { ...application, appliedAt: serverTimestamp() }));
  await env.withSecurityRulesDisabled(async c => {
    await updateDoc(ref(c.firestore(), 'account_management/locum'), { trustedAccountType: 'locum' });
    await updateDoc(ref(c.firestore(), 'account_management/owner'), { trustedAccountType: 'practice_owner' });
    await updateDoc(ref(c.firestore(), 'account_access/locum'), { state: 'disabled' });
    await updateDoc(ref(c.firestore(), 'account_access/owner'), { state: 'disabled' });
  });
  await assertFails(setDoc(ref(owner, 'job_postings/new'), job));
  await assertFails(setDoc(ref(locum, 'applications/job_locum'), { ...application, appliedAt: serverTimestamp() }));
});
