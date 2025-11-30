#!/usr/bin/env bash

set -e
set -u
set -o pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        error "Unsupported OS: $OSTYPE"
        exit 1
    fi
}

# Detect architecture
detect_arch() {
    local arch
    arch=$(uname -m)
    case $arch in
        x86_64)
            echo "x86_64"
            ;;
        aarch64)
            echo "aarch64"
            ;;
        arm64)
            echo "aarch64"
            ;;
        *)
            error "Unsupported architecture: $arch"
            exit 1
            ;;
    esac
}

# Install packages based on OS
install_packages() {
    local os=$1
    local packages=("curl" "git" "make" "gcc" "bat" "npm" "shellcheck" "strace")

    log "Installing core packages..."

    if [[ "$os" == "linux" ]]; then
        if ! command -v apt &> /dev/null; then
            error "apt not found. This script requires apt-based Linux distribution."
            exit 1
        fi

        # Update package lists
        sudo apt update

        for package in "${packages[@]}"; do
            if ! command -v "$package" &> /dev/null; then
                log "Installing $package..."
                sudo apt install -y "$package"
            else
                log "$package is already installed"
            fi
        done

    elif [[ "$os" == "macos" ]]; then
        if ! command -v brew &> /dev/null; then
            error "Homebrew not found. Please install Homebrew first."
            exit 1
        fi

        for package in "${packages[@]}"; do
            if ! brew list "$package" &> /dev/null; then
                log "Installing $package..."
                brew install "$package"
            else
                log "$package is already installed"
            fi
        done
    fi
}

# Install Fish shell
install_fish() {
    local os=$1

    if command -v fish &> /dev/null; then
        log "Fish shell is already installed"
        return
    fi

    log "Installing Fish shell..."

    if [[ "$os" == "linux" ]]; then
        sudo apt install -y fish
    elif [[ "$os" == "macos" ]]; then
        brew install fish
    fi
}

# Install Neovim (latest)
install_neovim() {
    local os=$1
    local arch=$2

    if command -v nvim &> /dev/null; then
        log "Neovim is already installed"
        return
    fi

    log "Installing latest Neovim..."

    if [[ "$os" == "linux" ]]; then
        local release_url="https://api.github.com/repos/neovim/neovim/releases/latest"
        local asset_name=""

        if [[ "$arch" == "x86_64" ]]; then
            asset_name="nvim-linux-x86_64.appimage"
        elif [[ "$arch" == "aarch64" ]]; then
            asset_name="nvim-linux-arm64.appimage"
        fi

        local download_url
        download_url=$(curl -s "$release_url" | jq -r ".assets[] | select(.name == \"$asset_name\") | .browser_download_url" | head -1)

        if [[ -z "$download_url" ]]; then
            error "Could not find Neovim AppImage release"
            return 1
        fi

        log "Downloading Neovim from: $download_url"
        mkdir -p ~/.local/bin
        curl -L "$download_url" -o ~/.local/bin/nvim
        chmod +x ~/.local/bin/nvim

    elif [[ "$os" == "macos" ]]; then
        brew install neovim
    fi
}

# Install Ghostty
install_ghostty() {
    local os=$1
    local arch=$2

    if command -v ghostty &> /dev/null; then
        log "Ghostty is already installed"
        return
    fi

    log "Installing Ghostty..."

    if [[ "$os" == "linux" ]]; then
        local release_url="https://api.github.com/repos/mkasberg/ghostty-ubuntu/releases/latest"
        local asset_name=""

        if [[ "$arch" == "x86_64" ]]; then
            asset_name="ghostty-x86_64.AppImage"
        elif [[ "$arch" == "aarch64" ]]; then
            asset_name="ghostty-aarch64.AppImage"
        fi

        if [[ -z "$asset_name" ]]; then
            error "Unsupported architecture for Ghostty: $arch"
            return 1
        fi

        local download_url
        download_url=$(curl -s "$release_url" | grep -o "\"browser_download_url\": \"[^\"]*$asset_name\"" | head -1 | cut -d'"' -f4)

        if [[ -z "$download_url" ]]; then
            error "Could not find Ghostty release for architecture: $arch"
            return 1
        fi

        log "Downloading Ghostty from: $download_url"
        mkdir -p ~/.local/bin
        curl -L "$download_url" -o ~/.local/bin/ghostty
        chmod +x ~/.local/bin/ghostty

        if ! grep -q "$HOME/.local/bin" <<< "$PATH"; then
            warn "$HOME/.local/bin is not in PATH. Add it to your shell configuration."
        fi

    elif [[ "$os" == "macos" ]]; then
        brew install ghostty
    fi
}

