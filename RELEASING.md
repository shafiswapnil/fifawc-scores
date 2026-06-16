# Releasing — FIFAWC Scores

This document describes the release process. All releases follow semver
(`MAJOR.MINOR.PATCH`) and are triggered by a git tag.

---

## Quick Reference

```bash
# Bump version, commit, and tag
./scripts/bump-version.sh 1.1.0

# Push with tags (triggers CI → build → sign → notarize → GitHub Release)
git push origin main --tags
```

That's it. The `release.yml` workflow handles the rest.

---

## Full Release Checklist

### 1. Pre-release checks

- [ ] All CI checks green on `main` (`ci.yml` passes)
- [ ] Unit tests passing locally
- [ ] Manual smoke test — app launches, menu bar works, settings save
- [ ] Docs updated: `README.md`, `docs/status.md`, `CHANGELOG.md`
- [ ] `CLAUDE.md` "Current status" line reflects new version

### 2. Update CHANGELOG.md

Add a new `## [X.Y.Z]` section at the top of `CHANGELOG.md` with:

- **Added** — new features
- **Changed** — changes to existing functionality
- **Fixed** — bug fixes
- **Removed** — removed features
- Link format: `https://github.com/shafiswapnil/fifawc-scores/compare/vOLD...vNEW`

### 3. Bump version

```bash
./scripts/bump-version.sh X.Y.Z
```

This will:

1. Validate semver format
2. Ensure working tree is clean
3. Ensure tag doesn't already exist
4. Update `MARKETING_VERSION` in `project.yml`
5. Regenerate Xcode project (if xcodegen is installed)
6. Commit with message `chore: bump version to X.Y.Z`
7. Create git tag `vX.Y.Z`

### 4. Push

```bash
git push origin main --tags
```

### 5. Monitor CI

Go to [GitHub Actions](https://github.com/shafiswapnil/fifawc-scores/actions)
and watch the **Release** workflow. It will:

1. Validate tag matches `project.yml` version
2. Install XcodeGen + generate project
3. Build in Release configuration
4. Create `.zip` archive
5. Code sign (if `DEVELOPER_ID_CERTIFICATE` secret is set)
6. **EdDSA sign the zip** (if `SPARKLE_PRIVATE_KEY` secret is set — **required for Sparkle**)
7. Notarize with Apple (if `APPLE_ID` secret is set)
8. Create GitHub Release with the `.zip` attached
9. Update `docs/appcast.xml` with EdDSA signature for Sparkle auto-updates

### Required GitHub Secrets for Sparkle

EdDSA signing requires a one-time key setup and a GitHub repository secret.

#### One-time: Generate the EdDSA key pair (already done)

```bash
# 1. Download Sparkle signing tools (not installed permanently — just binaries)
curl -sL "https://github.com/sparkle-project/Sparkle/releases/download/2.6.4/Sparkle-2.6.4.tar.xz" -o /tmp/sparkle.tar.xz
cd /tmp && tar -xf sparkle.tar.xz ./bin/generate_keys
chmod +x /tmp/bin/generate_keys

# 2. Generate keys — stores private key in macOS Keychain, prints public key
/tmp/bin/generate_keys

# 3. Export private key from Keychain to a file
/tmp/bin/generate_keys -x /tmp/sparkle_private.pem
cat /tmp/sparkle_private.pem    # <-- copy this to GitHub secret
rm /tmp/sparkle_private.pem     # <-- delete after copying
rm /tmp/sparkle.tar.xz          # <-- clean up archive
```

The public key goes into `Info.plist` as `SUPublicEDKey`
(added automatically — value: `TfXIpCz44Ye0qq/LNlJmlarixEHLbZjb4VELsd8R85A=`).

#### One-time: Add private key as GitHub repository secret

1. Go to your repo on GitHub
2. Click **Settings** (top tab bar)
3. In the left sidebar, under **Security**, click **Secrets and variables**
4. Click **Actions**
5. Click the **Secrets** tab (should already be selected)
6. Click **New repository secret**
7. **Name** field: `SPARKLE_PRIVATE_KEY`
8. **Secret** field: paste the private key contents (from step 3 above)
9. Click **Add secret**

> **Note:** Do NOT use the **Environments** section for this. Use the
> **Repository secrets** section on the same page. Environments are
> for deployment protection rules — not what we need here.
>
> Reference: [GitHub Docs — Using secrets in GitHub Actions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions#creating-secrets-for-a-repository)

### 6. Verify

- [ ] GitHub Release page shows correct version + `.zip` attached
- [ ] `docs/appcast.xml` updated with new version entry
- [ ] Running app → Settings → "Check for Updates…" finds the new version
- [ ] Landing page (`shafiswapnil.github.io/fifawc-scores/`) loads correctly

---

## Version Consistency

| Location                     | What                   | Source of truth                           |
| ---------------------------- | ---------------------- | ----------------------------------------- |
| `project.yml`                | `MARKETING_VERSION`    | ✅ Single source of truth                 |
| Git tag                      | `vX.Y.Z`               | Must match `MARKETING_VERSION`            |
| `CFBundleShortVersionString` | Runtime version        | Derived from `MARKETING_VERSION` by Xcode |
| `docs/appcast.xml`           | Sparkle feed           | Updated by CI on release                  |
| `CHANGELOG.md`               | Human-readable history | Manual — update before each release       |

Mismatch between tag and `project.yml` → CI fails immediately.
Mismatch between tag and `MARKETING_VERSION` → false "update available" prompts via Sparkle.

---

## Secrets Required for Code Signing & Notarization

| Secret                     | Purpose                                   |
| -------------------------- | ----------------------------------------- |
| `DEVELOPER_ID_CERTIFICATE` | Base64-encoded `.p12` signing certificate |
| `CERTIFICATE_PASSWORD`     | Password for the `.p12` file              |
| `APPLE_ID`                 | Apple ID for notarization                 |
| `APPLE_TEAM_ID`            | Apple Developer Team ID                   |
| `NOTARIZATION_PASSWORD`    | App-specific password for notarization    |

If these secrets are not set, the release workflow still runs — it just
skips signing and notarization. The `.zip` will contain an unsigned build.

---

## Hotfix Releases

For critical bugs between planned releases:

1. Create a branch from the tag: `git checkout -b hotfix/v1.0.1 v1.0.0`
2. Fix the bug, commit
3. Bump: `./scripts/bump-version.sh 1.0.1`
4. Merge back: `git checkout main && git merge hotfix/v1.0.1`
5. Push: `git push origin main --tags`
