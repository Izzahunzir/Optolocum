# Job soft-delete proposal (not deployed)

firestore.soft-delete.rules is a local variant of this folder's firestore.rules.
Only job_postings changes: deny client hard deletion, reserve status=deleted and
deletedAt for server writes, and prevent modifications/restoration after deletion.
Creation, historical reads, ordinary owner updates, applications and profiles
retain their baseline checks. No Firebase configuration points to this proposal.

job_soft_delete.test.js validates this proposal and the sibling admin project's
functions/emulator/access/job-soft-delete.rules. The latter retains its fuller
user-supplied baseline (including admin access and verification fields). Neither
is verified as deployed. Do not deploy either full test fixture blindly; review
the actual deployed rules and merge only the job match after separate approval.

Run inside the Firestore emulator on 127.0.0.1:8185 with demo project
 demo-optolocum-firestore-only, sequentially:
node --test --test-concurrency=1 rules.test.js job_soft_delete.test.js
Use installed test dependencies; this implementation run reused the sibling admin
functions/node_modules via process-only NODE_PATH without downloading packages.
The tests seed synthetic contexts only, preserve applications and summaries,
check historical reads and reject direct/stale applications to deleted jobs.

The application transaction and available-only query already enforce available
status and are unchanged. Details/saved cards watch server-confirmed availability;
errors, missing jobs and cache-only reads are unavailable. Owner history retains
deleted postings and counts only available postings as active. Signup and account
verification implementations have not changed.

Offline validation: 38 Firestore emulator tests passed (36 existing checks plus
two proposal suites), and all six applicant-summary backend tests passed.
Four new Flutter soft-delete tests passed. Full Flutter: 19 passed, 22 failed;
an untouched HEAD snapshot: 15 passed, the exact same 22 failed. Existing failures
include missing Firebase test initialization, outdated UI/session expectations and
the applicant-summary verificationStatus expectation. Analyzer: 34 diagnostics,
the same as untouched HEAD (naming infos and three existing warnings). No new
workflow/test failures were introduced; unrelated verification code is unchanged.
