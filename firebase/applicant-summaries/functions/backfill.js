"use strict";

// Run once with authorized Application Default Credentials AFTER deploying
// the triggers. Never changes applications, jobs or private profiles.
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { syncQuery } = require("./projection");

const projectId = process.argv[2];
if (!projectId) throw new Error("Usage: node backfill.js <firebase-project-id>");
initializeApp({ projectId });
const db = getFirestore();
syncQuery(db, db.collection("applications"))
  .then(() => console.log("Applicant summaries backfilled."))
  .catch((error) => { console.error(error.message); process.exitCode = 1; });
