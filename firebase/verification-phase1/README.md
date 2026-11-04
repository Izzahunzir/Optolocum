# Verification submissions — Phase 1, offline only

No deployment or live Firebase writes are part of this change. The root Firebase
configuration and Admin project are unchanged. These are isolated draft rules,
not a replacement for the existing application rules.

## Activation boundary

Both existing forms default to `DisabledVerificationSubmissions`. There is no
production activation environment variable or build flag. The only Firebase
repository factory requires a `demo-` project, configures Auth, Firestore and
Storage emulators, and rejects nonlocal hosts. The injectable client interface is
for tests and future approved integration; it is not wired to production.

With submission disabled, Locums retain the original profile-only save and
navigation. Exactly one valid document is now required on the document step, but
that document stays local. The message explicitly says it was not uploaded or
submitted. Practice Owners see an unavailable message after validation and do not
write a submission. Neither case announces a successful verification submission.

For an offline harness, initialize a *separate named app* with a
`demo-optolocum-verification` FirebaseOptions project and demo storage bucket. Pass
it to `FirebaseVerificationRepository.emulator`, then inject
`VerificationSubmissionService(repository)` into an existing form. Do not point
the current production profile service at emulators; the Locum form's profile
service must also be injected/mocked, or independently configured on the same
demo app. Phase 1 widget tests mock it. Emulator addresses default to
127.0.0.1:8188 (Firestore), :9198 (Auth), :9298 (Storage); Android's host alias is
10.0.2.2. There is no new page or navigation route.

## Data contract

`verification_submissions/{uid}/revisions/{submissionId}` contains:

| Field | Meaning |
| --- | --- |
| uid | Authenticated submitting UID |
| accountType | `locum` or `practice_owner`: evidence category, **not** a trusted account role |
| schemaVersion | Integer 1 |
| fields | Exact trimmed values from the existing form, with no extra profile fields |
| fingerprint | SHA-256 of canonical input, used to retain an attempt when retrying |
| state | `draft` then `submitted`; never an approval status |
| createdAt | Server timestamp when reserving the revision |
| submittedAt | Server timestamp only when finalizing |
| document | Locum only: private path, filename, MIME type, byte count and SHA-256 |

Locum field keys: fullName, email, nric, phoneNumber, gender, dateOfBirth,
highestEducation, course. Practice keys: practiceType, clinicName,
registrationNumber, address, state, contactNumber, companyEmail.

The Locum object lives at
`verification_documents/{uid}/{submissionId}/document`. No local paths, document
bytes, public URLs, approval fields, trusted roles, or reviewer identities are
written to Firestore. Practice Owner submissions have no document.

## Persistence and failure behavior

The service reserves a server-confirmed draft, uploads and confirms object
metadata, performs the existing Locum profile save, then finalizes in a Firestore
transaction. Practice Owners skip upload and profile mutation. Success is shown
only after completion. The legacy Locum profile `pending` value is preserved;
it is not evidence that Admin reviewed anything and may remain pending after a
later finalization failure.

The same form attempt keeps its revision ID on retry. An existing identical
draft/submitted revision is accepted without replacing it. Existing objects are
checked and reused, not overwritten. An uncertain final commit can be retried
without changing its timestamp. Changed inputs create another revision. Opening
the form again also creates a new revision, including resubmission after a future
Request Changes decision. Earlier submitted revisions remain immutable.

On process termination, a draft/object may remain. No local sensitive document
cache or background upload is introduced. Reopening and submitting creates a new
safe revision; automatic cross-restart draft recovery is not provided. A future
recovery caller can reselect the document and construct the same model with the
persisted revision ID; complete payload comparison prevents mismatched reuse.
Abandoned drafts require a separately approved server cleanup/retention policy.
The app never deletes submissions or objects as part of retry handling.

## Security boundaries

- Firestore allows owner-scoped reads and draft creation, with strict key/type
  allowlists. The only client update adds submittedAt and changes draft to
  submitted. Submitted revisions and their payloads cannot be changed/deleted.
- The accountType field grants no privileges. Account-role provisioning is out
  of scope. No submitted data should be used to grant a role.
