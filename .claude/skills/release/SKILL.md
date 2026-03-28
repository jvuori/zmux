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

Run these commands to understand what has changed since the last release:

```bash
git tag --sort=-v:refname | head -1          # latest tag (current version)
git log <latest-tag>..HEAD --oneline         # commits since last release
git diff <latest-tag>..HEAD --stat           # files changed
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

Produce a concise summary suitable for showing to the user:

```
Current version : 0.1.5
Proposed version: 0.1.6  (patch)

Changes since 0.1.5:
• <short description of each logical change group>

Bump rationale: <one sentence explaining why patch/minor/major>
```

Group related commits into bullet points — don't list every commit hash.

### Step 5 — Ask for confirmation

Show the summary and ask:

> Shall I create and push tag `0.1.6`? (yes / no, or suggest a different version)

Wait for the user's response before doing anything with git.

### Step 6 — Create and push the tag (only after confirmation)

```bash
git tag <new-version>
git push origin <new-version>
```

After pushing, inform the user that the GitHub Actions release workflow will now build and publish the release automatically.

## Important Rules

- **Never create or push a tag without explicit user confirmation.**
- Do not modify any files (no VERSION file, no CHANGELOG). The workflow stamps the version from the tag.
- If the user suggests a different version number, use theirs — don't override their judgement.
- If there are no commits since the last tag, tell the user and abort.
- If the working tree has uncommitted changes, warn the user before proceeding.
