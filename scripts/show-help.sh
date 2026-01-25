#!/bin/bash
# show-help.sh - Display zmux keybinding help in a popup

cat <<'HELP'
zmux Keybindings Help

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

MAIN MODES (Always available - shown in status bar)

  Ctrl+o   Sessions   | Ctrl+t   Tabs         | Ctrl+p   Panes
  Ctrl+h   Move pane  | Ctrl+n   Resize pane  | Ctrl+l   Lock/Unlock

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

COMMON ACTIONS (Same across Session, Tab, and Pane modes)

  Action        Sessions    Tabs         Panes
  ─────────────────────────────────────────────
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

NAVIGATION

  Arrow Keys        Navigate (panes, tabs in their modes)
  Alt + Arrow Keys  Quick pane navigation in root mode
    Alt+←           Move left          Alt+→  Move right
    Alt+↑           Move up            Alt+↓  Move down

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
