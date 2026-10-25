"use strict";

// Explicit allowlist: never spread a private profile into a summary.
function publicFields(profile) {
  const text = (key) => typeof profile[key] === "string" ? profile[key].trim() : "";
  return {
    fullName: text("fullName"),
    highestEducation: text("highestEducation"),
    course: text("course"),
  };
}

function validApplication(id, application) {
  return application && typeof application.locumId === "string" &&
    typeof application.jobId === "string" &&
    typeof application.clinicOwnerId === "string" &&
    application.locumId.length > 0 && application.jobId.length > 0 &&
    !application.locumId.includes("/") && !application.jobId.includes("/") &&
    application.locumId !== application.clinicOwnerId &&
    id === `${application.jobId}_${application.locumId}`;
}

async function syncApplication(db, applicationId) {
  const applicationRef = db.collection("applications").doc(applicationId);
  const summaryRef = db.collection("application_applicant_summaries").doc(applicationId);
  // Read current source documents rather than event payloads. Transactions
  // make duplicate and out-of-order deliveries safe.
  await db.runTransaction(async (transaction) => {
    const application = (await transaction.get(applicationRef)).data();
    if (!validApplication(applicationId, application)) {
      transaction.delete(summaryRef);
      return;
    }
    const profileRef = db.collection("locum_profiles").doc(application.locumId);
    const jobRef = db.collection("job_postings").doc(application.jobId);
    const [profileSnapshot, jobSnapshot] = await transaction.getAll(profileRef, jobRef);
    const profile = profileSnapshot.data();
    const job = jobSnapshot.data();
    if (!profile || !job || job.clinicOwnerId !== application.clinicOwnerId) {
      transaction.delete(summaryRef);
      return;
    }
    // Replace rather than merge so obsolete/private fields cannot persist.
    transaction.set(summaryRef, publicFields(profile));
  });
}

async function syncQuery(db, query) {
  let cursor;
  for (;;) {
    let pageQuery = query.orderBy("__name__").limit(200);
    if (cursor) pageQuery = pageQuery.startAfter(cursor);
    const page = await pageQuery.get();
    if (page.empty) return;
    for (let offset = 0; offset < page.docs.length; offset += 20) {
      await Promise.all(page.docs.slice(offset, offset + 20)
        .map((document) => syncApplication(db, document.id)));
    }
    cursor = page.docs[page.docs.length - 1];
  }
}

module.exports = { publicFields, validApplication, syncApplication, syncQuery };
