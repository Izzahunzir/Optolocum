"use strict";
const {test}=require('node:test');
const assert=require('node:assert/strict');
const {readFileSync}=require('node:fs');
const path=require('node:path');
const {initializeTestEnvironment,assertSucceeds,assertFails}=require('@firebase/rules-unit-testing');
const {doc,setDoc,updateDoc,deleteDoc,getDoc,getDocs,collection,query,where,serverTimestamp,runTransaction}=require('firebase/firestore');
for(const [label,file] of [['main','firestore.soft-delete.rules'],['admin','../../../../Admin-Optolocum/functions/emulator/access/job-soft-delete.rules']]) {
 test(label+' local soft-delete proposal preserves history and blocks client bypasses',async t=>{
  const env=await initializeTestEnvironment({projectId:'demo-optolocum-firestore-only',firestore:{host:'127.0.0.1',port:8185,rules:readFileSync(path.resolve(__dirname,file),'utf8')}});
  t.after(()=>env.cleanup()); await env.clearFirestore();
  const owner=env.authenticatedContext('owner').firestore(),locum=env.authenticatedContext('locum').firestore(),admin=env.authenticatedContext('administrator',{admin:true}).firestore();
  const application={jobId:'job',locumId:'locum',clinicOwnerId:'owner',status:'pending',appliedAt:serverTimestamp()};
  await assertSucceeds(setDoc(doc(owner,'job_postings/job'),{clinicOwnerId:'owner',status:'available',placeName:'Keep history'}));
  await assertSucceeds(updateDoc(doc(owner,'job_postings/job'),{placeName:'Preserved history'}));
  await assertFails(updateDoc(doc(owner,'job_postings/job'),{status:'deleted',deletedAt:serverTimestamp()}));
  await assertFails(deleteDoc(doc(owner,'job_postings/job')));
  await assertFails(deleteDoc(doc(admin,'job_postings/job')));
  await assertFails(setDoc(doc(owner,'job_postings/forged'),{clinicOwnerId:'owner',status:'available',deletedAt:serverTimestamp()}));
  await assertSucceeds(runTransaction(locum,async tx=>{await tx.get(doc(locum,'job_postings/job'));await tx.get(doc(locum,'applications/job_locum'));tx.set(doc(locum,'applications/job_locum'),application);}));
  await env.withSecurityRulesDisabled(async ctx=>{
    await setDoc(doc(ctx.firestore(),'application_applicant_summaries/job_locum'),{fullName:'History',highestEducation:'Degree',course:'Optometry'});
    await updateDoc(doc(ctx.firestore(),'job_postings/job'),{status:'deleted',deletedAt:serverTimestamp(),updatedAt:serverTimestamp()});
  });
  for(const database of [owner,admin,locum]) {
    await assertFails(updateDoc(doc(database,'job_postings/job'),{status:'available'}));
    await assertFails(updateDoc(doc(database,'job_postings/job'),{placeName:'Tamper'}));
    await assertFails(updateDoc(doc(database,'job_postings/job'),{deletedAt:serverTimestamp()}));
    await assertFails(deleteDoc(doc(database,'job_postings/job')));
  }
  assert.equal((await assertSucceeds(getDoc(doc(locum,'job_postings/job')))).data().placeName,'Preserved history');
  assert.equal((await assertSucceeds(getDocs(query(collection(locum,'job_postings'),where('status','==','available'))))).size,0);
  assert.equal((await assertSucceeds(getDoc(doc(locum,'applications/job_locum')))).data().status,'pending');
  await assertSucceeds(getDoc(doc(owner,'applications/job_locum')));
  await assertSucceeds(getDoc(doc(owner,'application_applicant_summaries/job_locum')));
  const other=env.authenticatedContext('another-locum').firestore();
  await assertFails(setDoc(doc(other,'applications/job_another-locum'),{...application,locumId:'another-locum'}));
  await assertFails(runTransaction(other,async tx=>{await tx.get(doc(other,'job_postings/job'));tx.set(doc(other,'applications/job_another-locum'),{...application,locumId:'another-locum'});}));
 });
}
