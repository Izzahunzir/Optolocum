# Restricted applicant summaries

The deployed `locum_profiles` rules allow only the Locum to read their private
profile. Keep those rules unchanged. Firestore does not redact individual fields
from readable documents.

The Clinic Owner page now reads
`application_applicant_summaries/{applicationId}`. Each document contains **only**
`fullName`, `highestEducation`, and `course`. The application supplies the Locum UID;
no private profile is fetched by the Clinic Owner app.

## Apply the additional rules

In Firebase Console → Firestore Database → Rules, insert the complete block from
[`firestore.rules.fragment`](firestore.rules.fragment) **inside**
`match /databases/{database}/documents { ... }`, alongside your existing three
collection matches, then Publish. Keep all existing rules exactly as supplied.
This fragment is not a full replacement rules file.

The rules allow only a single-document read by the application's Clinic Owner,
also checking that they still own the corresponding job. Summary listing and
all client writes are denied. Extra fields in a summary cause reads to fail.
Private profiles remain owner-only.

## Publish summaries without changing existing client writes

Two separate trusted Cloud Functions maintain this projection: one reacts to
application changes, and the other to profile changes. They re-read current
documents in transactions, tolerate repeated/out-of-order events, replace the
summary using an explicit three-field allowlist, and delete it if the profile or
application is removed. No application, job, or private profile is modified.
The Admin SDK runs only in the trusted backend, never in the Flutter app.

From this directory, after installing Node.js 22 and authenticating Firebase CLI:

```powershell
npm.cmd --prefix functions install
firebase.cmd deploy --project optolocum-f314e --config firebase.json --only functions:applicant-summaries
```

Cloud Functions requires an eligible billing-enabled Firebase project. Confirm
the functions' region suits your Firestore database before deployment; no region
override is set here. Changes propagate asynchronously, so a new applicant can
briefly display a placeholder.

The deployment config contains only the separate functions codebase; it does
not deploy Firestore rules. Merge the additive rule block in the Console.
`firebase.emulator.json` and `test/emulator.rules` are only for local tests.

Existing applications do not emit creation events when functions are deployed.
After deploying the triggers, run the one-time backfill with authorized Google
Application Default Credentials for this project:

```powershell
node functions/backfill.js optolocum-f314e
```

Firebase CLI login alone does not configure Admin SDK Application Default
Credentials. Configure authorized local ADC (for example through your Google
Cloud tooling) or run the backfill in an authorized Google Cloud environment.
Do not embed service-account credentials in the app or repository.

The backfill reads current applications, jobs, and profiles and writes only the
three-field summaries. It can be rerun safely. If a profile is absent, no summary
is published and the page keeps its neutral placeholder.

## Local verification

```powershell
node --test functions/projection.test.js
firebase.cmd emulators:exec --project demo-optolocum-summary --config firebase.emulator.json --only firestore "node --test functions/rules.test.js"
```

The emulator suite tests summary ownership, private-profile isolation, denied
client writes/listing, revoked relationships, and accidental extra-field denial.
No production rules or data are changed by these tests.
