#!/usr/bin/env bash
# bump-version.sh — Update MARKETING_VERSION, commit, and tag.
# Usage: ./scripts/bump-version.sh 1.1.0
set -euo pipefail

# ── Validate arguments ──
if [ $# -ne 1 ]; then
  echo "Usage: $0 <version>"
  echo "Example: $0 1.1.0"
  exit 1
fi

VERSION="$1"

# ── Validate semver format ──
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: Invalid version format '$VERSION'. Expected semver (e.g. 1.0.0)"
  exit 1
fi

# ── Validate we're in a git repo ──
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: Not inside a git repository."
  exit 1
fi

# ── Ensure working tree is clean ──
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Error: Working tree is dirty. Commit or stash changes first."
  exit 1
fi

# ── Ensure tag doesn't already exist ──
if git rev-parse "v$VERSION" >/dev/null 2>&1; then
  echo "Error: Tag 'v$VERSION' already exists."
  exit 1
fi

# ── Update MARKETING_VERSION in project.yml ──
PLIST_FILE="project.yml"
if [ ! -f "$PLIST_FILE" ]; then
  echo "Error: $PLIST_FILE not found. Run this from the project root."
  exit 1
fi

sed -i '' "s/MARKETING_VERSION: \".*\"/MARKETING_VERSION: \"$VERSION\"/" "$PLIST_FILE"
echo "✅ Updated MARKETING_VERSION to $VERSION in $PLIST_FILE"

# ── Regenerate Xcode project ──
if command -v xcodegen &>/dev/null; then
  xcodegen generate
  echo "✅ Regenerated Xcode project"
else
  echo "⚠️  xcodegen not found — skipping project generation. Install with: brew install xcodegen"
fi

# ── Commit ──
git add "$PLIST_FILE"
git commit -m "chore: bump version to $VERSION"

# ── Tag ──
git tag "v$VERSION"

echo ""
echo "✅ Done! Version bumped to $VERSION and tagged as v$VERSION"
echo ""
echo "Next steps:"
echo "  git push origin main --tags"
echo ""
echo "This will trigger the GitHub Actions release pipeline."
