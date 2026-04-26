#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting the script"

# --- Homebrew Installation ---
echo "Checking if Homebrew is installed..."
if command -v brew &> /dev/null; then
    echo "Homebrew is already installed. Skipping installation."
else
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "Done installing Homebrew."
fi

# --- iTerm2 Installation ---
echo "Checking if iTerm2 is installed..."
if [ -d "/Applications/iTerm.app" ]; then
    echo "iTerm2 is already installed. Skipping installation."
else
    echo "iTerm2 not found. Installing..."
    brew install --cask iterm2
    echo "Done installing iTerm2."
fi

# --- Install Powerline Fonts ---
echo "Installing Powerline fonts..."
./fonts_mine/install.sh
echo "Done installing Powerline fonts."


# --- Zsh and Oh My Zsh Setup ---
echo "Installing Zsh and related tools..."
brew install zsh zsh-completions zsh-syntax-highlighting fzf

if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "Oh My Zsh is already installed."
else
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended
fi

echo "Installing Powerlevel10k theme..."
if [ -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    echo "Powerlevel10k already installed."
else
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
fi

echo "Installing zsh-autosuggestions plugin..."
if [ -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    echo "zsh-autosuggestions already installed."
else
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

echo "Installing zsh-syntax-highlighting plugin..."
if [ -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
    echo "zsh-syntax-highlighting already installed."
else
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

echo "Done setting up Zsh."


# --- Configuration ---
echo "Copying configuration files..."
cp -i com.googlecode.iterm2.plist ~/Library/Preferences/
cp -i .zshrc ~/
cp -i .p10k.zsh ~/

echo ""
echo "--------------------------------------------------"
echo "✅ Setup complete!"
echo ""
echo "🔴 IMPORTANT FINAL STEP:"
echo "For the best experience, set your iTerm2 font to a Nerd Font:"
echo "1. Open iTerm2."
echo "2. Go to iTerm2 > Settings > Profiles > Text."
echo "3. Under 'Font', select a Nerd Font (e.g. 'MesloLGS NF' or 'JetBrainsMono Nerd Font')."
echo "4. Restart iTerm2."
echo "--------------------------------------------------"
