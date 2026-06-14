# Security Runbook — Leaked Signing Keystore & Cert (C-5)

The Android release keystore (`pos-keystore.jks`), its certificate (`pos-cert.pem`),
and a base64 dump (`keystore-base64.txt`) were committed to git. They have been
**untracked** (commit `29e2bec`), but they still exist in **git history**, so they
must be treated as **compromised**.

> ⚠️ These commands rewrite history and force-push. They are destructive and
> outward-facing. Run them yourself, deliberately, after reading each step.
> Claude will not run them.

---

## Step 1 — Rotate the signing key (the actual fix; do this FIRST)

Purging history only removes copies; it does **not** un-leak the key. Rotation is
what makes the leaked key worthless.

- **If the app is NOT yet on Google Play:** generate a brand-new keystore and use
  it going forward.
  ```bash
  keytool -genkey -v -keystore upsenso-release.jks \
    -keyalg RSA -keysize 2048 -validity 10000 -alias upsenso
  ```
  Update `android/key.properties` (keep it git-ignored) and your CI secrets.

- **If the app IS already published with this key:** you cannot simply swap the
  upload/app-signing key. Either:
  - Enroll in **Play App Signing** and request an **upload key reset** with Google
    (they let you register a new upload key), or
  - If Google manages the app-signing key, the leaked *upload* key can be reset
    via the Play Console → "Request upload key reset".
  Document which key leaked (upload vs app-signing) before acting.

## Step 2 — Move signing material out of the repo for good

- Confirm `.gitignore` already ignores `*.jks *.keystore *.pem *.p12 keystore-base64.txt **/key.properties` (done in `29e2bec`).
- Store the new keystore + passwords in your CI secret manager (GitHub Actions
  secrets / EAS secrets / etc.), never in the repo.

## Step 3 — Purge the old material from history

Use `git filter-repo` (preferred over BFG; install: `pip install git-filter-repo`).

```bash
# From a FRESH clone of the repo (filter-repo refuses to run on a dirty/again repo):
git clone https://github.com/DTHarryyy/upsenso.git upsenso-clean
cd upsenso-clean

git filter-repo \
  --invert-paths \
  --path pos-keystore.jks \
  --path pos-cert.pem \
  --path keystore-base64.txt \
  --path-glob 'supabase/.temp/*'

# Review history is clean:
git log --all --oneline -- pos-keystore.jks   # should print nothing
```

## Step 4 — Force-push the rewritten history

```bash
git push origin --force --all
git push origin --force --tags
```

> This breaks every existing clone. Tell collaborators to re-clone (not pull).
> Any open PRs will need to be recreated.

## Step 5 — Post-rotation hygiene

- Invalidate any CI caches that may hold the old keystore.
- If `pos-cert.pem` was a TLS/private cert (not just the keystore cert), reissue it.
- Rotate anything else that ever lived in `supabase/.temp/` if it held tokens.

---

### Quick reference — what was leaked

| File | Risk | Action |
|---|---|---|
| `pos-keystore.jks` | Release signing key | Rotate (Step 1) + purge (Step 3) |
| `pos-cert.pem` | Certificate / public-ish but reissue if private | Purge; reissue if private |
| `keystore-base64.txt` | Full keystore, base64-encoded | Same as `.jks` |
| `supabase/.temp/*` | Project metadata (low) | Purge; rotate tokens if any |
