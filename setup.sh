#!/usr/bin/env bash

# ==============================================================================
# Mac Setup & Restore Script - DalPra0
# Este script restaura todos os seus aplicativos, CLI tools, dotfiles,
# perfil do Zen Browser, Raycast e projetos no seu Mac recém-formatado.
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

PENDING_INSTALLS=()

add_pending_install() {
    local item="$1"
    local existing
    for existing in "${PENDING_INSTALLS[@]}"; do
        [[ "$existing" == "$item" ]] && return 0
    done
    PENDING_INSTALLS+=("$item")
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICLOUD_BACKUP="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Backup_Mac_Formatacao"

echo ""
echo "${BOLD}====================================================${RESET}"
echo "${BOLD}     Iniciando Restauração Automatizada do Mac      ${RESET}"
echo "${BOLD}====================================================${RESET}"
echo ""

info "Este processo vai instalar pacotes, apps, ajustar preferências e restaurar dados do iCloud."
read -r -p "Deseja continuar? [y/N]: " CONFIRM_SETUP
if [[ ! "$CONFIRM_SETUP" =~ ^[Yy]$ ]]; then
    warn "Restauração cancelada pelo usuário."
    exit 0
fi

info "Solicitando permissões de administrador no início para evitar interrupções no meio do processo..."
sudo -v
while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
done 2>/dev/null &

# 1. Verificar Xcode Command Line Tools
info "Verificando Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
    info "Instalando Xcode Command Line Tools..."
    xcode-select --install || true
    info "Aguardando conclusão da instalação do Xcode Command Line Tools..."
    until xcode-select -p &>/dev/null; do
        sleep 5
    done
    success "Xcode Command Line Tools instalado."
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

# 3. Atualizar Homebrew e Instalar Brewfile (incluindo Raycast, Zen, Cursor, etc.)
info "Instalando todos os aplicativos, CLI tools e casks via Brewfile..."
brew update
if [[ -f "$SCRIPT_DIR/Brewfile" ]]; then
    if brew bundle --file="$SCRIPT_DIR/Brewfile"; then
        success "Aplicativos e pacotes instalados com sucesso!"
    else
        warn "brew bundle encontrou erros. Revise os itens com falha acima e rode novamente após corrigir."
    fi

    BREW_CHECK_OUTPUT="$(brew bundle check --file="$SCRIPT_DIR/Brewfile" --verbose 2>&1 || true)"
    while IFS= read -r line; do
        if [[ "$line" == *" is not installed." || "$line" == *" is not tapped." ]]; then
            add_pending_install "$line"
        fi
    done <<< "$BREW_CHECK_OUTPUT"
else
    warn "Brewfile não encontrado em $SCRIPT_DIR/Brewfile"
    add_pending_install "Brewfile não encontrado em $SCRIPT_DIR/Brewfile"
fi

# 4. Instalar Oh My Zsh (opcional)
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Instalando Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        success "Oh My Zsh instalado."
    else
        warn "Falha ao instalar Oh My Zsh."
        add_pending_install "Oh My Zsh"
    fi
fi

# 4.1 Instalar plugins externos do Oh My Zsh
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    info "Verificando plugins externos do Oh My Zsh..."
    ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    mkdir -p "$ZSH_CUSTOM_DIR/plugins"

    install_omz_plugin() {
        local name="$1"
        local repo="$2"
        local target="$ZSH_CUSTOM_DIR/plugins/$name"
        if [[ -d "$target" ]]; then
            success "Plugin já presente: $name"
        elif command -v git &>/dev/null; then
            if git clone --depth 1 "$repo" "$target"; then
                success "Plugin instalado: $name"
            else
                warn "Falha ao instalar plugin $name de $repo"
                add_pending_install "Plugin Oh My Zsh: $name"
                return 1
            fi
        else
            warn "Git não encontrado. Não foi possível instalar plugin $name"
            add_pending_install "Plugin Oh My Zsh: $name (git ausente)"
            return 1
        fi
    }

    install_omz_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
    install_omz_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"
    install_omz_plugin "zsh-history-substring-search" "https://github.com/zsh-users/zsh-history-substring-search"
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

        ZEN_BACKUP_DIR="$ICLOUD_BACKUP/ZenBrowser"
        ZEN_DEST_UPPER="$HOME/Library/Application Support/Zen"
        ZEN_DEST_LOWER="$HOME/Library/Application Support/zen"
        ZEN_FIRST_ITEM="$(find "$ZEN_BACKUP_DIR" -mindepth 1 -print -quit)"

        if [[ -z "$ZEN_FIRST_ITEM" ]]; then
            warn "Backup do Zen foi encontrado, mas está vazio: $ZEN_BACKUP_DIR"
        else
            if [[ -d "$ZEN_DEST_LOWER" ]]; then
                ZEN_DEST="$ZEN_DEST_LOWER"
            else
                ZEN_DEST="$ZEN_DEST_UPPER"
            fi

            mkdir -p "$ZEN_DEST"
            info "Origem Zen: $ZEN_BACKUP_DIR"
            info "Destino Zen: $ZEN_DEST"

            if rsync -avh --progress --stats --partial --timeout=120 "$ZEN_BACKUP_DIR/" "$ZEN_DEST/"; then
                success "Perfil do Zen Browser restaurado com sucesso!"
            else
                warn "A restauração do Zen falhou ou atingiu timeout (120s sem transferência). Tente novamente com o iCloud totalmente sincronizado e o Zen fechado."
            fi
        fi
    fi

    # 6.2 Restaurar Raycast (Extensões, Atalhos, IA, Snippets)
    if [[ -d "$ICLOUD_BACKUP/Raycast" ]]; then
        info "Restaurando dados e extensoes do Raycast..."
        if [[ -d "$ICLOUD_BACKUP/Raycast/ApplicationSupport" ]]; then
            mkdir -p "$HOME/Library/Application Support/com.raycast.macos"
            rsync -av "$ICLOUD_BACKUP/Raycast/ApplicationSupport/" "$HOME/Library/Application Support/com.raycast.macos/"
        fi
        if [[ -d "$ICLOUD_BACKUP/Raycast/config" ]]; then
            mkdir -p "$HOME/.config/raycast"
            rsync -av "$ICLOUD_BACKUP/Raycast/config/" "$HOME/.config/raycast/"
        fi
        success "Dados do Raycast restaurados com sucesso!"
    fi

    # 6.3 Restaurar Pasta Developer
    if [[ -d "$ICLOUD_BACKUP/Developer" ]]; then
        info "Restaurando pasta Developer (projetos)..."
        mkdir -p "$HOME/Developer"
        rsync -av "$ICLOUD_BACKUP/Developer/" "$HOME/Developer/"
        success "Pasta Developer restaurada!"
    fi

    # 6.4 Restaurar Projetos IDEs
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

# 7. Instalar Antigravity CLI e App
info "Instalando Antigravity CLI..."
if ! command -v agy &>/dev/null; then
    if curl -fsSL https://antigravity.google.com/install.sh | bash; then
        success "Antigravity CLI instalado."
    else
        warn "Falha ao instalar Antigravity CLI."
        add_pending_install "Antigravity CLI (agy)"
    fi
fi

if ! command -v agy &>/dev/null; then
    add_pending_install "Antigravity CLI (agy)"
fi

# 8. Preferências Customizadas do macOS
info "Aplicando preferências recomendadas do macOS..."
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write com.apple.finder CreateDesktop -bool true

killall Finder &>/dev/null || true

echo ""
if [[ ${#PENDING_INSTALLS[@]} -gt 0 ]]; then
    warn "Os seguintes itens NÃO foram instalados/configurados:"
    for item in "${PENDING_INSTALLS[@]}"; do
        echo " - $item"
    done
else
    success "Nenhum item pendente de instalação foi detectado."
fi

echo ""
echo "${GREEN}${BOLD}====================================================${RESET}"
echo "${GREEN}${BOLD}      Restauração Concluída com Sucesso!            ${RESET}"
echo "${GREEN}${BOLD}====================================================${RESET}"
echo ""