# Install Go (latest)
install_go() {
    local os=$1
    local arch=$2

    if command -v go &> /dev/null; then
        log "Go is already installed"
        return
    fi

    log "Installing latest Go..."

    local go_version
    go_version=$(curl -s https://go.dev/dl/ | grep -oP 'go\d+\.\d+\.\d+' | head -1 | sed 's/go//')

    if [[ "$os" == "linux" ]]; then
        local go_arch="$arch"
        if [[ "$arch" == "x86_64" ]]; then
            go_arch="amd64"
        elif [[ "$arch" == "aarch64" ]]; then
            go_arch="arm64"
        fi
        local tar_name="go${go_version}.linux-${go_arch}.tar.gz"
        local download_url="https://go.dev/dl/$tar_name"

        log "Downloading Go ${go_version}..."
        mkdir -p /tmp/go-install
        curl -L "$download_url" -o /tmp/go-install/"$tar_name"

        log "Extracting Go..."
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf /tmp/go-install/"$tar_name"
        rm /tmp/go-install/"$tar_name"

    elif [[ "$os" == "macos" ]]; then
        brew install go
    fi

    log "Go installed successfully"
}

# Install uv (Python package manager)
install_uv() {
    if command -v uv &> /dev/null; then
        log "uv is already installed"
        return
    fi

    log "Installing uv..."

    curl -LsSf https://astral.sh/uv/install.sh | sh

    log "uv installed successfully. Ensure ~/.cargo/bin is in your PATH"
}

# Install gopls (Go language server)
install_gopls() {
    if command -v gopls &> /dev/null; then
        log "gopls is already installed"
        return
    fi

    log "Installing gopls..."

    if command -v go &> /dev/null; then
        go install github.com/golang/tools/gopls@latest
        log "gopls installed successfully"
    else
        error "Go is required to install gopls"
        return 1
    fi
}

# Setup tmux configuration
setup_tmux() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local tmux_repo_dir="$script_dir/tmuxfiles"
    local tmux_commit="0dc93fdc1d414e1e14aa29a5cceca9b12ecfc412"

    log "Setting up tmux configuration..."

    # Ensure tmuxfiles is at the correct commit
    git -C "$tmux_repo_dir" fetch origin
    git -C "$tmux_repo_dir" checkout "$tmux_commit"
    log "Checked out tmuxfiles commit $tmux_commit"

    # Handle ~/.tmux.conf symlink
    mkdir -p "$HOME/.tmux"
    if [[ -L "$HOME/.tmux.conf" ]]; then
        rm "$HOME/.tmux.conf"
    elif [[ -f "$HOME/.tmux.conf" ]]; then
        log "Backing up existing ~/.tmux.conf to ~/.tmux.conf.bak"
        mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak"
    fi
    ln -sf "$tmux_repo_dir/tmux.conf" "$HOME/.tmux.conf"
    log "Linked tmux configuration to ~/.tmux.conf"

    # Run install script
    if [[ -x "$tmux_repo_dir/install" ]]; then
        bash "$tmux_repo_dir/install"
        log "Executed tmuxfiles install script"
    else
        error "tmuxfiles install script not found or not executable"
        return 1
    fi
}

# Setup repositories and symlinks
setup_configurations() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    log "Setting up configuration symlinks..."

    # Neovim configuration
    if [[ ! -L "$HOME/.config/nvim" ]]; then
        # Backup existing nvim config if it's a real directory
        if [[ -d "$HOME/.config/nvim" && ! -L "$HOME/.config/nvim" ]]; then
            log "Backing up existing nvim config to ~/.config/nvim.bak"
            mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak"
        fi
        ln -sf "$script_dir/neovim-config" "$HOME/.config/nvim"
        log "Linked neovim configuration"
    else
        log "Neovim configuration symlink already exists"
    fi

    # Fish configuration directory (will be used for future dotfiles)
    mkdir -p "$HOME/.config/fish/conf.d"
    log "Fish configuration directory ready at ~/.config/fish"

    # Ghostty configuration
    mkdir -p "$HOME/.config/ghostty"
    if [[ -f "$(pwd)/ghostty-config" ]]; then
        cp "$(pwd)/ghostty-config" "$HOME/.config/ghostty/config"
        log "Ghostty configuration installed"
    fi
}

