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
6. Notarize with Apple (if `APPLE_ID` secret is set)
7. Create GitHub Release with the `.zip` attached
8. Update `docs/appcast.xml` for Sparkle auto-updates

### 6. Verify

- [ ] GitHub Release page shows correct version + `.zip` attached
- [ ] `docs/appcast.xml` updated with new version entry
- [ ] Running app → Settings → "Check for Updates…" finds the new version
- [ ] Landing page (`shafiswapnil.github.io/fifawc-scores/`) loads correctly

---

## Version Consistency

| Location | What | Source of truth |
|---|---|---|
| `project.yml` | `MARKETING_VERSION` | ✅ Single source of truth |
| Git tag | `vX.Y.Z` | Must match `MARKETING_VERSION` |
| `CFBundleShortVersionString` | Runtime version | Derived from `MARKETING_VERSION` by Xcode |
| `docs/appcast.xml` | Sparkle feed | Updated by CI on release |
| `CHANGELOG.md` | Human-readable history | Manual — update before each release |

Mismatch between tag and `project.yml` → CI fails immediately.
Mismatch between tag and `MARKETING_VERSION` → false "update available" prompts via Sparkle.

---

## Secrets Required for Code Signing & Notarization

| Secret | Purpose |
|---|---|
| `DEVELOPER_ID_CERTIFICATE` | Base64-encoded `.p12` signing certificate |
| `CERTIFICATE_PASSWORD` | Password for the `.p12` file |
| `APPLE_ID` | Apple ID for notarization |
| `APPLE_TEAM_ID` | Apple Developer Team ID |
| `NOTARIZATION_PASSWORD` | App-specific password for notarization |

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
