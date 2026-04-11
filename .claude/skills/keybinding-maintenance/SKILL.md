---
name: keybinding-maintenance
description: When updating keybinding hints, mode names, or keybindings themselves, this skill ensures all related files are updated consistently and become effective. Activates when working on keybindings, hints, or related configuration changes.
version: 1.0.0
---

# Keybinding Maintenance Skill

When modifying keybindings, hint texts, or mode-related configuration, changes must be applied consistently across **multiple files** to take effect. This skill identifies all locations that must be updated.

## When This Skill Applies

Activate when:

- Adding, removing, or renaming keybindings
- Changing hint text labels (e.g., "zoom" → "focus")
- Modifying mode names or descriptions
- Updating keybinding descriptions or comments
- Any change to `Ctrl+*` or mode activation keys

## Critical File Locations for Keybinding Changes

### 1. **Keybinding Definitions** (Active - keybindings work)

**File**: `tmux/keybindings.conf`

**What to update**:

- Key binding commands: `bind -T pane f ...`
- Comments describing each binding
- Mode names in key table switches

**Example**:

```tmux
# ❌ Old: Toggle fullscreen
# ✅ New: Toggle fullscreen (focus pane)
bind -T pane f resize-pane -Z \; switch-client -T root
```

### 2. **Status Bar Hints - Hardcoded** (CRITICAL - What users see)

**File**: `tmux/statusbar.conf`

**What to update**:

- Pane mode hint in `if-shell` conditions (appears twice for WSL and Linux)
- Tab mode hints
- Session mode hints
- Move/Resize/Git mode hints
- Root mode keybinding legend

**Example**:

```tmux
# ❌ Old: #[fg=colour81]f#[default]: zoom
# ✅ New: #[fg=colour81]f#[default]: focus

# Both if-shell branches MUST be updated:
"set -g status-right '...#{?#{==:#{client_key_table},pane},...
[...n: new | d: below | r: right | f: focus | x: kill | ←↑↓→: nav...]
..."
```

**Critical**: Status bar hints appear **twice** in statusbar.conf:

1. Inside first `if-shell` (WSL detection)
2. Inside second `if-shell` (Linux/macOS)

Both must match - updating only one leaves inconsistency.

### 3. **Helper Script Hints** (Backup/Reference)

**File**: `scripts/get-mode-help.sh`

**What to update**:

- Case statements for each mode (pane, tab, session, move, resize, git)
- Echo output containing hint text

**Example**:

```bash
pane)
  # Ctrl+p: Pane mode
  echo "#[fg=colour244][...f#[default]: focus...]"
  ;;
```

**Note**: This script is NOT currently used by the status bar (hints are hardcoded in statusbar.conf), but it serves as documentation and could be called in the future via the statusbar. Keep it in sync with statusbar.conf for consistency.

### 4. **Documentation** (Optional but recommended)

**Files**:

- `docs/keymap.md` - User-facing keybinding reference table
- `README.md` - Feature descriptions
- Commit messages - Describe what changed

**Example in docs/keymap.md**:

```markdown
| `f` | Toggle focus (fullscreen) |
```

## Exact Locations Checklist

Use this checklist when updating any keybinding or hint:

### For hint text changes (e.g., "zoom" → "focus"):

- [ ] `tmux/statusbar.conf` - First `if-shell` block, pane mode hint
- [ ] `tmux/statusbar.conf` - Second `if-shell` block, pane mode hint (same text)
- [ ] `scripts/get-mode-help.sh` - Pane case statement
- [ ] `tmux/keybindings.conf` - Comment on the keybinding
- [ ] `docs/keymap.md` - Description in Pane Mode table

### For new keybindings (e.g., adding `Ctrl+g` for git):

- [ ] `tmux/keybindings.conf` - Define the binding and mode table
- [ ] `tmux/statusbar.conf` - Add case condition for new key table (both if-shell branches)
- [ ] `scripts/get-mode-help.sh` - Add case statement with hints
- [ ] `docs/keymap.md` - Add to appropriate section

