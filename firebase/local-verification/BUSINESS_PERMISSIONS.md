# Confirmed verification permissions and reverification

Only active accounts with a trusted `locum` assignment and approved verification
may apply; only active accounts with a trusted `practice_owner` assignment and
approved verification may create jobs. Pending, rejected and unverified users
cannot perform those actions. Unverified Locums may browse available jobs.
Active users may sign in, view their profile and submit verification regardless
of status. Existing jobs, applications and history must be retained. The rules
candidate uses canonical `approved`; legacy `verified` requires controlled
reconciliation and does not grant the new job permissions automatically.

The candidate checks a server-controlled `account_access` record and token
auth_time on all permitted user and administrator operations, and additionally
checks assignment and profile status on restricted creates. The backend now
maintains access records for enrollment, assignment and managed Disable/Enable.
An administrator access record and recovery mechanism must be provisioned by a
separate trusted process; admin claims alone cannot bypass this check. Firebase
Auth disabled state is not directly visible to Firestore rules: external Auth
changes or incomplete synchronization must be detected and blocked through
trusted operations and administrative recovery.

For Locums, full name, NRIC, date of birth, highest education, course and
supporting documents are sensitive. For Practice Owners, clinic name,
registration number, practice type, registered address/state and supporting
documents are sensitive. Email, telephone and gender are treated as ordinary
profile fields; availability, preferences and profile pictures are ordinary.
The Practice Owner personal full name and role are ordinary editable profile
fields: the current practice verification schema does not review that name.

Sensitive changes must be staged in a private revision, validated with its
document, and finalized transactionally. Preserve the old approved fields until
successful finalization, mark status pending at finalization, and retain the
approved snapshot separately until a reviewer approves the replacement. Only
approval should promote new verified fields and restore job permissions;
rejection retains old approved information and supports resubmission. The
backend now stages fields until approval, but approval currently copies every
submitted field, including Locum email, phoneNumber and gender. Newer Locum
ordinary edits while review is pending can therefore be overwritten. Practice
Owner revisions also contain companyEmail and contactNumber, which are currently
separate from the editable owner profile's email and phoneNumber; future mapping
must not overwrite newer edits if those fields are unified. Change the backend to
promote only reviewed sensitive fields, or otherwise preserve newer ordinary
changes, and test concurrent edits before enabling integration. Contact-only
edits must preserve status.

Existing accounts missing access metadata require administrator-controlled
identity and state review and a fresh sign-in after the assigned cutoff. Legacy
`verified` is not automatically converted to `approved`: require audited
evidence-based recovery or a new verification, without bulk promotion.
