# Rules
## Installation Script Completeness

When tmux config files source other config files (e.g., `keybindings.conf` sources `lock-mode-bindings.conf`), ensure **all sourced files are copied during installation and updates**. Missing sourced files will cause "No such file or directory" errors on startup.

**Action**: Always check that both `install.sh` and `update.sh` copy all configuration files that are referenced via `source-file` directives.