- Admin-claim readers can inspect evidence. Neither applicant nor Admin Flutter
  clients can write account_management or review decisions. That future document
  must contain only a user-readable management summary; internal reviewer notes
  belong in a separate server-controlled, access-restricted document.
- Storage allows owner creates only while the corresponding Locum draft exists.
  It checks the exact path, declared MIME/size/hash, positive size <= 50 MiB, and
  rejects overwrites, metadata updates, deletion, listing and other users. Owners
  and Admin-claim reviewers can read private objects via authenticated SDK reads.
- The app checks PDF/PNG/JPEG signatures as well as extension and size. This is a
  basic format check, not a full parser, malware scanner or identity check.
- Storage rules validate declared metadata, not actual byte signatures/hashes.
  Firestore rules **cannot inspect Storage existence**. A malicious applicant
  can finalize a revision without an object; it is only untrusted evidence.
  Phase 2's trusted approval endpoint must retrieve the actual immutable object,
  validate size/type/hash/content and bind the decision to that revision before
  writing any trusted verification result. Missing or invalid evidence must
  never become approved. A trusted submission-finalizer can be added if the
  pending-review queue itself must exclude fabricated references.
- Practice approval means review of self-reported store details. No independent
  business/registry verification or document requirement is claimed.

Do not activate historical account_access candidate rules. This phase does not
change Disable/Enable, token revocation, Admin claims, jobs, or application rules.

## Offline checks

Install test dependencies with `npm.cmd ci` in this directory. With a supported
JDK on PATH, run:

```powershell
firebase.cmd emulators:exec --only firestore,storage --project demo-optolocum-verification --config firebase.json "node --test rules.test.js"
```

Tests refuse endpoints other than the isolated ports above. They use synthetic
data and recursively clear only the demo emulator bucket between cases. To use
the offline Flutter repository harness, start Auth as well with
`--only auth,firestore,storage`. No test uses the real project ID or credentials.

Flutter model/service/form tests use injected in-memory repositories and mocked
profile services. Run these from the app root:

```powershell
flutter test test/verification_submission_test.dart test/verification_submission_forms_test.dart test/verification_form_test.dart test/locum_profile_store_test.dart
flutter analyze
```

Validation on 2026-11-05: 35 focused Flutter tests passed (verification models,
services, forms, profile persistence, owner job history, Locum search and
soft-delete regression coverage); 20 Firestore/Storage emulator rule tests
passed. Repository-wide analysis reported the same 34 pre-existing lint findings
and no errors. No deployed rules or real Firebase records were used by tests.

## Required before any safe live testing — separate approval required

1. Review this schema, privacy/retention policy, abandoned draft handling, and
   the untrusted-evidence boundary. Implement trusted evidence validation before
   enabling any future Admin Verify action.
2. Confirm the currently deployed Firestore and Storage rules. Merge only the
   new matches into that exact baseline, resolving any broad overlapping grants.
   Preserve all existing account, application and job soft-delete protections.
   Re-run combined regression tests, including the existing Admin backend tests.
3. Confirm Firebase Storage billing (Blaze is required), choose/confirm the private
   bucket and region, and explicitly configure its storageBucket in the app's
   FirebaseOptions. A project declaration alone does not provision a bucket.
   Do not run flutterfire configure or change the root Firebase configuration
   until separately approved.
4. Enable the Storage-to-Firestore rules access permissions required by
   firestore.get, and deploy the reviewed Storage and merged Firestore rules
   only after approval. Keep public bucket IAM and document download URLs off.
   Check required browser CORS for future authenticated document viewing.
5. Reconcile Locum legacy profile rule constraints with the existing profile-only
   save. Do not treat legacy profile verificationStatus as trusted approval or
   allow new client-editable approval fields. Keep account_management server-only.
6. Add an explicitly approved production repository/wiring. Phase 1 intentionally
   has none. First validate on a nonproduction Firebase project with isolated
   test identities, then obtain approval for a limited live test. Verify owner
   isolation, private retrieval, real device uploads, failed upload/retry,
   immutable revisions, and resubmission. Record cleanup/retention decisions.

Firebase references: [Flutter uploads](https://firebase.google.com/docs/storage/flutter/upload-files),
[Storage rule conditions](https://firebase.google.com/docs/storage/security/rules-conditions),
[Storage billing changes](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024).
