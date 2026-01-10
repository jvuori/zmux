# Differences Between zmux and Zellij

This document outlines the key differences between zmux (tmux configured like Zellij) and actual Zellij. Understanding these differences helps set proper expectations.

## Fundamental Differences

### Architecture
- **Zellij**: Standalone application written in Rust with its own rendering engine
- **zmux**: Configuration layer on top of tmux (C-based terminal multiplexer)

### UI Rendering
- **Zellij**: Custom UI with panels, borders, and visual elements rendered by Zellij itself
- **zmux**: Uses terminal capabilities and tmux's built-in rendering (limited by terminal)

## Feature Comparison

### ✅ Features That Work Similarly

| Feature | Zellij | zmux | Notes |
|---------|--------|------|-------|
| Modal keybindings | ✅ | ✅ | Implemented via tmux key tables |
| Pane splitting | ✅ | ✅ | Works identically |
| Tab/window management | ✅ | ✅ | Windows act as tabs |
| Session management | ✅ | ✅ | Via tmux sessions + plugins |
| Scroll/copy mode | ✅ | ✅ | tmux copy mode |
| Resize panes | ✅ | ✅ | Standard tmux functionality |
| Move panes | ✅ | ✅ | Via swap-pane commands |

### ⚠️ Features That Work Differently

| Feature | Zellij | zmux | Difference |
|---------|--------|------|------------|
| **Status bar** | Custom rendered | Terminal-based | zmux uses tmux status bar (less customizable) |
| **Layouts** | Advanced layout engine | Basic tmux layouts | Zellij has more sophisticated layouts |
| **Plugins** | Zellij plugin system | tmux plugins | Different ecosystems |
| **UI elements** | Custom panels/borders | Terminal characters | Zellij can render richer UI |
| **Performance** | Rust-based, fast | C-based, very fast | Both are fast, different architectures |

### ❌ Features Not Available in zmux

| Feature | Zellij | zmux | Reason |
|---------|--------|------|--------|
| **Zellij plugins** | ✅ | ❌ | Different plugin system |
| **Layout presets** | ✅ | ❌ | Zellij-specific feature |
| **Custom UI panels** | ✅ | ❌ | Requires Zellij's rendering engine |
| **Session layouts** | ✅ | ⚠️ | Limited via tmux-resurrect |
| **Floating panes** | ✅ | ❌ | Zellij-specific feature |
| **Pane tabs** | ✅ | ❌ | Zellij-specific feature |
| **Built-in themes** | ✅ | ⚠️ | zmux has one theme, less customizable |
| **Pane borders** | ✅ | ⚠️ | Basic borders, less visual polish |
| **Mouse drag scrolling** | ✅ | ⚠️ | Both auto-scroll when dragging to edge, but tmux is slower. Speed is hardcoded and cannot be changed via configuration |

## Visual Differences

### Status Bar
- **Zellij**: Custom-rendered status bar with icons, colors, and rich formatting
- **zmux**: tmux status bar (text-based, limited styling)

### Pane Borders
- **Zellij**: Thick, styled borders with visual indicators
- **zmux**: Thin borders using terminal characters

### Tab Display
- **Zellij**: Visual tab bar with icons and indicators
- **zmux**: Text-based window list in status bar

## Workflow Differences

### Mode Switching
- **Zellij**: Smooth mode transitions with visual feedback
- **zmux**: Mode switching via key tables (works but less visual feedback)

### Session Management
- **Zellij**: Built-in session management with layouts
- **zmux**: Uses tmux sessions + tmux-resurrect plugin (requires setup)

### Plugin System
- **Zellij**: Zellij-specific plugins (e.g., status-bar, tab-bar)
- **zmux**: tmux plugins (different ecosystem, different capabilities)

## Performance

Both are fast, but:
- **Zellij**: Optimized Rust code, efficient rendering
- **zmux**: tmux is extremely lightweight and fast

## Compatibility

- **Zellij**: Works on most terminals, but requires terminal support
- **zmux**: Works on any terminal that supports tmux (very broad compatibility)

## When to Use Which

### Use Zellij if:
- You want the full Zellij experience with all features
- You need Zellij-specific plugins
- You want the best visual polish
- You're starting fresh and don't need tmux compatibility

### Use zmux if:
- You need tmux compatibility (existing scripts, workflows)
- You're already familiar with tmux
- You need to work on systems where Zellij isn't available
- You want Zellij-like UX on tmux's foundation
- You prefer tmux's plugin ecosystem

## Migration Notes

If you're switching from Zellij to zmux:
1. Most keybindings work the same way
2. Visual appearance will be different (terminal-based vs. custom UI)
3. Some advanced features won't be available
4. Session management works differently (tmux sessions vs. Zellij sessions)

If you're switching from zmux to Zellij:
1. Keybindings are very similar
2. You'll gain access to Zellij-specific features
3. Visual appearance will be more polished
4. Plugin ecosystem is different

## Conclusion

zmux provides **Zellij-like user experience** on tmux, not a full Zellij replacement. It's ideal for users who want Zellij's workflow but need tmux compatibility or prefer tmux's ecosystem. For the full Zellij experience with all features, use Zellij itself.

