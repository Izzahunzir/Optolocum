# Local verification rules candidate — do not deploy

The active Firestore release was retrieved read-only from project
`optolocum-f314e` on 2026-11-25; its release update time is
2026-11-04T13:56:26.855713Z and source SHA-256 is
`58e0fdf707c307edf53924393713770c38dc34f5af301c9ec6d9af156f9fc00b`.
This is a review candidate informed by that release, not an automatically
generated copy or approval to deploy. Recheck the release before any future use.

The local Node enrollment code creates profiles and assignments with the Admin
SDK. Client profile creation, assignment writes, intent and upload staging
access, and revision/review writes are denied. Owners may read their own profile
and verification history; admins may read them, but neither can write decisions
through Firestore clients. Admin SDKs bypass these rules, so server identity,
application authorization and IAM are separate security boundaries. Private
registration intents and upload drafts remain inaccessible even to admin clients.

Job and application rules retain the retrieved release's soft-delete and status
transition protections. Restricted creates additionally require trusted type,
approved status and an active session record; see `BUSINESS_PERMISSIONS.md`.
All allowed client reads and writes require a valid active-session record,
including administrators. Missing, malformed and transition records fail closed.
Profile creation and updates are denied to all clients; trusted servers use the
Admin SDK to maintain profiles and verification status.

Real-backend enrollment and verification require trusted server routes; the
candidate does not authorize legacy direct client profile writes. The mobile
summary maps canonical `approved` to the existing `verified` display value.
Review legacy accounts and app behavior before activation.

Real-backend startup uses a UID-bound account-type hint to choose the validation
request and destination. The hint is not authorization: startup waits for the
Firebase session and trusted HTTPS validation before showing an account home.
Missing hints or validation failures return to sign-in; logout and account
switching clear the previous account's hint.

`firebase.json` explicitly supplies this rules file to the loopback-only demo
Auth/Firestore emulators. `rules.test.js` uses the existing SDK dependencies in
`firebase/verification-phase1/node_modules`. Tests use synthetic data. For the
Windows environment, set Android Studio's `jbr` as `JAVA_HOME`, set `NODE_PATH`
to that node_modules directory and run `firebase.cmd emulators:exec --project
demo-optolocum-account-management --config firebase.json --only auth,firestore
"node --test rules.test.js"` from this directory. Do not deploy this config.
