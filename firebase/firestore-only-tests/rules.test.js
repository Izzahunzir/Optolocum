"use strict";
const { test, before, beforeEach, after } = require("node:test");
const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const { resolve } = require("node:path");
const { initializeTestEnvironment, assertSucceeds, assertFails } = require("@firebase/rules-unit-testing");
const { doc, collection, getDoc, getDocs, query, where, setDoc, deleteDoc,
  serverTimestamp, runTransaction } = require("firebase/firestore");

let environment;
const summaryPath = "application_applicant_summaries/job_locum";
const summary = { fullName: "Test Locum", highestEducation: "Bachelor's Degree", course: "Optometry" };
const application = { jobId: "job", locumId: "locum", clinicOwnerId: "owner", status: "pending" };
const db = (uid) => uid ? environment.authenticatedContext(uid).firestore()
  : environment.unauthenticatedContext().firestore();
const admin = (callback) => environment.withSecurityRulesDisabled((context) => callback(context.firestore()));

before(async () => {
  environment = await initializeTestEnvironment({
    projectId: "demo-optolocum-firestore-only",
    firestore: {
      host: "127.0.0.1", port: 8185,
      rules: readFileSync(resolve(__dirname, process.env.RULES_FILE || "firestore.rules"), "utf8"),
    },
  });
});
after(async () => { if (environment) await environment.cleanup(); });
beforeEach(async () => {
  await environment.clearFirestore();
  await admin(async (database) => {
    await Promise.all([
      setDoc(doc(database, "job_postings/job"), { clinicOwnerId: "owner", status: "available" }),
      setDoc(doc(database, "applications/job_locum"), application),
      setDoc(doc(database, "locum_profiles/locum"), {
        ...summary, nric: "private", phoneNumber: "private", dateOfBirth: "private",
        verificationStatus: "pending",
      }),
    ]);
  });
});

