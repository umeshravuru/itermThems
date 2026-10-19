#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting the script"

# --- Detect chip and locate the matching Homebrew ---
# Apple Silicon Homebrew lives in /opt/homebrew; Intel Homebrew in /usr/local.
# An Intel brew running under Rosetta on an arm64 Mac cannot use prebuilt
# bottles, so it falls back to compiling from source -- slow, and it fails
# outright on networks that block the GNU source mirrors. Prefer the native
# prefix, and fall back to prebuilt binaries when brew is unusable.
ARCH="$(uname -m)"
echo "Detected architecture: $ARCH"

if [ "$ARCH" = "arm64" ]; then
    NATIVE_BREW="/opt/homebrew/bin/brew"
    NATIVE_LABEL="Apple Silicon"
else
    NATIVE_BREW="/usr/local/bin/brew"
    NATIVE_LABEL="Intel"
fi

BREW=""
if [ -x "$NATIVE_BREW" ]; then
    echo "Found native $NATIVE_LABEL Homebrew at $NATIVE_BREW"
    BREW="$NATIVE_BREW"
else
    echo "No native $NATIVE_LABEL Homebrew at $NATIVE_BREW."
    # Only try to install if we can actually write the prefix. The official
    # installer needs admin rights and refuses to run under sudo.
    BREW_PREFIX="$(dirname "$(dirname "$NATIVE_BREW")")"
    if [ -w "$(dirname "$BREW_PREFIX")" ] || [ -w "$BREW_PREFIX" ]; then
        echo "Installing native Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        [ -x "$NATIVE_BREW" ] && BREW="$NATIVE_BREW"
    else
        echo "Cannot install to $BREW_PREFIX (needs admin rights)."
    fi
fi

# A non-native brew (e.g. Intel brew under Rosetta) is worse than no brew for
# our purposes, so we deliberately do not fall back to it.
if [ -z "$BREW" ]; then
    if command -v brew &> /dev/null; then
        echo "NOTE: a non-native Homebrew exists at $(command -v brew)."
        echo "      Ignoring it -- it would compile from source instead of"
        echo "      using prebuilt bottles."
    fi
    echo "Will install tools as prebuilt binaries instead."
fi

# Everything we install without brew goes here. Put it on PATH for the rest of
# this script too, so the "already installed?" checks below can see it.
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"
export PATH="$LOCAL_BIN:$PATH"

# --- iTerm2 Installation ---
echo ""
echo "Checking if iTerm2 is installed..."
if [ -d "/Applications/iTerm.app" ]; then
    echo "iTerm2 is already installed. Skipping installation."
elif [ -n "$BREW" ]; then
    echo "iTerm2 not found. Installing..."
    "$BREW" install --cask iterm2
    echo "Done installing iTerm2."
else
    echo "iTerm2 not found and Homebrew is unavailable."
    echo "Please install it manually from https://iterm2.com/downloads.html"
fi

# --- Install Nerd Fonts ---
echo ""
echo "Installing Nerd Fonts..."
./fonts_mine/install.sh
echo "Done installing fonts."

# --- Shell tooling ---
echo ""
if [ -n "$BREW" ]; then
    # zsh-syntax-highlighting is cloned as an oh-my-zsh plugin below, so it is
    # not installed here.
    echo "Installing shell tools via Homebrew..."
    "$BREW" install zsh zsh-completions fzf starship
