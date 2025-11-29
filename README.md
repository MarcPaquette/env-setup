# Environment Setup Script

Automated bash script to set up a development environment with your preferred tools and configurations.

## Features

- **Cross-platform support**: Supports Ubuntu/Debian (apt) and macOS (brew)
- **Idempotent**: Safe to run multiple times without errors
- **Core tools**: curl, git, make, gcc
- **Latest versions**: Neovim (from GitHub releases on Linux), Go, and uv
- **Ghostty terminal**: Automatic architecture detection for AppImage
- **Fish shell**: Set as default shell with native prompt configuration
- **Configuration management**: Clones and symlinks config repositories
- **tmuxfiles**: Checked out to specific commit with install script execution
- **Extensible**: Ready for additional dotfiles

## Components Installed

- **Package managers**: apt (Linux) or Homebrew (macOS)
- **Development tools**: curl, git, make, gcc
- **Shell**: Fish shell (set as default)
- **Editor**: Neovim (latest)
- **Terminal emulator**: Ghostty
- **Language runtimes**: Go (latest)
- **Python tools**: uv (fast Python package manager)
- **Configuration repos**:
  - tmuxfiles: `https://github.com/MarcPaquette/tmuxfiles`
  - neovim-config: `https://github.com/MarcPaquette/neovim-config`

## Configuration Structure

Configurations are cloned to `~/.dotfiles/` and symlinked as follows:

```
~/.dotfiles/
├── tmuxfiles/     (commit: 0dc93fdc1d414e1e14aa29a5cceca9b12ecfc412)
│   └── install.sh (executed automatically)
├── neovim-config/ → ~/.config/nvim (full directory symlink)
└── [other configs added later]

~/.config/
├── tmux/config → ~/.dotfiles/tmuxfiles
├── nvim/ → ~/.dotfiles/neovim-config
└── fish/ (ready for configuration)
```

## Prerequisites

- **Linux**: Ubuntu/Debian-based distribution with apt
- **macOS**: Homebrew installed (https://brew.sh)
- **Both**: sudo access for package installation

## Usage

1. Clone or download this repository
2. Make the script executable (already done if downloaded as-is)
3. Run the script:

```bash
./setup.sh
```

The script will:
1. Detect your OS and architecture
2. Install core packages and tools (curl, git, make, gcc)
3. Install Fish shell and set it as default
4. Install Neovim (latest - from GitHub releases on Linux, brew on macOS)
5. Install Ghostty (with architecture-specific AppImage on Linux, brew on macOS)
6. Install Go (latest)
7. Install uv (Python package manager)
8. Clone configuration repositories to `~/.dotfiles/`
9. Create symlinks: tmux and neovim configs
10. Run tmuxfiles install.sh script
11. Set Fish as default shell

## Idempotency

The script is idempotent:
- Already installed packages are skipped
- Existing symlinks are not recreated
- Git repositories are updated via `pull` if they exist
- Safe to run multiple times

## Post-Installation

After running the script:

1. **Restart your shell** or log out and back in for Fish to become your default shell
2. **Configure Fish prompt** using Fish's native configuration at `~/.config/fish/`
3. **Add future dotfiles** by cloning repositories to `~/.dotfiles/` and creating symlinks in `~/.config/`

## Future Enhancements

- Add git configuration dotfiles
- Add shell aliases and functions
- Add additional tool configurations
- Add vim/neovim plugin management

## Troubleshooting

### "Homebrew not found" on macOS
Install Homebrew first: https://brew.sh

### Ghostty not found on Linux
Ensure `~/.local/bin` is in your PATH. Add to `~/.config/fish/config.fish`:
```fish
set -gx PATH $HOME/.local/bin $PATH
```

### Go not in PATH
Ensure `/usr/local/go/bin` is in your PATH. Add to `~/.config/fish/config.fish`:
```fish
set -gx PATH /usr/local/go/bin $PATH
```

### uv not in PATH
Ensure `~/.cargo/bin` is in your PATH. Add to `~/.config/fish/config.fish`:
```fish
set -gx PATH $HOME/.cargo/bin $PATH
```

### Shell change didn't take effect
Log out and back in, or start a new terminal session.

## License

This script is provided as-is for personal use.
# env-setup
# env-setup
# env-setup
