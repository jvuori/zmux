# zmux notify

`zmux notify` flashes the tmux tab to signal that something needs your attention — a long-running command finished, or Claude Code is waiting for your reply.

## How it works

When called, `zmux notify`:

1. **Flashes the tab** in the status bar 3 times (fast 200ms/100ms cycle)
2. **Leaves a persistent `i` badge** on the tab if you are currently in a different window — so you still see the signal when you come back
3. **Silently clears** if you are already in the same window (no false alarm)
4. **Drains stdin** if called from a pipe — output passes through to your terminal, then the flash fires once the upstream command exits

## Basic usage

```bash
# Flash immediately
zmux notify

# Flash after a command finishes (pipe form)
sleep 60 | zmux notify
make build | zmux notify
```

The pipe form is the most common pattern: chain `| zmux notify` onto any long-running command and you will get a tab flash the moment it exits, regardless of which window you are in.

## CLI use cases

### Build and test pipelines

```bash
# Notify when a slow build finishes
cargo build --release 2>&1 | zmux notify

# Run the full test suite and flash when done
pytest -x 2>&1 | zmux notify

# Docker image build
docker build -t myapp . | zmux notify
```

### Data processing

```bash
# Long-running data export
pg_dump mydb > backup.sql && zmux notify

# Model training or heavy computation
python train.py | zmux notify

# Large file operations
rsync -avz /data/large-dir remote:/backup/ | zmux notify
```

### Waiting for external events

```bash
# Wait for a service to become healthy, then notify
until curl -sf http://localhost:8080/health; do sleep 2; done && zmux notify

# Wait for a background job to finish
./start-long-job.sh &
wait && zmux notify

# Poll until a file appears (e.g. a CI artifact)
until [ -f ./dist/output.tar.gz ]; do sleep 5; done && zmux notify
```

### Combining with watch / tail

```bash
# Tail a log and notify when a specific line appears
tail -f app.log | grep -m1 "Build succeeded" | zmux notify

# Watch for a test run to complete in a log file
tail -f /var/log/ci.log | grep -m1 "PASSED\|FAILED" | zmux notify
```

### Remote work over SSH

```bash
# Run a long job on a remote host and notify locally when done
ssh build-server 'make release' && zmux notify

# Deploy and flash when the remote script exits
ssh prod './deploy.sh' | zmux notify
```

## Claude Code integration

Claude Code can trigger `zmux notify` automatically via hooks in `~/.claude/settings.json`.
This is useful when you start a task in Claude Code and switch to another tmux window while it works — you will get a tab flash and `i` badge the moment Claude finishes and is waiting for your input.

```json
{
  "hooks": {
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "zmux notify"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "zmux notify"
          }
        ]
      }
    ]
  }
}
```

**`Notification`** fires when Claude explicitly signals task completion (e.g. after a long autonomous run).  
**`Stop`** fires every time Claude finishes its turn and waits for your reply — the most useful hook for the "I'm in another tab" scenario.

> Note: `PreToolUse` is intentionally **not** used here — it fires before every file read and shell command, which would flood you with flashes mid-task rather than only when Claude needs your attention.

You can set this up by editing `~/.claude/settings.json` directly, or via the Claude Code settings UI.

## Notes

- `zmux notify` is a no-op outside tmux (exits silently), so it is safe to use in scripts that may run in non-tmux environments
- The `i` badge persists until you visit the window; it is cleared automatically on focus
- The visual effect is purely in the tmux status bar — no system notifications or sounds are used
