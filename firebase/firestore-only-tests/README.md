# Firestore-only rules validation

Validated locally on 26 October 2026 using Firestore Emulator 1.22.0, Java 21,
Node.js 24.22.0, Firebase client SDK 13.1.0, and rules-unit-testing 6.0.0.

## Results

| Full ruleset | Passed | Failed |
| --- | ---: | ---: |
| `firestore.proposed.rules` (previous proposal) | 36 | 0 |
| `firestore.rules` (guarded recommendation) | 36 | 0 |

Both files contain all four collection matches: `job_postings`, `applications`,
`locum_profiles`, and `application_applicant_summaries`. The first three matches
are the rules supplied in the conversation; they are identical in both files.
This test suite does not import the old Cloud Functions rules fragment or use
Cloud Functions, the Admin SDK, production credentials, or a live Firebase project.

The tests verify:

- Locum summary creation and refresh, with exact values from their own profile.
- Clinic Owner reads for a genuine application and matching job owner.
- Denial for signed-out users, unrelated users, forged relationships, and wrong IDs.
- Denial of extra NRIC, phone number, birth date, email and verification fields.
- Denial of profile-mismatching names and qualifications, malformed summaries,
  collection listing and summary deletion.
- Owner-only private profile reads, pending-only profile saves, and denied
  self-verification.
- Existing job creation/reading, application transaction and owner-scoped queries.
- Missing profiles/jobs/applications, malformed or empty references, and missing
  summary documents.

## Findings and recommended fix

The original proposed full ruleset compiles, and authorized operations succeed.
The exact Playground messages `Function not found: exists` and
`Invalid argument provided to get` were not reproduced with this supplied source.
`exists()` is a valid Firestore Rules built-in; the successful application
transaction exercises it in the existing application-create rule.

The original summary helpers dereference `.data` on lookups before confirming
that the document exists. Missing documents produced null-value evaluation
diagnostics during correctly denied requests. These are confirmed findings;
they do not establish the exact cause of a different Playground message.

The guarded `firestore.rules` recommendation changes ONLY the summary helpers:

1. Check lookup results for null before reading `.data`.
2. Validate relationship keys and document ID strings before constructing paths.
3. Look up the current user's private profile only after confirming ownership
   and validating the proposed three-field summary.

All 36 authorization tests pass with both versions. The guarded version removes
the tested null-value diagnostics. Generic evaluation diagnostics can still be
printed for deliberately denied requests; they are not compilation failures.

For Playground, use an existing full application ID, not just a Locum UID:

```text
application_applicant_summaries/{jobId}_{locumUid}
```

Authenticate the read simulation with the exact application/job Clinic Owner UID.
The corresponding `applications/{applicationId}` and `job_postings/{jobId}`
documents must exist and agree on the owner. For create/update, authenticate as
the application's Locum and supply exactly the three strings from their profile.
A summary document need not already exist for an authorized single-document read.
No production test documents were created during this investigation.

If the Playground still reports a function/path error, compare the editor's full
rules source, error line, simulation operation/path/UID, and referenced document
fields with this fixture. A Playground-only root cause cannot be determined from
the two error messages alone.

## Run again locally

Dependencies are isolated in this folder and recorded in `package-lock.json`.
The approved emulator binary is cached in `.emulator-cache/` (ignored by Git).
Its SHA-256 was checked against the installed Firebase CLI's published metadata:

```text
9b6498b7f62714d67f48f59b3818883cd682dbcd46b9f59511de81c97bb5166c
```

In one terminal, from this folder:

```powershell
java -jar .emulator-cache/cloud-firestore-emulator-v1.22.0.jar --host 127.0.0.1 --port 8185 --project_id demo-optolocum-firestore-only --rules firestore.rules
```

In another terminal, also from this folder:

```powershell
node --test --test-reporter=spec rules.test.js
```

To test the unchanged previous proposal instead:

```powershell
$env:RULES_FILE = 'firestore.proposed.rules'
node --test --test-reporter=spec rules.test.js
Remove-Item Env:RULES_FILE
```

Local outputs are `test-results-proposed.log` and `test-results-hardened.log`.
Expected `PERMISSION_DENIED` messages correspond to negative assertions.
`withSecurityRulesDisabled` is used only to seed local test fixtures, never to
authorize the application operations being tested.

## Production status

Nothing has been deployed or published. Billing and production data are unchanged.
The guarded full ruleset is a local recommendation for review, not an automatic
production update. Do not deploy this testing configuration as a routine test step.
