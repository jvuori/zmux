#!/bin/bash
# show-help.sh - Display zmux keybinding help in a popup

cat <<'HELP'
┌──────────────────────────────────────────────────────────────────────────────┐
│                          zmux Keybindings Help                               │
├──────────────────────────────────────────────────────────────────────────────┤
│ Mode Activation                                                              │
│   Ctrl+g  Lock/Unlock     - Lock all keys to prevent accidents               │
│   Ctrl+a  Prefix key      - Activate prefix for tmux commands                │
│                                                                              │
│ Quick Actions                                                                │
│   Ctrl+a r     Reload configuration                                          │
│   Ctrl+a s     Session switcher                                              │
│   Ctrl+a i     Install plugins                                               │
│   Ctrl+a u     Update plugins                                                │
│   Ctrl+a ?     Show this help                                                │
│                                                                              │
│ Lock Mode (Shows 🔒 in status bar)                                           │
│   When active: All keys are passed to the terminal                           │
│   Exit by: Pressing Ctrl+g or any unbound key (like §)                       │
│   Purpose: Prevent tmux from intercepting keys                               │
│                                                                              │
│ Alt+Arrow Keys                                                               │
│   Alt+←  Move left        Alt+→  Move right                                  │
│   Alt+↑  Move up          Alt+↓  Move down                                   │
│                                                                              │
│ Lock Mode covers extensive key combinations:                                 │
│   ✓ All letters (a-z, A-Z)                                                  │
│   ✓ All numbers (0-9)                                                       │
│   ✓ Alt combinations (Alt+a, Alt+arrows, etc)                                │
│   ✓ Ctrl combinations (Ctrl+a, Ctrl+arrows, etc)                             │
│   ✓ Function keys (F1-F20 with modifiers)                                    │
│   ✓ Special characters and symbols                                           │
│   ✓ Tab, Enter, Backspace, Escape                                            │
│                                                                              │
│ To exit lock mode:                                                           │
│   1. Press Ctrl+g (always works)                                             │
│   2. Press any unbound key like § (auto-exits and forwards key)              │
│                                                                              │
│ Status Bar                                                                   │
│   A^  Shows prefix is active (waiting for next key after Ctrl+A)            │
│   🔒  Shows lock mode is active (all keys sent to terminal)                  │
└──────────────────────────────────────────────────────────────────────────────┘
HELP