else
    # macOS already ships a native zsh, so only starship and fzf are needed.
    echo "Using the system zsh: $(/bin/zsh --version)"

    if command -v starship &> /dev/null; then
        echo "starship already installed. Skipping."
    else
        echo "Installing starship (prebuilt binary)..."
        case "$ARCH" in
            arm64) STARSHIP_TARGET="aarch64-apple-darwin" ;;
            *)     STARSHIP_TARGET="x86_64-apple-darwin" ;;
        esac
        TMPDIR_STARSHIP="$(mktemp -d)"
        curl -fsSL -o "$TMPDIR_STARSHIP/starship.tar.gz" \
            "https://github.com/starship/starship/releases/latest/download/starship-${STARSHIP_TARGET}.tar.gz"
        tar xzf "$TMPDIR_STARSHIP/starship.tar.gz" -C "$TMPDIR_STARSHIP"
        mv "$TMPDIR_STARSHIP/starship" "$LOCAL_BIN/"
        rm -rf "$TMPDIR_STARSHIP"
        echo "Installed starship to $LOCAL_BIN"
    fi

    if command -v fzf &> /dev/null; then
        echo "fzf already installed. Skipping."
    else
        echo "Installing fzf (prebuilt binary)..."
        case "$ARCH" in
            arm64) FZF_TARGET="darwin_arm64" ;;
            *)     FZF_TARGET="darwin_amd64" ;;
        esac
        FZF_VER="$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest \
            | sed -n 's/.*"tag_name" *: *"v\{0,1\}\([^"]*\)".*/\1/p' | head -1)"
        TMPDIR_FZF="$(mktemp -d)"
        curl -fsSL -o "$TMPDIR_FZF/fzf.tar.gz" \
            "https://github.com/junegunn/fzf/releases/download/v${FZF_VER}/fzf-${FZF_VER}-${FZF_TARGET}.tar.gz"
        tar xzf "$TMPDIR_FZF/fzf.tar.gz" -C "$TMPDIR_FZF"
        mv "$TMPDIR_FZF/fzf" "$LOCAL_BIN/"
        rm -rf "$TMPDIR_FZF"
        echo "Installed fzf $FZF_VER to $LOCAL_BIN"
    fi
fi

# --- Oh My Zsh ---
echo ""
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "Oh My Zsh is already installed."
else
    echo "Installing Oh My Zsh..."
    # KEEP_ZSHRC stops the installer replacing the .zshrc we copy in below.
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    echo "Installing $plugin plugin..."
    if [ -d "$ZSH_CUSTOM/plugins/$plugin" ]; then
        echo "$plugin already installed."
    else
        git clone --depth=1 "https://github.com/zsh-users/$plugin" "$ZSH_CUSTOM/plugins/$plugin"
    fi
done

echo "Done setting up Zsh."

# --- Configuration ---
echo ""
echo "Copying configuration files..."

# Back up anything we are about to replace, then copy unconditionally. Using
# "cp -i" here would abort the whole script under "set -e" if the user
# declined a prompt, skipping every step that follows.
backup_and_copy() {
    src="$1"
    dest="$2"
    if [ -e "$dest" ]; then
        if cmp -s "$src" "$dest"; then
            echo "  $dest already up to date."
            return
        fi
        backup="$dest.backup.$(date +%Y%m%d-%H%M%S)"
        cp "$dest" "$backup"
        echo "  Backed up existing $dest -> $backup"
    fi
    cp "$src" "$dest"
    echo "  Installed $dest"
}

# When running without Homebrew we add a PATH line to ~/.zshrc below, so the
# installed copy is intentionally not identical to the repo one. Compare
# against the repo file with that line stripped, to stay idempotent.
ZSHRC_MATCHES=false
if [ -f "$HOME/.zshrc" ] && \
   grep -v 'local/bin\|^# --- Local binaries' "$HOME/.zshrc" | grep -v '^$' \
   | cmp -s - <(grep -v '^$' .zshrc); then
    ZSHRC_MATCHES=true
fi

if [ "$ZSHRC_MATCHES" = true ]; then
    echo "  $HOME/.zshrc already up to date."
else
    backup_and_copy .zshrc "$HOME/.zshrc"
fi

mkdir -p ~/.config
backup_and_copy starship.toml "$HOME/.config/starship.toml"

# Make sure the shell can find binaries installed outside Homebrew. This must
# be PREPENDED: .zshrc runs "starship init" partway down, so appending the
# PATH export would come too late and the prompt would fail to load.
if [ -z "$BREW" ] && ! grep -q '.local/bin' ~/.zshrc 2>/dev/null; then
    {
        printf '# --- Local binaries (starship, fzf) ---\nexport PATH="$HOME/.local/bin:$PATH"\n\n'
        cat ~/.zshrc
    } > ~/.zshrc.tmp && mv ~/.zshrc.tmp ~/.zshrc
    echo "Added ~/.local/bin to PATH in ~/.zshrc"
fi

# iTerm2 holds its preferences in memory and writes them out on quit, so
# copying the plist while it is running would be silently undone.
echo ""
if pgrep -x iTerm2 > /dev/null; then
    echo "⚠️  iTerm2 is running -- NOT copying the preferences file."
    echo "   Quit iTerm2 (Cmd-Q) and then run:"
    echo "     cp com.googlecode.iterm2.plist ~/Library/Preferences/"
else
    backup_and_copy com.googlecode.iterm2.plist \
        "$HOME/Library/Preferences/com.googlecode.iterm2.plist"
fi

echo ""
echo "--------------------------------------------------"
echo "✅ Setup complete!"
echo ""
echo "🔴 IMPORTANT FINAL STEP:"
echo "For icons to render correctly, set your iTerm2 font to a Nerd Font:"
echo "1. Open iTerm2."
echo "2. Go to iTerm2 > Settings > Profiles > Text."
echo "3. Under 'Font', select a Nerd Font (e.g. 'MesloLGS NF' or 'JetBrainsMono Nerd Font')."
echo "4. Restart iTerm2."
echo "--------------------------------------------------"
