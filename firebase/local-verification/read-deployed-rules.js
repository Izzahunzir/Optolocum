'use strict';
// Read only the Firestore rules release and source; never print credentials.
const path = require('node:path');
const crypto = require('node:crypto');
async function main() {
  const auth = require(path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib/auth'));
  const account = auth.getGlobalDefaultAccount();
  if (!account?.tokens?.refresh_token) throw new Error('Firebase CLI login is unavailable.');
  const token = await auth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  const get = async url => {
    const response = await fetch(url, { headers: { Authorization: `Bearer ${token.access_token}` }, signal: AbortSignal.timeout(30000) });
    if (!response.ok) throw new Error(`Firebase Rules API returned HTTP ${response.status}.`);
    return response.json();
  };
  const project = 'optolocum-f314e';
  const release = await get(`https://firebaserules.googleapis.com/v1/projects/${project}/releases/cloud.firestore`);
  if (!release.rulesetName?.startsWith(`projects/${project}/rulesets/`)) throw new Error('Unexpected ruleset project.');
  const ruleset = await get(`https://firebaserules.googleapis.com/v1/${release.rulesetName}`);
  const files = ruleset.source?.files || [];
  console.log(JSON.stringify({ releaseUpdatedAt: release.updateTime, files: files.map(file => ({ name: file.name, sha256: crypto.createHash('sha256').update(file.content || '').digest('hex') })) }));
  for (const file of files) console.log(file.content || '');
}
main().catch(error => { console.error(error.message?.startsWith('Firebase ') || error.message === 'Unexpected ruleset project.' ? error.message : 'Read-only rules retrieval failed; details suppressed.'); process.exitCode = 1; });
