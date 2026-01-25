# Zmux Testing

This directory contains Docker-based integration tests for zmux installation and functionality.

## Overview

The test suite validates:

- Installation procedure completes successfully
- All configuration files are created
- All scripts are present and executable
- Tmux modes and key bindings are properly configured
- Git operations work correctly
- All dependencies (TPM, fzf, plugins) are installed

## Running Tests Locally

### Prerequisites

- Docker installed
- From the zmux root directory

### Run all tests

```bash
docker build -f tests/Dockerfile -t zmux-test .
docker run --rm zmux-test
```

### Run specific test

```bash
docker build -f tests/Dockerfile -t zmux-test .
docker run --rm zmux-test bash tests/test-installation.sh
```

## Test Suite

### test-installation.sh

Verifies that:

- install.sh completes without errors
- Config directory structure is created
- All configuration files are present
- TPM is installed
- fzf is installed
- All scripts are copied and executable

### test-modes.sh

Verifies that:

- All tmux key tables are defined (pane, tab, session, move, resize, git)
- Each mode has appropriate key bindings
- Prefix key is set to Ctrl+a
- Repeat-time is configured to 2000ms
- Status bar is positioned at top

**Automation**: Fully automated - uses config file verification in headless environments

### test-git-operations.sh

Verifies that:

- Git branch selection script works correctly
- Git commits selection script works correctly
- Popup wrapper scripts are present and executable
- Scripts can access git repositories
- Branch selection returns valid branch names
- Commit selection returns valid commit SHAs

**Automation**: Fully automated - scripts support both interactive and automated modes
- Scripts detect piped input and use fzf `--filter` mode for testing
- Test provides search terms via stdin to simulate user selection
- No interactive user input required

### test-scripts.sh

Verifies that:

- All required scripts are present
- Scripts have correct permissions
- Scripts have valid bash syntax
- Scripts have proper shebangs

**Automation**: Fully automated - no user interaction required

## CI/CD

Tests automatically run on:

- Push to master/main/develop branches
- Pull requests to master/main/develop
- Manual workflow dispatch

See `.github/workflows/test.yml` for the GitHub Actions configuration.

## Test Automation Strategy

### Fully Automated Tests

All tests are **fully automated** and require no user interaction:

**test-installation.sh**
- Runs the installer script non-interactively
- Verifies all files and dependencies are installed

**test-modes.sh**
- Verifies configuration files in headless environment
- Falls back to config file parsing when tmux unavailable
- No interactive tmux sessions required

**test-git-operations.sh**
- Git scripts support both interactive and automated modes
- Detects piped input (`[ ! -t 0 ]`) to activate test mode
- In test mode: Uses fzf `--filter` to match search terms from stdin
- In interactive mode: Full UI with previews and key bindings

**test-scripts.sh**
- Static validation of syntax, permissions, and structure
- No runtime execution required

### Interactive vs Automated Modes

The git operation scripts (`fzf-git-branch.sh`, `fzf-git-commits.sh`) are designed to work in both modes:

**Interactive Mode** (user usage)
```bash
# Direct execution: Full fzf UI with previews and keybindings
./scripts/fzf-git-branch.sh
```

**Automated Mode** (testing)
```bash
# Piped input: fzf --filter mode for automated selection
echo "search_term" | ./scripts/fzf-git-branch.sh
```

This allows the same scripts to be used interactively while remaining fully testable.

## Test Environment

- Base image: Debian Bookworm Slim
- Pre-installed: git, curl, bash, zsh, tmux (via installation)
- Non-root user: testuser
- Fresh installation on each run

## Adding New Tests

1. Create a new test script in `tests/`
2. Make it executable: `chmod +x tests/test-newfeature.sh`
3. Add it to `tests/run-tests.sh`
4. Follow the pattern:
   - Exit 0 on success
   - Exit 1 on failure
   - Echo descriptive error messages
   - Clean up any resources

## Troubleshooting

### Test fails locally but passes in CI (or vice versa)

- Check Docker image consistency
- Verify environment variables
- Check for timing issues with tmux initialization

### "Tmux server not found" errors

- Ensure tmux has time to initialize (add `sleep 1` after starting)
- Kill any existing tmux servers before tests: `tmux kill-server 2>/dev/null || true`

### Permission errors

- Verify scripts are marked executable in git: `git ls-files --stage scripts/`
- Check Dockerfile COPY preserves permissions
