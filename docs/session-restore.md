# Session Restoration

zmux automatically saves and restores your tmux sessions, including the programs running in each pane.

## Automatic restore at login

The installer sets up **XDG autostart** so tmux starts in the background when you log into your graphical desktop — before you open any terminal. When you open a terminal window, your previous sessions appear instantly with no waiting.

This works on all Linux desktop environments (GNOME, KDE, XFCE, i3, etc.).

To verify the autostart is configured:

```bash
./verify-autostart.sh
```

## What gets saved

Sessions are saved automatically every ~5 minutes by tmux-continuum. A final save also runs at logout/shutdown via a systemd user service (`tmux-shutdown-save.service`).

Each save captures:
- Session and window layout
- Pane working directories
- The program running in each pane (see below)

## Program restoration

When sessions are restored, zmux re-launches the program that was running in each pane — not just the shell:

| Program | Behaviour |
|---------|-----------|
| **Claude Code** | Resumes the last conversation via `claude --continue`. Extra flags (`--debug`, etc.) are preserved. If originally launched with `--resume SESSION_ID` or `--session-id`, the exact original command is used. |
| **Cursor Agent / Copilot** | Re-launched with the original command; their session state survives reboots in the tool's own state directory. |
| **Any other program** | Re-launched with its original arguments: `vim notes.txt` reopens that file, `htop` restarts normally, etc. |
| **Shells** | Skipped — the pane already has a prompt after session restore. |
| **Destructive tools** (`dd`, `mkfs`, `fdisk`, `apt`, …) | Never auto-restarted. |

## Manual save and restore

You can trigger a save or restore at any time from within tmux:

| Action | Keys |
|--------|------|
| Save session | `Ctrl+a` `Ctrl+s` |
| Restore session | `Ctrl+a` `Ctrl+r` |

## Manual startup

If autostart is not available or you prefer to start tmux manually:

**Script directly:**

```bash
~/.config/tmux/scripts/tmux-start.sh
```

**Shell alias** — add to `~/.bashrc` or `~/.zshrc`:

```bash
alias tmux='~/.config/tmux/scripts/tmux-start.sh'
```

**WezTerm** — the default config already uses this script:

```lua
default_prog = { '/bin/bash', '-c', 'exec ~/.config/tmux/scripts/tmux-start.sh' }
```
