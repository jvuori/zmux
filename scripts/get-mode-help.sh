#!/bin/bash
# Display mode-specific help hints for status bar RIGHT side
# Compact, colored, intuitive format using bracket notation

PANE_ID="${1}"

# Check if locked mode is active
LOCK_MODE=$(tmux display-message -p -t "$PANE_ID" "#{@lock_mode}")

# If locked, show only unlock hint
if [ "$LOCK_MODE" = "1" ]; then
    echo "#[fg=colour244]Ctrl+ [#[fg=colour220]l:unlock#[fg=colour244]]"
    exit 0
fi

case "$KEY_TABLE" in
  session)
    # Ctrl+o: Session mode
    echo "#[fg=colour244][#[fg=colour51]n#[default]: new #[fg=colour244]| #[fg=colour51]r#[default]: rename #[fg=colour244]| #[fg=colour51]x#[default]: kill #[fg=colour244]| #[fg=colour51]w#[default]: switch#[fg=colour244]]"
    ;;
  tab)
    # Ctrl+t: Tab mode
    echo "#[fg=colour244][#[fg=colour46]n#[default]: new #[fg=colour244]| #[fg=colour46]r#[default]: rename #[fg=colour244]| #[fg=colour46]x#[default]: kill #[fg=colour244]| #[fg=colour46]←→#[default]: nav#[fg=colour244]]"
    ;;
  pane)
    # Ctrl+p: Pane mode
    echo "#[fg=colour244][#[fg=colour81]n#[default]: new #[fg=colour244]| #[fg=colour81]x#[default]: kill #[fg=colour244]| #[fg=colour81]←↑↓→#[default]: nav#[fg=colour244]]"
    ;;
  move)
    # Ctrl+h: Move/swap panes mode
    echo "#[fg=colour244][#[fg=colour201]←↑↓→#[default]: move#[fg=colour244]]"
    ;;
  resize)
    # Ctrl+n: Resize panes mode
    echo "#[fg=colour244][#[fg=colour220]←↑↓→#[default]: resize#[fg=colour244]]"
    ;;
  *)
    # Root mode: Show all modes with single Ctrl+ prefix
    echo "#[fg=colour244]Ctrl+ [#[fg=colour51]o#[default]:#[fg=colour51]sessions#[fg=colour244] | #[fg=colour46]t#[default]:#[fg=colour46]tabs#[fg=colour244] | #[fg=colour81]p#[default]:#[fg=colour81]panes#[fg=colour244] | #[fg=colour81]h#[default]:#[fg=colour81]move#[fg=colour244] | #[fg=colour81]n#[default]:#[fg=colour81]resize#[fg=colour244] | #[fg=colour200]g#[default]:#[fg=colour200]git#[fg=colour244]]"
    ;;
esac
