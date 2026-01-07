# zmux Philosophy

## What is zmux?

zmux is a configuration for tmux that makes it behave as closely as possible to [Zellij](https://zellij.dev/), a modern terminal workspace with batteries included. Zellij provides an excellent user experience with modal keybindings, intuitive pane/tab management, and a beautiful interface.

## Why zmux?

While Zellij is fantastic, there are situations where you might want to use tmux instead:
- **Compatibility**: tmux is more widely available and has better compatibility with older systems
- **Performance**: tmux can be lighter on resources in some cases
- **Ecosystem**: tmux has a mature plugin ecosystem
- **Familiarity**: You might already know tmux and want Zellij-like UX

zmux bridges this gap by providing Zellij's user experience on tmux's foundation.

## Design Principles

### 1. Modal Interface
Zellij uses modes (Pane, Tab, Resize, Move, Scroll) to organize functionality. zmux replicates this with tmux's key tables, making the experience feel natural and organized.

### 2. Intuitive Keybindings
- **Prefix**: `Ctrl+a` (quicker to type)
- **Modes**: Activate with prefix + mode key (e.g., `Ctrl+a p` for pane mode)
- **Navigation**: Arrow keys and vim-style hjkl work consistently

### 3. Modern Aesthetics
- Clean, minimal status bar
- Subtle colors and borders
- Top status bar (like Zellij)

### 4. Session Management
- Easy session switching
- Automatic session restoration (via plugins)
- Session persistence

### 5. Plugin Integration
zmux uses essential tmux plugins to enhance functionality:
- **tmux-resurrect**: Save and restore sessions
- **tmux-continuum**: Auto-save sessions
- **tmux-yank**: Better clipboard integration
- **tmux-open**: Open files/URLs from terminal

## Key Differences from Standard tmux

1. **Modal Keybindings**: Instead of prefix + key combinations, zmux uses modes
2. **Default Prefix**: Changed from `Ctrl+b` to `Ctrl+a`
3. **Status Bar**: Modern, minimal design at the top
4. **Pane Management**: More intuitive splitting and navigation
5. **Tab Management**: Windows are treated as tabs (Zellij-style)

## Philosophy vs. Implementation

zmux aims to provide the **experience** of Zellij, not an exact clone. Some Zellij features (like its plugin system, layout engine, or UI components) are unique to Zellij and cannot be replicated in tmux. However, the core workflow and keybindings can be closely approximated.

## Future Directions

- Better integration with terminal emulators
- More Zellij-like visual features
- Enhanced session management
- Improved plugin ecosystem integration

