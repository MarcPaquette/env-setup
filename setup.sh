#!/usr/bin/env bash

set -e

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
    local arch=$(uname -m)
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
    local packages=("curl" "git" "make" "gcc" "bat" "npm")

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

        local download_url=$(curl -s "$release_url" | jq -r ".assets[] | select(.name == \"$asset_name\") | .browser_download_url" | head -1)

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

        local download_url=$(curl -s "$release_url" | grep -o "\"browser_download_url\": \"[^\"]*$asset_name\"" | head -1 | cut -d'"' -f4)

        if [[ -z "$download_url" ]]; then
            error "Could not find Ghostty release for architecture: $arch"
            return 1
        fi

        log "Downloading Ghostty from: $download_url"
        mkdir -p ~/.local/bin
        curl -L "$download_url" -o ~/.local/bin/ghostty
        chmod +x ~/.local/bin/ghostty

        if ! grep -q "$HOME/.local/bin" <<< "$PATH"; then
            warn "~/.local/bin is not in PATH. Add it to your shell configuration."
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

    local go_version=$(curl -s https://go.dev/dl/ | grep -oP 'go\d+\.\d+\.\d+' | head -1 | sed 's/go//')

    if [[ "$os" == "linux" ]]; then
        local tar_name="go${go_version}.linux-${arch}.tar.gz"
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

    log "Go installed successfully. Ensure /usr/local/go/bin is in your PATH"
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

# Setup repositories and symlinks
setup_configurations() {
    local config_dir="$HOME/.dotfiles"

    log "Setting up configuration repositories..."

    mkdir -p "$config_dir"

    # Clone or update tmux configuration
    if [[ -d "$config_dir/tmuxfiles" ]]; then
        log "Updating tmuxfiles..."
        git -C "$config_dir/tmuxfiles" fetch origin
        git -C "$config_dir/tmuxfiles" checkout 0dc93fdc1d414e1e14aa29a5cceca9b12ecfc412
    else
        log "Cloning tmuxfiles..."
        git clone https://github.com/MarcPaquette/tmuxfiles "$config_dir/tmuxfiles"
        git -C "$config_dir/tmuxfiles" checkout 0dc93fdc1d414e1e14aa29a5cceca9b12ecfc412
    fi

    # Run tmuxfiles install script
    if [[ -f "$config_dir/tmuxfiles/install.sh" ]]; then
        log "Running tmuxfiles install script..."
        bash "$config_dir/tmuxfiles/install.sh"
    fi

    # Clone or update neovim configuration
    if [[ -d "$config_dir/neovim-config" ]]; then
        log "Updating neovim-config..."
        git -C "$config_dir/neovim-config" pull
    else
        log "Cloning neovim-config..."
        git clone https://github.com/MarcPaquette/neovim-config "$config_dir/neovim-config"
    fi

    # Setup symlinks
    log "Setting up symlinks..."

    # Tmux configuration
    mkdir -p "$HOME/.config/tmux"
    if [[ ! -L "$HOME/.config/tmux/config" ]]; then
        ln -sf "$config_dir/tmuxfiles" "$HOME/.config/tmux/config"
        log "Linked tmux configuration"
    else
        log "Tmux configuration symlink already exists"
    fi

    # Neovim configuration
    if [[ ! -L "$HOME/.config/nvim" ]]; then
        # Backup existing nvim config if it's a real directory
        if [[ -d "$HOME/.config/nvim" && ! -L "$HOME/.config/nvim" ]]; then
            log "Backing up existing nvim config to ~/.config/nvim.bak"
            mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak"
        fi
        ln -sf "$config_dir/neovim-config" "$HOME/.config/nvim"
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

# Setup Fish aliases
setup_fish_aliases() {
    local fish_aliases_dir="$HOME/.config/fish/conf.d"
    local aliases_file="$fish_aliases_dir/aliases.fish"

    log "Setting up Fish aliases..."

    mkdir -p "$fish_aliases_dir"

    # Create aliases file
    cat > "$aliases_file" << 'EOF'
# Aliases
if command -v batcat &> /dev/null
    alias bat batcat
end
EOF

    log "Fish aliases configured"
}

# Set Fish as default shell
set_fish_default() {
    local fish_path=$(command -v fish)

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

    echo "$fish_path" | sudo chsh -s -
    log "Default shell changed to Fish. Changes will take effect on next login."
}

# Main setup function
main() {
    log "Starting environment setup..."

    local os=$(detect_os)
    local arch=$(detect_arch)

    log "Detected OS: $os"
    log "Detected architecture: $arch"

    install_packages "$os"
    install_fish "$os"
    install_neovim "$os" "$arch"
    install_ghostty "$os" "$arch"
    install_go "$os" "$arch"
    install_uv
    setup_configurations
    setup_fish_aliases
    set_fish_default

    log "Environment setup completed successfully!"
    log "You may need to restart your shell or log out and back in for all changes to take effect."
}

main "$@"
