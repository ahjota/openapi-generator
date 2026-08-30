#!/bin/sh
# Install personal dotfiles (github.com/ahjota/dotfiles) via chezmoi.
# Runs non-interactively as postCreateCommand, so the chezmoi config is
# pre-seeded below to skip the usual `chezmoi init` prompts.
set -eu

REPO="ahjota"

# 1. Install chezmoi into ~/.local/bin if it is not already on PATH.
if ! command -v chezmoi >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    curl -fsLS get.chezmoi.io -o /tmp/install-chezmoi.sh
    sh /tmp/install-chezmoi.sh -b "$HOME/.local/bin"
fi
export PATH="$HOME/.local/bin:$PATH"

# 2. Seed the chezmoi data so `chezmoi init` skips its interactive prompts.
#    chezmoi init always regenerates the config from the repo's
#    .chezmoi.toml.tmpl, whose prompt*Once functions look up these exact
#    keys; values found in the data are reused instead of prompting.
#    NOTE: set your real email before the first run.
if [ ! -f "$HOME/.config/chezmoi/chezmoi.toml" ]; then
    mkdir -p "$HOME/.config/chezmoi"
    cat > "$HOME/.config/chezmoi/chezmoi.toml" <<'EOF'
[data]
email = "alexander.joel.alon@gmail.com"
hasDrDev = false
devJava = true
iterm2 = false
EOF
fi

# 3. Clone/refresh the dotfiles and apply them to $HOME.
chezmoi init --apply "$REPO"