### For removing keybindings:

- [ ] `tmux/keybindings.conf` - Remove binding and mode table
- [ ] `tmux/statusbar.conf` - Remove case condition (both if-shell branches)
- [ ] `scripts/get-mode-help.sh` - Remove case statement
- [ ] `docs/keymap.md` - Remove from documentation

## Why Multiple Locations?

1. **statusbar.conf (hardcoded)** - Direct status bar output; actual source of truth for what displays
2. **get-mode-help.sh** - Extracted hints; serves as documentation and fallback/future use
3. **keybindings.conf** - Binding logic; comments help developers understand intent
4. **docs/keymap.md** - User-facing documentation; must match implementation

## Verification Steps

After making keybinding changes:

1. **Syntax check**: `tmux -f ~/.config/tmux/tmux.conf -S`
2. **Reload config**: In tmux, press `Ctrl+a`, then `r`
3. **Test hints**: Press the keybinding mode key (e.g., `Ctrl+p`) and check status bar
4. **Verify all files**: Search for old text to ensure no instances remain
   ```bash
   grep -r "zoom" --include="*.conf" --include="*.sh" --include="*.md"
   ```

## Common Mistakes to Avoid

❌ **Updating only get-mode-help.sh** - Changes won't appear in status bar (not currently used)

✅ **Update statusbar.conf** - The actual source for status bar display

❌ **Updating only one if-shell branch** in statusbar.conf - WSL users won't see changes

✅ **Update both if-shell blocks** - Ensure consistency across platforms

❌ **Forgetting documentation** - Users don't know about the new keybinding

✅ **Update docs/keymap.md** - Keep user docs in sync

## CRITICAL: Dynamic Width Conditionals in statusbar.conf

The two `set -g status-right` lines in `statusbar.conf` are extremely long (500+ chars each). Every edit carries the risk of accidentally truncating the **dynamic width conditionals** at the tail of each line:

```
#{?#{e|>=|:#{client_width},220}, 🔋 <battery widget>,}#{?#{e|>=|:#{client_width},190}, ⏰ %H:%M 📅 %d %b %Y,}
```

These conditionals hide the battery widget below 220 columns and the time/date below 190 columns. If they are dropped the widgets are always visible and break narrow terminal layouts. This happened once already (fixed in commit `91679fa`).

### Safe editing rule

**Only replace the minimum substring that must change.** Never replace large swaths of the line. For example, to rename a hint from `Ctrl+u` to `Ctrl+a U`, replace only the literal string `Ctrl+u`, not the surrounding 200+ characters.

### Mandatory post-edit verification

After **any** edit to `tmux/statusbar.conf`, run:

```bash
grep -o 'client_width' tmux/statusbar.conf | wc -l
```

Expected output: **4** (two conditionals × two if-shell branches). If the count is less than 4, the edit dropped a conditional and must be fixed before committing.

## Implementation Pattern

When making a keybinding hint change, follow this order:

1. Update `tmux/statusbar.conf` (both if-shell branches)
2. Update `tmux/keybindings.conf` comments
3. Update `scripts/get-mode-help.sh` for documentation
4. Update `docs/keymap.md` for users
5. Reload and test: Enter the mode and check status bar
6. Verify with grep that no old text remains

## Key Insight

**The status bar displays hardcoded hints, not dynamic script output.** All hint changes must be made in `statusbar.conf` to be effective. The `get-mode-help.sh` script exists for testing, documentation, and potential future use if the architecture changes to call the script.

## Files Modified by This Skill Knowledge

```
tmux/
├── keybindings.conf      ← Binding definitions + comments
├── statusbar.conf        ← CRITICAL: Status bar hints (two if-shell blocks)
└── modes/
    ├── pane.conf
    ├── tab.conf
    ├── resize.conf
    └── move.conf

scripts/
└── get-mode-help.sh      ← Hint documentation (not currently used)

docs/
└── keymap.md             ← User-facing reference

.claude/skills/
└── keybinding-maintenance/
    └── SKILL.md          ← This file
```
