#!/usr/bin/env bash
set -euo pipefail

REPO_SSH="git@github.com:Neicx/dotfiles.git"
REPO_HTTPS="https://github.com/Neicx/dotfiles.git"
DOTFILES="$HOME/dotfiles"
REPO_DIR="${REPO_DIR:-$DOTFILES}"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}[*]${NC} $*"; }
ok()    { echo -e "${GREEN}[+]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
fail()  { echo -e "${RED}[x]${NC} $*"; }

confirm() {
    echo -en "${YELLOW}[?]${NC} $1 [s/N] "
    read -r -n 1 answer
    echo
    [[ "${answer,,}" == "s" ]]
}

PACMAN_PKGS=(
    # WM / core
    hyprland hyprpaper hyprpicker hyprshot hyprland-guiutils
    hypridle hyprlock hyprsunset
    kitty dolphin rofi waybar
    # audio
    pipewire pipewire-pulse wireplumber alsa-utils pavucontrol
    # dependencias de waybar / sistema
    playerctl brightnessctl network-manager-applet blueman
    dunst libnotify termusic neovim
    # fuentes (iconos de waybar)
    ttf-hack-nerd ttf-jetbrains-mono-nerd
    # apps del README
    discord obs-studio libreoffice-fresh obsidian foliate man-db
    # utilidades
    git base-devel unzip
)

AUR_PKGS=(
    bruno
    helium-browser-bin
    nvim-packer-git
    localsend
    kwybars-bin
    spotify
)

check_prereq() {
    if [[ $EUID -eq 0 ]]; then
        fail "No ejecutes este script como root."
        exit 1
    fi
    if ! command -v pacman &>/dev/null; then
        fail "Este script es solo para Arch Linux."
        exit 1
    fi
    if ! command -v sudo &>/dev/null; then
        fail "Necesitas sudo."
        exit 1
    fi
    ok "Comprobaciones correctas."
}

update_system() {
    info "Actualizando sistema..."
    sudo pacman -Syu --noconfirm
    ok "Sistema actualizado."
}

install_pacman() {
    info "Instalando paquetes oficiales..."
    sudo pacman -S --noconfirm --needed "${PACMAN_PKGS[@]}"
    ok "Paquetes oficiales instalados."
}

install_yay() {
    if command -v yay &>/dev/null; then
        ok "yay ya está instalado."
        return
    fi
    info "Instalando yay (AUR helper)..."
    sudo pacman -S --noconfirm --needed base-devel git
    tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    cd "$tmp/yay-bin"
    makepkg -si --noconfirm
    cd /
    rm -rf "$tmp"
    ok "yay instalado."
}

install_aur() {
    info "Instalando paquetes AUR..."
    yay -S --noconfirm --needed "${AUR_PKGS[@]}"
    ok "Paquetes AUR instalados."
}

setup_dotfiles() {
    if [[ -d "$DOTFILES/.git" ]]; then
        info "dotfiles ya existe, actualizando..."
        git -C "$DOTFILES" pull --ff-only || warn "No se pudo hacer pull (revisa tu SSH key)."
        return
    fi
    info "Clonando dotfiles..."
    if git clone "$REPO_SSH" "$DOTFILES"; then
        ok "Clonado vía SSH."
    else
        warn "SSH falló, usando HTTPS..."
        git clone "$REPO_HTTPS" "$DOTFILES"
        ok "Clonado vía HTTPS (configura tu SSH key después para hacer push)."
    fi
}

restore_extras() {
    HYPR_DIR="$REPO_DIR/hypr"
    KITTY_CONF="$REPO_DIR/kitty/kitty.conf"
    KWYBARS_CONF="$REPO_DIR/kwybars/config.toml"

    info "Restaurando extras locales que no están en el repo..."

    cat > "$HYPR_DIR/toggle_touchpad.sh" <<'EOF'
#!/bin/bash

DEVICE="dll07a6:01-044e:120b"
STATE_FILE="/tmp/touchpad_state"

if [ -f "$STATE_FILE" ]; then
    hyprctl keyword "device[$DEVICE]:enabled" true
    rm "$STATE_FILE"
    notify-send "Touchpad" "Activado"
else
    hyprctl keyword "device[$DEVICE]:enabled" false
    touch "$STATE_FILE"
    notify-send "Touchpad" "Bloqueado"
fi
EOF
    chmod +x "$HYPR_DIR/toggle_touchpad.sh"
    ok "toggle_touchpad.sh restaurado."

    if ! grep -q "toggle_touchpad.sh" "$HYPR_DIR/hyprland.conf"; then
        printf '\nbind = $mainMod, T, exec, ~/.config/hypr/toggle_touchpad.sh\n' >> "$HYPR_DIR/hyprland.conf"
        ok "Bind Super+T del touchpad añadido a hyprland.conf."
    else
        ok "Bind del touchpad ya existe."
    fi

    if ! grep -q "confirm_os_window_close" "$KITTY_CONF"; then
        printf '\nconfirm_os_window_close 0\n' >> "$KITTY_CONF"
        ok "confirm_os_window_close 0 añadido a kitty.conf."
    else
        ok "kitty.conf ya tiene confirm_os_window_close."
    fi

    if grep -q "^bars = 30" "$KWYBARS_CONF"; then
        sed -i 's/^bars = 30$/bars = 48/' "$KWYBARS_CONF"
        ok "kwybars configurado con bars = 48."
    else
        ok "kwybars ya tiene tu valor de bars."
    fi

    cat > "$REPO_DIR/.bashrc" <<'EOF'
#
# ~/.bashrc
#
# If not running interactively, don't do anything
[[ $- != *i* ]] && return

eval "$(dircolors ~/.dircolors)"
alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='\[\e[38;5;221m\]\h\[\e[0m\] \[\e[38;5;189m\]\w\[\e[0m\] \[\e[38;5;221m\]❯\[\e[0m\] '

# opencode
export PATH=$HOME/.opencode/bin:$PATH
export PATH="$HOME/flutter/bin:$PATH"

if command -v pyenv >/dev/null 2>&1; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

unzipd() {
  local nombre="${1%.zip}"
  mkdir -p "$nombre" && unzip "$1" -d "$nombre"
}
EOF
    ok ".bashrc restaurado."
}

link_configs() {
    info "Enlazando configs a ~/.config..."
    mkdir -p "$HOME/.config"
    local cfg="$HOME/.config"
    local links=(
        "$REPO_DIR/hypr:$cfg/hypr"
        "$REPO_DIR/kitty:$cfg/kitty"
        "$REPO_DIR/kwybars:$cfg/kwybars"
        "$REPO_DIR/rofi:$cfg/rofi"
        "$REPO_DIR/waybar:$cfg/waybar"
        "$REPO_DIR/.bashrc:$HOME/.bashrc"
        "$REPO_DIR/.dircolors:$HOME/.dircolors"
    )
    for link in "${links[@]}"; do
        local src="${link%%:*}"
        local dst="${link#*:}"
        if [[ -e "$dst" && ! -L "$dst" ]]; then
            warn "$dst ya existe, no se toca."
            continue
        fi
        rm -f "$dst"
        ln -s "$src" "$dst"
        ok "  $dst -> $src"
    done
}

enable_services() {
    info "Habilitando servicios..."
    sudo systemctl enable --now NetworkManager bluetooth 2>/dev/null || true
    systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service 2>/dev/null || true
    ok "Servicios habilitados."
}

summary() {
    echo
    echo -e "${BOLD}=== Resumen ===${NC}"
    echo -e "  1. Cierra sesión y vuelve a entrar (o ejecuta ${BOLD}source ~/.bashrc${NC})."
    echo -e "  2. Inicia Hyprland con: ${BOLD}start-hyprland${NC}"
    echo -e "  3. Si clonaste por HTTPS, configura tu SSH key y:"
    echo -e "       git -C ~/dotfiles remote set-url origin git@github.com:Neicx/dotfiles.git"
    echo -e "  4. Los extras locales (touchpad, kitty, kwybars, .bashrc) quedaron en ~/dotfiles,"
    echo -e "     hazles commit para no perderlos:"
    echo -e "       git -C ~/dotfiles add -A && git -C ~/dotfiles commit"
}

main() {
    check_prereq
    update_system
    install_pacman
    install_yay
    install_aur
    setup_dotfiles
    restore_extras
    link_configs
    enable_services
    summary
}

main
