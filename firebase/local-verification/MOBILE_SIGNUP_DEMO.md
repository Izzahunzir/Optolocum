# Isolated Chrome signup demonstration

Use synthetic accounts only. The demo switch is restricted to Chrome at
`http://localhost:5174`, demo project `demo-optolocum-account-management`,
Auth emulator port 19099, Firestore emulator port 18080 and local API port 8787.
It is not supported on a physical Android phone. The Node server only accepts
the browser origin above and binds to loopback. Production remains the default.

In PowerShell terminal 1, start the isolated emulators with explicit candidate
rules (do not use `firebase deploy`):

```powershell
cd C:\Users\unzir\Desktop\MobileApp\Optolocum\optolocum\firebase\local-verification
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
firebase.cmd emulators:start --project demo-optolocum-account-management --config firebase.json --only auth,firestore
```

In terminal 2 start the isolated local API. Remove conflicting production
credential and project environment variables first; the launcher refuses them.

```powershell
cd C:\Users\unzir\Desktop\MobileApp\Admin-Optolocum\functions
$env:GCLOUD_PROJECT = 'demo-optolocum-account-management'
$env:GOOGLE_CLOUD_PROJECT = 'demo-optolocum-account-management'
$env:FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:19099'
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:18080'
npm.cmd run emulators:local-api
```

In terminal 3:

```powershell
cd C:\Users\unzir\Desktop\MobileApp\Optolocum\optolocum
flutter run -d chrome --web-hostname localhost --web-port 5174 --dart-define=OPT_ISOLATED_DEMO=true
```

The recovery secret and request ID exist only in browser memory; the password
is never written to preferences or logs. Retrying within the same running app
requires the same email, account type, profile details and password. A reload,
closed tab or browser crash loses the secret and requires administrator recovery;
browser memory is not protected against malicious scripts or extensions. No
durable secure browser storage is claimed. The server deliberately returns an
ambiguous conflict for duplicate email and recovery conflicts. Sign-in occurs
after a short delay for the server's whole-second access cutoff and is checked
with a server-only Firestore read of the trusted assignment under the candidate
rules. If that read cannot confirm the session, signup keeps its retry material
and signs out. Do not use this
HTTP-only local demonstration for real credentials or production data.
