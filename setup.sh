#!/usr/bin/env bash

# ==============================================================================
# Mac Setup & Restore Script - DalPra0
# Este script restaura todos os seus aplicativos, CLI tools, dotfiles,
# perfil do Zen Browser e projetos no seu Mac recém-formatado.
# ==============================================================================

set -e

# Cores para logs
BOLD="$(tput bold 2>/dev/null || echo '')"
GREEN="$(tput setaf 2 2>/dev/null || echo '')"
YELLOW="$(tput setaf 3 2>/dev/null || echo '')"
BLUE="$(tput setaf 4 2>/dev/null || echo '')"
RESET="$(tput sgr0 2>/dev/null || echo '')"

info() { echo "${BLUE}${BOLD}[INFO]${RESET} $1"; }
success() { echo "${GREEN}${BOLD}[OK]${RESET} $1"; }
warn() { echo "${YELLOW}${BOLD}[AVISO]${RESET} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICLOUD_BACKUP="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Backup_Mac_Formatacao"

echo ""
echo "${BOLD}====================================================${RESET}"
echo "${BOLD}     Iniciando Restauração Automatizada do Mac      ${RESET}"
echo "${BOLD}====================================================${RESET}"
echo ""

# 1. Verificar Xcode Command Line Tools
info "Verificando Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
    info "Instalando Xcode Command Line Tools..."
    xcode-select --install
    echo "Pressione ENTER após terminar a instalação da janela do Xcode..."
    read -r
else
    success "Xcode Command Line Tools já instalado."
fi

# 2. Verificar Homebrew
info "Verificando Homebrew..."
if ! command -v brew &>/dev/null; then
    info "Instalando Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    success "Homebrew já instalado."
fi

# 3. Atualizar Homebrew e Instalar Brewfile
info "Instalando todos os aplicativos, CLI tools e casks via Brewfile..."
brew update
if [[ -f "$SCRIPT_DIR/Brewfile" ]]; then
    brew bundle --file="$SCRIPT_DIR/Brewfile" || warn "Alguns pacotes podem ter tido avisos durante a instalação."
    success "Aplicativos e pacotes instalados com sucesso!"
else
    warn "Brewfile não encontrado em $SCRIPT_DIR/Brewfile"
fi

# 4. Instalar Oh My Zsh (opcional)
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Instalando Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
    success "Oh My Zsh instalado."
fi

# 5. Restaurar Dotfiles & Configurações de Aplicativos
info "Restaurando arquivos de configuração (dotfiles)..."
mkdir -p "$HOME/.config"

restore_file() {
    local src="$1"
    local dest="$2"

    if [[ -f "$src" ]]; then
        if [[ -f "$dest" || -L "$dest" ]]; then
            mv "$dest" "${dest}.bak.$(date +%Y%m%d%H%M%S)"
        fi
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        success "Restaurado: $dest"
    fi
}

restore_dir() {
    local src_dir="$1"
    local dest_dir="$2"

    if [[ -d "$src_dir" ]]; then
        mkdir -p "$dest_dir"
        cp -R "$src_dir/"* "$dest_dir/" 2>/dev/null || true
        success "Restaurado diretório: $dest_dir"
    fi
}

# Restaurar Shell & Git
restore_file "$SCRIPT_DIR/shell/.zshrc" "$HOME/.zshrc"
restore_file "$SCRIPT_DIR/shell/.bash_profile" "$HOME/.bash_profile"
restore_file "$SCRIPT_DIR/shell/.bashrc" "$HOME/.bashrc"
restore_file "$SCRIPT_DIR/git/.gitconfig" "$HOME/.gitconfig"

# Restaurar .config apps
restore_dir "$SCRIPT_DIR/config/fastfetch" "$HOME/.config/fastfetch"
restore_dir "$SCRIPT_DIR/config/karabiner" "$HOME/.config/karabiner"
restore_dir "$SCRIPT_DIR/config/spotify-player" "$HOME/.config/spotify-player"
restore_dir "$SCRIPT_DIR/config/zed" "$HOME/.config/zed"
restore_dir "$SCRIPT_DIR/config/aerospace" "$HOME/.config/aerospace"

# 6. Restaurar Backup do iCloud se disponível
if [[ -d "$ICLOUD_BACKUP" ]]; then
    info "Encontrado backup do iCloud Drive em $ICLOUD_BACKUP!"

    # 6.1 Restaurar Perfil do Zen Browser
    if [[ -d "$ICLOUD_BACKUP/ZenBrowser" ]]; then
        info "Restaurando perfil completo do Zen Browser (abas, favoritos, senhas)..."
        mkdir -p "$HOME/Library/Application Support/Zen"
        rsync -av "$ICLOUD_BACKUP/ZenBrowser/" "$HOME/Library/Application Support/Zen/"
        success "Perfil do Zen Browser restaurado com sucesso!"
    fi

    # 6.2 Restaurar Pasta Developer
    if [[ -d "$ICLOUD_BACKUP/Developer" ]]; then
        info "Restaurando pasta Developer (projetos)..."
        mkdir -p "$HOME/Developer"
        rsync -av "$ICLOUD_BACKUP/Developer/" "$HOME/Developer/"
        success "Pasta Developer restaurada!"
    fi

    # 6.3 Restaurar Projetos IDEs
    if [[ -d "$ICLOUD_BACKUP/Projetos_IDEs" ]]; then
        info "Restaurando projetos de IDEs (CLion, IntelliJ, PyCharm)..."
        for ide_folder in "$ICLOUD_BACKUP/Projetos_IDEs/"*; do
            if [[ -d "$ide_folder" ]]; then
                ide_name=$(basename "$ide_folder")
                mkdir -p "$HOME/$ide_name"
                rsync -av "$ide_folder/" "$HOME/$ide_name/"
            fi
        done
        success "Projetos de IDEs restaurados!"
    fi
else
    warn "Nenhum backup automático do iCloud foi detectado ainda. Você pode sincronizar o iCloud Drive mais tarde."
fi

# 7. Preferências Customizadas do macOS
info "Aplicando preferências recomendadas do macOS..."
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write com.apple.finder CreateDesktop -bool true

killall Finder &>/dev/null || true

echo ""
echo "${GREEN}${BOLD}====================================================${RESET}"
echo "${GREEN}${BOLD}      Restauração Concluída com Sucesso!            ${RESET}"
echo "${GREEN}${BOLD}====================================================${RESET}"
echo ""
echo "Próximos passos recomendados:"
echo " 1. Se você fez backup das chaves SSH em iCloud/Seguranca/chaves_ssh_privadas.zip, descompacte-as em ~/.ssh/"
echo " 2. Reinicie o terminal ou execute: source ~/.zshrc"
echo " 3. Seu Zen Browser já foi restaurado com suas abas e senhas!"
echo ""
