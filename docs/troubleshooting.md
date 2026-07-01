# Troubleshooting

Run `zmux doctor` first — it checks the most common problems automatically.

## Keybindings not working (Ctrl+p shows previous command, etc.)

Your shell is intercepting the keys before tmux sees them.

1. Run the shell setup script:

   ```bash
   ./setup-shell.sh
   ```

2. Reload your shell config:

   ```bash
   source ~/.bashrc  # or source ~/.zshrc
   ```

3. Reload the tmux config (press prefix, then):

   ```
   :source-file ~/.config/tmux/tmux.conf
   ```

4. Test: `Ctrl+p` should enter pane mode (not show the previous command).

See [shell-config.md](shell-config.md) for manual setup and details.

## Ctrl+G (or other modal keys) stopped working after installing neovim / yazi

WezTerm's `enable_csi_u_key_encoding = true` sends extended key sequences (CSI u / Kitty keyboard protocol) that tmux won't decode unless `extended-keys on` is set. This is included in zmux's default config; if you are on an older install, run `zmux update` or add the line manually:

```
set -g extended-keys on
```

`zmux doctor` will detect and report this mismatch.

## Installation had no effect / Old config still active

1. Check that files were copied:

   ```bash
   ls -la ~/.config/tmux/
   ```

2. Fix the installation:

   ```bash
   ./fix-installation.sh
   ```

3. Reload tmux config in existing sessions:

   ```bash
   tmux source-file ~/.config/tmux/tmux.conf
   ```

   Or restart tmux entirely:

   ```bash
   exit   # leave the current session
   tmux   # start a new one
   ```

4. Verify: press `Ctrl+p` (pane mode), `Ctrl+n` (resize mode), `Ctrl+a` (prefix).

## Plugins not installing

1. Check TPM is present: `ls ~/.tmux/plugins/tpm`
2. If missing: `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`
3. In tmux: `Ctrl+a i`

## Status bar not showing

1. Check it is enabled: `tmux show-options -g status`
2. Reload config: `Ctrl+a r`

## Session restore not working

1. Verify autostart: `./verify-autostart.sh`
2. Check the resurrect directory exists: `ls ~/.local/share/tmux/resurrect/`
3. Run a manual save: `Ctrl+a Ctrl+s`, then try restoring: `Ctrl+a Ctrl+r`

See [session-restore.md](session-restore.md) for full details.