# Setup Fish aliases and PATH
setup_fish_aliases() {
    local fish_aliases_dir="$HOME/.config/fish/conf.d"
    local aliases_file="$fish_aliases_dir/aliases.fish"

    log "Setting up Fish aliases and PATH..."

    mkdir -p "$fish_aliases_dir"

    # Create aliases file
    cat > "$aliases_file" << 'EOF'
# Aliases
if command -v batcat &> /dev/null
    alias bat batcat
end

# Add Go to PATH
if test -d /usr/local/go/bin
    set -gx PATH /usr/local/go/bin $PATH
end

# Add cargo to PATH
if test -d "$HOME/.cargo/bin"
    set -gx PATH "$HOME/.cargo/bin" $PATH
end

# Add local bin to PATH
if test -d "$HOME/.local/bin"
    set -gx PATH "$HOME/.local/bin" $PATH
end
EOF

    log "Fish aliases and PATH configured"
}

# Setup Python virtual environment
setup_python_venv() {
    local venv_dir="$HOME/.venv"
    local fish_venv_file="$HOME/.config/fish/conf.d/venv.fish"

    log "Setting up Python virtual environment..."

    # Create venv if it doesn't exist
    if [[ ! -d "$venv_dir" ]]; then
        if command -v python3 &> /dev/null; then
            python3 -m venv "$venv_dir"
            log "Created Python venv at $venv_dir"
        else
            error "Python3 is required to create venv"
            return 1
        fi
    else
        log "Python venv already exists at $venv_dir"
    fi

    # Create Fish configuration to auto-source venv
    mkdir -p "$HOME/.config/fish/conf.d"
    cat > "$fish_venv_file" << 'EOF'
# Auto-activate Python venv if it exists
if test -f "$HOME/.venv/bin/activate.fish"
    source "$HOME/.venv/bin/activate.fish"
end
EOF

    log "Fish venv auto-activation configured"
}

# Install and setup bash-git-prompt for Fish
setup_bash_git_prompt() {
    local bash_git_prompt_dir="$HOME/.bash-git-prompt"
    local fish_prompt_file="$HOME/.config/fish/conf.d/git_prompt.fish"

    log "Setting up bash-git-prompt for Fish..."

    # Clone or update bash-git-prompt repository
    if [[ -d "$bash_git_prompt_dir" ]]; then
        log "Updating bash-git-prompt..."
        git -C "$bash_git_prompt_dir" fetch origin
        git -C "$bash_git_prompt_dir" checkout master
    else
        log "Cloning bash-git-prompt..."
        git clone https://github.com/magicmonty/bash-git-prompt.git "$bash_git_prompt_dir"
    fi

    # Copy gitprompt.fish to Fish configuration
    mkdir -p "$HOME/.config/fish/conf.d"
    cp "$bash_git_prompt_dir/gitprompt.fish" "$fish_prompt_file"
    log "Installed bash-git-prompt for Fish"
}

# Set Fish as default shell
set_fish_default() {
    local fish_path
    fish_path=$(command -v fish)

    if [[ "$SHELL" == "$fish_path" ]]; then
        log "Fish is already the default shell"
        return
    fi

    log "Setting Fish as default shell..."

    # Check if fish is in /etc/shells
    if ! grep -q "$fish_path" /etc/shells; then
        log "Adding Fish to /etc/shells..."
        echo "$fish_path" | sudo tee -a /etc/shells > /dev/null
    fi

    chsh -s "$fish_path"
    log "Default shell changed to Fish. Changes will take effect on next login."
}

# Main setup function
main() {
    log "Starting environment setup..."

    local os
    os=$(detect_os)
    local arch
    arch=$(detect_arch)

    log "Detected OS: $os"
    log "Detected architecture: $arch"

    install_packages "$os"
    install_fish "$os"
    install_neovim "$os" "$arch"
    install_ghostty "$os" "$arch"
    install_go "$os" "$arch"
    install_uv
    # install_gopls
    setup_configurations
    setup_tmux
    setup_fish_aliases
    setup_python_venv
    setup_bash_git_prompt
    set_fish_default

    log "Environment setup completed successfully!"
    log "You may need to restart your shell or log out and back in for all changes to take effect."
}

main "$@"