test("Locum can create a summary matching their own profile", async () => {
  await assertSucceeds(setDoc(doc(db("locum"), summaryPath), summary));
  const result = await assertSucceeds(getDoc(doc(db("owner"), summaryPath)));
  assert.deepEqual(result.data(), summary);
});
test("Locum can refresh their summary after updating their profile", async () => {
  const locum = db("locum");
  await setDoc(doc(locum, summaryPath), summary);
  const updated = { ...summary, course: "Clinical Optometry" };
  await assertSucceeds(setDoc(doc(locum, "locum_profiles/locum"), {
    ...updated, verificationStatus: "pending",
  }));
  await assertSucceeds(setDoc(doc(locum, summaryPath), updated));
  assert.deepEqual((await getDoc(doc(db("owner"), summaryPath))).data(), updated);
});
test("job owner can read a not-yet-created summary", async () => {
  const result = await assertSucceeds(getDoc(doc(db("owner"), summaryPath)));
  assert.equal(result.exists(), false);
});
for (const uid of [null, "other-owner", "other-locum", "locum"]) {
  test(`summary read is denied for ${uid ?? "signed-out user"}`, async () => {
    await admin((database) => setDoc(doc(database, summaryPath), summary));
    await assertFails(getDoc(doc(db(uid), summaryPath)));
  });
}
for (const uid of [null, "owner", "other-locum"]) {
  test(`summary creation is denied for ${uid ?? "signed-out user"}`, async () => {
    await assertFails(setDoc(doc(db(uid), summaryPath), summary));
  });
}
for (const field of ["nric", "phoneNumber", "dateOfBirth", "email", "verificationStatus", "verified"]) {
  test(`Locum cannot insert extra field ${field}`, async () => {
    await assertFails(setDoc(doc(db("locum"), summaryPath), { ...summary, [field]: "private-or-untrusted" }));
  });
}
for (const field of ["fullName", "highestEducation", "course"]) {
  test(`Locum cannot publish ${field} differing from saved profile`, async () => {
    await assertFails(setDoc(doc(db("locum"), summaryPath), { ...summary, [field]: "Invented" }));
  });
}
test("summary requires all three string fields", async () => {
  await assertFails(setDoc(doc(db("locum"), summaryPath), { fullName: "Test Locum" }));
  await assertFails(setDoc(doc(db("locum"), summaryPath), { ...summary, course: 123 }));
});
test("missing profile fields permit neutral empty strings", async () => {
  await admin((database) => setDoc(doc(database, "locum_profiles/locum"), {
    fullName: "Test Locum", verificationStatus: "pending",
  }));
  await assertSucceeds(setDoc(doc(db("locum"), summaryPath), {
    fullName: "Test Locum", highestEducation: "", course: "",
  }));
});
test("a missing private profile denies summary creation", async () => {
  await admin((database) => deleteDoc(doc(database, "locum_profiles/locum")));
  await assertFails(setDoc(doc(db("locum"), summaryPath), summary));
});
test("private profiles remain readable only by their Locum", async () => {
  await assertSucceeds(getDoc(doc(db("locum"), "locum_profiles/locum")));
  await assertFails(getDoc(doc(db("owner"), "locum_profiles/locum")));
  await assertFails(getDoc(doc(db("other-locum"), "locum_profiles/locum")));
  await assertFails(getDocs(collection(db("locum"), "locum_profiles")));
});
test("clients cannot enumerate or delete summaries", async () => {
  await setDoc(doc(db("locum"), summaryPath), summary);
  await assertFails(getDocs(collection(db("owner"), "application_applicant_summaries")));
  await assertFails(deleteDoc(doc(db("locum"), summaryPath)));
  await assertFails(deleteDoc(doc(db("owner"), summaryPath)));
});
test("a summary with an accidental private field cannot be read", async () => {
  await admin((database) => setDoc(doc(database, summaryPath), { ...summary, nric: "private" }));
  await assertFails(getDoc(doc(db("owner"), summaryPath)));
});
test("deleting the application revokes summary read and write access", async () => {
  await admin(async (database) => {
    await setDoc(doc(database, summaryPath), summary);
    await deleteDoc(doc(database, "applications/job_locum"));
  });
  await assertFails(getDoc(doc(db("owner"), summaryPath)));
  await assertFails(setDoc(doc(db("locum"), summaryPath), summary));
});
test("a different actual job owner invalidates the relationship", async () => {
  await admin(async (database) => {
    await setDoc(doc(database, summaryPath), summary);
    await setDoc(doc(database, "job_postings/job"), { clinicOwnerId: "other-owner", status: "available" });
  });
  await assertFails(getDoc(doc(db("owner"), summaryPath)));
  await assertFails(getDoc(doc(db("other-owner"), summaryPath)));
  await assertFails(setDoc(doc(db("locum"), summaryPath), summary));
});
test("missing and malformed job references deny summary access", async () => {
  await admin((database) => setDoc(doc(database, "applications/job_locum"), { ...application, jobId: null }));
  await assertFails(setDoc(doc(db("locum"), summaryPath), summary));
  await assertFails(getDoc(doc(db("owner"), summaryPath)));
  await admin((database) => setDoc(doc(database, "applications/missing_locum"), { ...application, jobId: "missing" }));
  await assertFails(setDoc(doc(db("locum"), "application_applicant_summaries/missing_locum"), summary));
});
test("application ID must match the genuine job and Locum", async () => {
  await admin((database) => setDoc(doc(database, "applications/forged"), application));
  await assertFails(setDoc(doc(db("locum"), "application_applicant_summaries/forged"), summary));
});
test("using only locumId instead of the application ID is denied", async () => {
  await assertFails(getDoc(doc(db("owner"), "application_applicant_summaries/locum")));
  await assertFails(setDoc(doc(db("locum"), "application_applicant_summaries/locum"), summary));
});
test("empty job reference cannot be used to create or read a summary", async () => {
  await admin((database) => setDoc(doc(database, "applications/_locum"), {
    ...application, jobId: "",
  }));
  await assertFails(setDoc(doc(db("locum"), "application_applicant_summaries/_locum"), summary));
  await assertFails(getDoc(doc(db("owner"), "application_applicant_summaries/_locum")));
});
test("existing application rules reject an empty job reference", async () => {
  await assertFails(setDoc(doc(db("locum"), "applications/_locum"), {
    ...application, jobId: "", appliedAt: serverTimestamp(),
  }));
});
test("existing job creation and authenticated reading remain allowed", async () => {
  await assertSucceeds(setDoc(doc(db("owner"), "job_postings/new-job"), {
    clinicOwnerId: "owner", status: "available",
  }));
  await assertSucceeds(getDoc(doc(db("locum"), "job_postings/new-job")));
  await assertFails(getDoc(doc(db(null), "job_postings/new-job")));
});
test("existing application transaction still commits before the summary", async () => {
  await admin((database) => deleteDoc(doc(database, "applications/job_locum")));
  const locum = db("locum");
  await assertSucceeds(runTransaction(locum, async (transaction) => {
    const jobRef = doc(locum, "job_postings/job");
    const applicationRef = doc(locum, "applications/job_locum");
    await transaction.get(jobRef);
    await transaction.get(applicationRef);
    transaction.set(applicationRef, { ...application, appliedAt: serverTimestamp() });
  }));
  await assertSucceeds(setDoc(doc(locum, summaryPath), summary));
  await assertSucceeds(getDoc(doc(db("owner"), summaryPath)));
});
test("existing application lists work for Locum and Clinic Owner", async () => {
  await assertSucceeds(getDocs(query(collection(db("locum"), "applications"), where("locumId", "==", "locum"))));
  await assertSucceeds(getDocs(query(collection(db("owner"), "applications"), where("clinicOwnerId", "==", "owner"))));
  await assertFails(getDocs(collection(db("other-owner"), "applications")));
});
test("existing profile save permits pending, not self-verification", async () => {
  await assertSucceeds(setDoc(doc(db("locum"), "locum_profiles/locum"), { ...summary, verificationStatus: "pending" }));
  await assertFails(setDoc(doc(db("locum"), "locum_profiles/locum"), { ...summary, verificationStatus: "verified" }));
});
