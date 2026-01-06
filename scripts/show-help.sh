#!/bin/bash
# show-help.sh - Display zmux keybinding help

# Create a temporary file with help content
HELP_FILE=$(mktemp)
cat > "$HELP_FILE" <<'HELP'
┌──────────────────────────────────────────────────────────────────────────────┐
│                          zmux Keybindings Help                               │
├──────────────────────────────────────────────────────────────────────────────┤
│ Mode Activation                                                              │
│   Ctrl+p  Pane mode      - Manage panes (split, close, navigate)             │
│   Ctrl+n  Resize mode    - Resize panes with arrow keys                      │
│   Ctrl+h  Move mode      - Move/reorder panes                                │
│   Ctrl+t  Tab mode       - Manage tabs/windows                               │
│   Ctrl+s  Scroll mode    - Scroll and copy mode                              │
│   Ctrl+o  Session mode   - Session management                                │
│                                                                              │
│ Quick Actions                                                                │
│   Ctrl+g       Lock/Unlock session                                           │
│   Ctrl+q       Quit (kill all sessions)                                      │
│   Ctrl+g r     Reload configuration                                          │
│   Ctrl+g s     Session switcher                                              │
│   Ctrl+g ?     Show this help                                                │
│                                                                              │
│ Pane Mode (Ctrl+p)                                                           │
│   h/←    Move left          l/→    Move right                                │
│   j/↓    Move down          k/↑    Move up                                   │
│   n      New pane (smart)   x      Close pane                                │
│   p      Switch focus       f      Fullscreen                                │
│                                                                              │
│ Resize Mode (Ctrl+n)                                                         │
│   ←/h    Resize left        →/l    Resize right                              │
│   ↑/k    Resize up          ↓/j    Resize down                               │
│   H/L/K/J  Coarse resize                                                     │
│                                                                              │
│ Tab Mode (Ctrl+t)                                                            │
│   ←/h    Previous tab      →/l     Next tab                                  │
│   n      New tab            x      Close tab                                 │
│   r      Rename tab         1-9    Switch to tab                             │
│                                                                              │
│ Session Mode (Ctrl+o)                                                        │
│   n      New session        r      Rename session                            │
│   w      Session manager    d      Detach                                    │
│                                                                              │
│ Scroll Mode (Ctrl+s)                                                         │
│   ↑/k    Scroll up          ↓/j    Scroll down                               │
│   v      Begin selection    y      Copy & exit                               │
│                                                                              │
│ Shared (All Modes)                                                           │
│   Alt+h/←  Move left       Alt+l/→  Move right                               │
│   Alt+j/↓  Move down       Alt+k/↑  Move up                                  │
│   Alt+n    New pane        Alt+=    Resize increase                          │
│                                                                              │
│ Press 'q' to close                                                           │
└──────────────────────────────────────────────────────────────────────────────┘
HELP

# Check if tmux popup is available (tmux 3.2+)
if tmux display-popup -h >/dev/null 2>&1; then
    # Use popup for better display
    tmux display-popup -w 80 -h 30 -E "less -R '$HELP_FILE'; rm -f '$HELP_FILE'"
else
    # Fallback: display in a new window
    tmux new-window -n "zmux-help" "less -R '$HELP_FILE'; rm -f '$HELP_FILE'"
fi
