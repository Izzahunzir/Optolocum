"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const { publicFields, syncApplication } = require("./projection");

function fakeDatabase(documents) {
  const writes = [];
  const snapshot = (reference) => ({ data: () => documents[reference] });
  return {
    writes,
    collection: (collection) => ({ doc: (id) => `${collection}/${id}` }),
    runTransaction: (callback) => callback({
      get: async (reference) => snapshot(reference),
      getAll: async (...references) => references.map(snapshot),
      set: (reference, data) => writes.push({ reference, data }),
      delete: (reference) => writes.push({ reference, deleted: true }),
    }),
  };
}

test("private fields cannot enter the summary", () => {
  assert.deepEqual(publicFields({ fullName: " Locum ", highestEducation: "Degree",
    course: "Optometry", nric: "secret", phoneNumber: "secret", dateOfBirth: "secret" }),
  { fullName: "Locum", highestEducation: "Degree", course: "Optometry" });
  assert.deepEqual(publicFields({ fullName: 123 }),
    { fullName: "", highestEducation: "", course: "" });
});

test("projection uses current source data and replaces the summary", async () => {
  const db = fakeDatabase({
    "applications/job_locum": { jobId: "job", locumId: "locum", clinicOwnerId: "owner" },
    "job_postings/job": { clinicOwnerId: "owner" },
    "locum_profiles/locum": { fullName: "Current Name", nric: "secret" },
  });
  await syncApplication(db, "job_locum");
  assert.deepEqual(db.writes, [{ reference: "application_applicant_summaries/job_locum",
    data: { fullName: "Current Name", highestEducation: "", course: "" } }]);
});

for (const [name, sources] of Object.entries({
  "deleted application": {},
  "missing profile": {
    "applications/job_locum": { jobId: "job", locumId: "locum", clinicOwnerId: "owner" },
    "job_postings/job": { clinicOwnerId: "owner" },
  },
  "mismatched job owner": {
    "applications/job_locum": { jobId: "job", locumId: "locum", clinicOwnerId: "owner" },
    "job_postings/job": { clinicOwnerId: "someone-else" },
    "locum_profiles/locum": { fullName: "Name" },
  },
  "invalid application ID": {
    "applications/job_locum": { jobId: "other-job", locumId: "locum", clinicOwnerId: "owner" },
  },
})) {
  test(`${name} removes the summary`, async () => {
    const db = fakeDatabase(sources);
    await syncApplication(db, "job_locum");
    assert.deepEqual(db.writes, [{
      reference: "application_applicant_summaries/job_locum", deleted: true,
    }]);
  });
}
