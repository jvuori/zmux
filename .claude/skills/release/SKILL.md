---
name: release
description: This skill should be used when the user asks to "release this version", "create a release", "publish a release", "tag a release", "cut a release", "ship this", or wants to bump the version and push a git tag.
version: 1.0.0
---

# Release Skill

Handles semantic versioning, tag creation, and release preparation for zmux. The GitHub Actions workflow publishes automatically when a tag is pushed.

## When This Skill Applies

Activate when the user wants to release the current state of the project — e.g. "release this", "cut a release", "tag and push", "publish a new version".

## How to Execute a Release

### Step 1 — Gather context

First, sync tags from remote so the local tag list is up to date:

```bash
git fetch --tags
```

Then gather context:

```bash
git tag --sort=-v:refname | head -1                          # latest tag (current version)
git log <latest-tag>..HEAD --oneline                         # commits since last release
git diff <latest-tag>..HEAD --stat                           # files changed
git log <latest-tag>..HEAD --format="%an" | sort -u          # unique contributor names
```

### Step 2 — Determine bump level

Analyse the commits and changed files:

| Signal | Bump |
|--------|------|
| Breaking change, incompatible API or config change, major behaviour change | **major** |
| New feature, new config option, new script, new plugin support | **minor** |
| Bug fix, typo, documentation, refactor, small improvement, CI fix | **patch** |

When in doubt, prefer the lower bump. This is a `0.x` project so `minor` covers most new features.

### Step 3 — Calculate new version

Parse the current tag (e.g. `0.1.5`) and increment the appropriate component:
- patch: `0.1.5` → `0.1.6`
- minor: `0.1.5` → `0.2.0`
- major: `0.1.5` → `1.0.0`

### Step 4 — Write a release summary

Produce a concise summary suitable for showing to the user, and also used verbatim as the GitHub release body:

```
Current version : 0.1.5
Proposed version: 0.1.6  (patch)

Changes since 0.1.5:
• <short description of each logical change group>

Bump rationale: <one sentence explaining why patch/minor/major>

Contributors: @name1, @name2
```

Group related commits into bullet points — don't list every commit hash.

For the **GitHub release body** (used in Step 6), format it as Markdown with only the changes — do **not** include a Contributors section. GitHub automatically renders a Contributors block below the release body; adding one manually causes a duplicate.

```markdown
## What's new

- <change 1>
- <change 2>
```

### Step 5 — Ask for confirmation

Show the summary and ask:

> Shall I create and push tag `0.1.6`? (yes / no, or suggest a different version)

Wait for the user's response before doing anything with git.

### Step 6 — Create and push the tag, then pre-create the release (only after confirmation)

Create the tag locally and push it. If the tag already exists on remote, check whether it points to the same commit — if yes, it's safe to proceed (a previous attempt created it); if it points to a different commit, abort and tell the user.

```bash
git tag <new-version>                      # may already exist locally — that's fine
git push origin <new-version> 2>&1        # may be rejected if already on remote
# Check: if rejected, verify remote tag points to HEAD
git ls-remote origin refs/tags/<new-version>   # get remote tag SHA
git rev-list -n1 <new-version>                 # get local tag SHA
# If both SHAs match → proceed. If they differ → abort.
```

Immediately after the tag is confirmed on remote, set the release body. Try `create` first; if the release already exists, use `edit`. Suppress the expected "already exists" error from `create` so it doesn't alarm the user:

```bash
gh release create <new-version> \
  --title "zmux <new-version>" \
  --notes "<markdown release body from Step 4>" \
  --draft=false 2>/dev/null \
|| gh release edit <new-version> \
  --title "zmux <new-version>" \
  --notes "<markdown release body from Step 4>"
```

The GitHub Actions workflow will attach the release assets and, with `append_body: true`, append auto-generated commit notes to the body.

Inform the user the release is live and the workflow is building the tarball.

## Important Rules

- **Never create or push a tag without explicit user confirmation.**
- Do not modify any files (no VERSION file, no CHANGELOG). The workflow stamps the version from the tag.
- If the user suggests a different version number, use theirs — don't override their judgement.
- If there are no commits since the last tag, tell the user and abort.
- If the working tree has uncommitted changes, warn the user before proceeding.
