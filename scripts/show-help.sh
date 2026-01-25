#!/bin/bash
# show-help.sh - Display zmux keybinding help in a popup

cat <<'HELP'
zmux Keybindings Help

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

MAIN MODES (Always available - shown in status bar)

  Ctrl+o   Sessions   | Ctrl+t   Tabs         | Ctrl+p   Panes
  Ctrl+h   Move pane  | Ctrl+n   Resize pane  | Ctrl+l   Lock/Unlock
  Ctrl+g   Git ops

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

COMMON ACTIONS (Same across Session, Tab, and Pane modes)

  Action        Sessions    Tabs         Panes
  ───────────────────────────────────────────────────
  New           Ctrl+o, n   Ctrl+t, n    Ctrl+p, n
  Rename        Ctrl+o, r   Ctrl+t, r   
  Kill          Ctrl+o, x   Ctrl+t, x    Ctrl+p, x
  Switch        Ctrl+o, w   
  Navigate                  Ctrl+t, ←→   Ctrl+t, ←↑↓→

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PANE-SPECIFIC MODES

  Ctrl+h, ←↑↓→  Move/Swap panes  - Reposition panes within the window
  Ctrl+n, ←↑↓→  Resize panes     - Adjust pane dimensions

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

GIT OPERATIONS  (Ctrl+g, [subcommand])

  Ctrl+g, b     Git branch     - Insert branch name into command line
  
  Notes:
    - Git operations open fzf for interactive selection
    - Selected branch name is inserted at cursor (doesn't execute)
    - Type the branch name to filter
    - Press Enter to select and insert
    - Useful for: git checkout, git merge, git rebase, etc.

  Example workflow:
    $ git checkout [Ctrl+g, b]
    > [fzf opens showing all branches]
    > Type to find: "feat"
    > Press Enter
    > $ git checkout feature/new-api [cursor here]
    > [Type additional args or hit Enter to execute]
    > [Press Enter to checkout branch]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PANE-SPECIFIC MODES

  Ctrl+h, ←↑↓→  Move/Swap panes  - Reposition panes within the window
  Ctrl+n, ←↑↓→  Resize panes     - Adjust pane dimensions

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

NAVIGATION

  Arrow Keys              Navigate (panes, tabs in their modes)
  
  Ctrl + Arrow Keys       Quick tab switching in root mode
    Ctrl+←                Previous tab
    Ctrl+→                Next tab
  
  Alt + Arrow Keys        Quick pane navigation in root mode
    Alt+←                 Navigate to left
    Alt+→                 Navigate to right
    Alt+↑                 Navigate to up            
    Alt+↓                 Navigate to down

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

LOCK MODE  (Ctrl+l)

  Purpose: Lock all keyboard input to prevent accidental tmux commands
  Indicator: 🔒 appears in status bar when active
  Exit: Press Ctrl+l or any unbound key

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STATUS BAR HINTS

  The right side of the status bar shows context-sensitive keybinding hints
  for the currently active mode. Hints update automatically as you navigate.

HELP
