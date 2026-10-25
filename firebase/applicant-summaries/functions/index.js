"use strict";

const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { syncApplication, syncQuery } = require("./projection");

initializeApp();
const db = getFirestore();

exports.syncApplicationApplicantSummary = onDocumentWritten(
  { document: "applications/{applicationId}", retry: true },
  (event) => syncApplication(db, event.params.applicationId),
);

exports.syncLocumApplicantSummaries = onDocumentWritten(
  { document: "locum_profiles/{locumId}", retry: true },
  (event) => syncQuery(db,
    db.collection("applications").where("locumId", "==", event.params.locumId)),
);
