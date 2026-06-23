#!/usr/bin/env bash
set -euo pipefail

# Define source and destination root variables
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME:-/home/robert}"

echo "🚀 Synchronizing user environment dotfiles from: $DOTFILES_DIR"

# Ensure runtime standard XDG target parent locations exist
mkdir -p "$TARGET_DIR/.config"
mkdir -p "$TARGET_DIR/.local"

# Map target directories and source paths explicitly
declare -A LINKS=(
    ["$TARGET_DIR/.config/foot"]="$DOTFILES_DIR/foot"
    ["$TARGET_DIR/.config/i3status-rust"]="$DOTFILES_DIR/i3status-rust"
    ["$TARGET_DIR/.config/mako"]="$DOTFILES_DIR/mako"
    ["$TARGET_DIR/.config/sway"]="$DOTFILES_DIR/sway"
    ["$TARGET_DIR/.config/gtk-3.0"]="$DOTFILES_DIR/gtk-3.0"
    ["$TARGET_DIR/.local/bin"]="$DOTFILES_DIR/bin"
    ["$TARGET_DIR/.config/kanshi"]="$DOTFILES_DIR/kanshi"
)

for TARGET in "${!LINKS[@]}"; do
    SOURCE="${LINKS[$TARGET]}"

    if [ ! -e "$SOURCE" ]; then
        echo "⚠️  Warning: Source path missing, skipping: $SOURCE"
        continue
    fi

    # Create parent folder context if needed
    mkdir -p "$(dirname "$TARGET")"

    # Clean existing symlinks or empty target stubs to avoid nested bugs
    if [ -L "$TARGET" ] || [ -e "$TARGET" ]; then
        rm -rf "$TARGET"
    fi

    echo "🔗 Linking: $TARGET -> $SOURCE"
    ln -sf "$SOURCE" "$TARGET"
done

echo "✅ Environment sync complete."

