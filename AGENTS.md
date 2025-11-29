# AGENTS.md

## Running & Testing

- **Run setup**: `./setup.sh` (runs the entire environment setup with color-coded logging)
- **Dry run**: Add `set -x` after `set -e` in setup.sh to see what would execute
- **Test syntax**: `bash -n setup.sh`

## Architecture

Single-file bash automation script that orchestrates environment setup across Linux (apt) and macOS (brew):
- **OS Detection**: OSTYPE matching for linux-gnu vs darwin
- **Architecture Detection**: uname -m parsing (x86_64/aarch64) for AppImage selection
- **Install Functions**: Modular functions for each tool/package
- **Config Management**: Clones to `~/.dotfiles/`, symlinks to `~/.config/`
- **Idempotent Design**: All functions check if already installed; git pulls for updates

## Key Implementation Details

**Binary Installation Methods**:
- Linux packages: apt (with sudo)
- macOS: Homebrew
- Neovim on Linux: GitHub releases AppImage (latest, not apt)
- Ghostty on Linux: GitHub releases AppImage (mkasberg/ghostty-ubuntu)
- Go: Official releases from go.dev/dl/
- uv: Official Astral installer script

**Configuration Repos**:
- tmuxfiles: Fixed commit `0dc93fdc1d414e1e14aa29a5cceca9b12ecfc412` with install.sh execution
- neovim-config: Full directory symlink (not single file)
- Both support fetch/checkout for idempotent updates

**Shell Integration**:
- Fish set as default via chsh -s
- Added to /etc/shells if needed
- Scripts assume ~/.local/bin and ~/.cargo/bin in PATH for binaries

## Code Style & Conventions

- **Error handling**: `set -e` at top; explicit error returns from functions; color-coded logging (RED/GREEN/YELLOW)
- **Logging**: `log()`, `warn()`, `error()` functions with [INFO]/[WARN]/[ERROR] prefixes
- **Quoting**: Always quote variables and command substitutions
- **Conditionals**: Use `[[ ]]` (bash-specific) not `[ ]`; check command existence with `command -v`
- **Variables**: lowercase for locals, UPPERCASE for constants (colors)
- **Architecture vars**: Use `$arch` consistently; map aarch64 from both arm64 and aarch64 uname outputs
- **Git ops**: Use `git -C <dir>` to avoid cd; `fetch` + `checkout` for idempotency (not `pull`)
- **Symlinks**: Check `-L` for existing symlinks; use `-sf` (force, follow) for ln
