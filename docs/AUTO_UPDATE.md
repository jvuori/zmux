# Auto-Update Notification

zmux includes an elegant self-update system that checks for new releases automatically and notifies you when one is available.

## How It Works

### Automatic Background Check

zmux checks for new releases **once per 24 hours** at these events:

- **On tmux startup** — When you run `tmux` or `zmux`
- **When attaching to an existing session** — `tmux attach`
- **After running `./update.sh`** — Ensures the notification reflects any version changes
- **When manually reloading config** — `Ctrl+a r` also re-evaluates available updates

The check is **completely silent**:

- No network errors are shown if the check fails
- No messages appear on screen
- The check happens in the background (`run-shell -b`)
- Rate-limited by checking the timestamp in `~/.config/tmux/.update-check-ts`

### Version Detection

zmux automatically detects your install type:

| Install Type        | `zmux-version` file                  | Behavior                                                          |
| ------------------- | ------------------------------------ | ----------------------------------------------------------------- |
| **Release tarball** | Contains version tag (e.g., `0.1.5`) | Compares against latest GitHub release; shows hint only if behind |
| **Git work tree**   | Absent / deleted                     | Always shows update hint for available packaged releases          |

When you run `install.sh` or `update.sh`:

- If installing from a **release tarball** (has `VERSION` file), the version is recorded
- If installing from a **git work tree** (no `VERSION` file), any stale `zmux-version` is removed

This means a git clone install always advertises packaged releases to encourage users to upgrade to the stable release channel.

## Status Bar Notification

When a new release is available, the status bar shows:

```
🔔 Ctrl+u: update (v0.2.0)
```

- Appears **only in root mode** (no mode selected)
- Shows **only when an update is available**
- Includes the emoji (🔔) to catch your eye without being alarming
- Uses the same orange color (`colour208`) as the help hint

If you're already on the latest release, the hint doesn't appear.

## Manual Update

Press **`Ctrl+u`** at any time to manually update zmux:

1. Opens a full-screen popup showing real-time update progress
2. Runs `zmux update` which:
   - Downloads the latest release from GitHub
   - Installs it to `~/.config/tmux/`
   - Reloads the configuration
   - Updates `~/.local/bin/zmux` CLI

3. Press any key to close the popup when done
4. The status bar notification is automatically cleared

## Implementation Details

### Scripts

- **`scripts/check-update.sh`** — Fetches latest release tag from GitHub API; sets/clears `@update_available` tmux option
- **`scripts/run-update.sh`** — Wrapper for running `zmux update` in a popup; ensures `zmux` CLI is in PATH

### Triggered From

1. **Keybindings** — `Ctrl+u` binding in `tmux/keybindings.conf`
2. **Hooks** — `client-attached` hook calls `check-update.sh` in background
3. **Config reload** — `Ctrl+a r` binding also refreshes the notification state
4. **update.sh** — Calls `check-update.sh` after updating version file

### API

- Fetches from `https://api.github.com/repos/jvuori/zmux/releases`
- Uses curl or wget with 15-second timeout
- Parses `tag_name` field from first release entry (pre-releases are included)
- Comparison uses simple semantic versioning sort

## Rate Limiting

The check is rate-limited in two ways:

1. **Time-based** — One API call per 24 hours (checks `~/.config/tmux/.update-check-ts`)
2. **Event-based** — Only checks on the specific events listed above

For dev installs (git work tree):

- The rate limit applies to the API call
- But the notification check (without API call) can run every time `check-update.sh` is called
- This avoids the "notification flickering" on repeated tmux starts

## Disabling Notifications

To disable update notifications:

1. Edit `~/.config/tmux/keybindings.conf`
2. Comment out or remove the `client-attached` hook:
   ```tmux
   # set-hook -ag client-attached 'run-shell -b "~/.config/tmux/scripts/check-update.sh"'
   ```
3. Reload config: `Ctrl+a r`

Or simply ignore the notification and keep using your current version.

## Troubleshooting

### "Network is unreachable" error

If you see an error when pressing `Ctrl+u`, check:

1. Internet connection is working
2. `curl` or `wget` is installed (`which curl` or `which wget`)
3. GitHub API is accessible from your location (not blocked by firewall)

### The notification doesn't appear

- If you're on the latest release and have a `zmux-version` file, it won't appear
- For dev installs, delete `~/.config/tmux/.update-check-ts` to force an immediate API check
- Check `~/.config/tmux/scripts/check-update.sh` is executable

### "Command not found: zmux" when updating

If the popup shows "Command not found: zmux":

1. Ensure `~/.local/bin` is in your `$PATH`
2. Add to your `.bashrc` or `.zshrc`:
   ```bash
   export PATH="$HOME/.local/bin:$PATH"
   ```
3. Reload shell and try again

## GitHub Release Process

When a new release is tagged on GitHub:

1. **GitHub Actions** runs the release workflow (`.github/workflows/release.yml`)
2. Workflow:
   - Extracts version from git tag
   - Stamps `VERSION` file with the tag
   - Creates tarball (with `VERSION` included)
   - Publishes release to GitHub with tarball attached

3. The `check-update.sh` script fetches this tag and your version is compared against it

Users can then run `zmux update` to download and install the new release.
