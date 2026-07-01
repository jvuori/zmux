# Release Process

zmux uses **GitHub Releases** backed by a GitHub Actions workflow.  
The **tag is the version** — there is no VERSION file to maintain manually.

## TL;DR — how to ship a release

```bash
git tag 0.2.0 && git push origin 0.2.0
```

That's it. GitHub Actions handles everything else.

---

## Versioning

zmux follows [Semantic Versioning](https://semver.org/) starting at **0.x.y**:

| Part        | When to bump                        |
| ----------- | ----------------------------------- |
| `x` (minor) | New user-visible features           |
| `y` (patch) | Bug fixes, docs, internal refactors |

Releases with versions starting `0.` or containing a hyphen (e.g. `0.3.0-rc1`) are
automatically published as GitHub _pre-releases_.

---

## What happens when you push a tag

The workflow in [`.github/workflows/release.yml`](../.github/workflows/release.yml):

1. **Stamps** the tag's version into `VERSION` — no manual file edit needed.
2. **Builds** a release tarball `zmux-<version>.tar.gz` (tests and docs excluded).
3. **Checksums** the archive with SHA-256.
4. **Publishes** a GitHub Release with automatically generated release notes.

Release notes are built by GitHub from merged PRs since the previous tag and grouped
by label (configured in [`.github/release.yml`](../.github/release.yml)).

The release appears at:

```
https://github.com/jvuori/zmux/releases/tag/<version>
```

---

## PR labels for release notes

Apply one of these labels to each PR so it lands in the right section of the
auto-generated release body:

| Label                     | Section             |
| ------------------------- | ------------------- |
| `breaking`                | ⚠️ Breaking Changes |
| `feature` / `enhancement` | 🚀 New Features     |
| `fix` / `bug`             | 🐛 Bug Fixes        |
| `docs` / `documentation`  | 📚 Documentation    |
| `skip-changelog`          | excluded from notes |
| _(anything else)_         | 🔧 Other Changes    |

If you don't label a PR, it appears in _Other Changes_.

---

## Pre-releases and release candidates

```bash
git tag 0.3.0-rc1 && git push origin 0.3.0-rc1
```

Any tag containing a hyphen or a version starting with `0.` is automatically
marked as a GitHub pre-release, so it won't be picked up as "latest" by
`zmux update` until a stable tag is pushed.

---

## Release assets

| File                           | Description                    |
| ------------------------------ | ------------------------------ |
| `zmux-<version>.tar.gz`        | Self-contained release archive |
| `zmux-<version>.tar.gz.sha256` | SHA-256 checksum               |

### Contents of the tarball

```
zmux-<version>/
├── VERSION          ← stamped from the tag by CI
├── install.sh
├── update.sh
├── uninstall.sh
├── setup-shell.sh
├── reload-config.sh
├── get-zmux.sh
├── tmux/
├── scripts/
├── plugins/
├── zmux-autostart.desktop
└── tmux-shutdown-save.service
```

Tests and documentation are excluded to keep the download small.
