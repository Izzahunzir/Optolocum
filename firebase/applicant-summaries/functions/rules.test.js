"use strict";
const { test, before, after, beforeEach } = require("node:test");
const { readFileSync } = require("node:fs");
const { resolve } = require("node:path");
const { initializeTestEnvironment, assertSucceeds, assertFails } = require("@firebase/rules-unit-testing");
const { doc, getDoc, setDoc, deleteDoc, collection, getDocs } = require("firebase/firestore");
let environment;
const summaryPath = "application_applicant_summaries/job_locum";
const fields = { fullName: "Locum", highestEducation: "Degree", course: "Optometry" };
const database = (uid) => uid
  ? environment.authenticatedContext(uid).firestore()
  : environment.unauthenticatedContext().firestore();

before(async () => {
  const fragment = readFileSync(resolve(__dirname, "../firestore.rules.fragment"), "utf8");
  environment = await initializeTestEnvironment({
    projectId: "demo-optolocum-summary",
    firestore: { host: "127.0.0.1", port: 8185, rules: `rules_version = '2';
      service cloud.firestore { match /databases/{database}/documents {
        ${fragment}
        match /locum_profiles/{locumId} {
          allow get: if request.auth != null && request.auth.uid == locumId;
          allow list: if false;
          allow create, update: if request.auth != null && request.auth.uid == locumId
            && request.resource.data.verificationStatus == 'pending';
          allow delete: if false;
        }
      } }` },
  });
});
after(async () => { if (environment) await environment.cleanup(); });
beforeEach(async () => {
  await environment.clearFirestore();
  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await Promise.all([
      setDoc(doc(db, "applications/job_locum"), { jobId: "job", locumId: "locum", clinicOwnerId: "owner" }),
      setDoc(doc(db, "job_postings/job"), { clinicOwnerId: "owner" }),
      setDoc(doc(db, "locum_profiles/locum"), { ...fields, nric: "private", verificationStatus: "pending" }),
      setDoc(doc(db, summaryPath), fields),
    ]);
  });
});

test("application's job owner can read the minimal summary", async () => {
  await assertSucceeds(getDoc(doc(database("owner"), summaryPath)));
});
test("owner can listen before the backend has published a summary", async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await deleteDoc(doc(context.firestore(), summaryPath));
  });
  await assertSucceeds(getDoc(doc(database("owner"), summaryPath)));
});
for (const uid of [null, "unrelated-owner", "locum"]) {
  test(`summary read denied for ${uid ?? "signed-out user"}`, async () => {
    await assertFails(getDoc(doc(database(uid), summaryPath)));
  });
}
test("clinic owner still cannot read the private profile", async () => {
  await assertFails(getDoc(doc(database("owner"), "locum_profiles/locum")));
  await assertSucceeds(getDoc(doc(database("locum"), "locum_profiles/locum")));
});
test("clients cannot enumerate summaries or publish their own", async () => {
  await assertFails(getDocs(collection(database("owner"), "application_applicant_summaries")));
  await assertFails(setDoc(doc(database("owner"), summaryPath), fields));
  await assertFails(setDoc(doc(database("locum"), summaryPath), fields));
});
test("a forged application relationship fails the job-owner check", async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "job_postings/job"), { clinicOwnerId: "different-owner" });
  });
  await assertFails(getDoc(doc(database("owner"), summaryPath)));
});
test("deleted applications revoke access to an existing summary", async () => {
  await environment.clearFirestore();
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), summaryPath), fields);
  });
  await assertFails(getDoc(doc(database("owner"), summaryPath)));
});
test("a summary with an accidental private field cannot be read", async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), summaryPath), { ...fields, nric: "private" });
  });
  await assertFails(getDoc(doc(database("owner"), summaryPath)));
});
