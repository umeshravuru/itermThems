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
# Check for the app in the standard Applications directory
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
brew install zsh zsh-completions zsh-syntax-highlighting

if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "Oh My Zsh is already installed."
else
    # The official Oh My Zsh install script will handle the .zshrc backup and switch to zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended
fi

echo "Installing Powerlevel9k theme..."
git clone https://github.com/bhilburn/powerlevel9k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel9k

echo "Done setting up Zsh."


# --- Configuration ---
echo "Copying configuration files..."
# -i will prompt before overwriting
cp -i com.googlecode.iterm2.plist ~/Library/Preferences/
cp -i .zshrc ~/

echo ""
echo "--------------------------------------------------"
echo "✅ Setup complete!"
echo ""
echo "🔴 IMPORTANT FINAL STEP:"
echo "To fix the symbols, you must change the font in iTerm2's settings:"
echo "1. Open iTerm2."
echo "2. Go to iTerm2 > Settings (or Preferences) > Profiles."
echo "3. Select your profile (e.g., 'Default')."
echo "4. Go to the 'Text' tab."
echo "5. Under 'Font', click 'Change Font' (or 'Font')."
echo "6. Select a font with 'for Powerline' or 'Nerd Font' in the name (e.g., 'MesloLG Nerd Font', 'Source Code Pro for Powerline')."
echo "7. Restart iTerm2 for all changes to take effect."
echo "--------------------------------------------------"%
