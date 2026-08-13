#!/usr/bin/env bash

# ==============================================================================
# Script de Backup Organizado para o iCloud Drive
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

ICLOUD_ROOT="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
BACKUP_DIR="$ICLOUD_ROOT/Backup_Mac_Formatacao"

if [[ ! -d "$ICLOUD_ROOT" ]]; then
    echo "❌ Erro: iCloud Drive não está acessível em $ICLOUD_ROOT"
    exit 1
fi

echo ""
echo "${BOLD}====================================================${RESET}"
echo "${BOLD}   Iniciando Backup Organizado no iCloud Drive     ${RESET}"
echo "${BOLD}====================================================${RESET}"
echo "Destino: $BACKUP_DIR"
echo ""

mkdir -p "$BACKUP_DIR"/{Developer,ZenBrowser,Raycast,Projetos_IDEs,Dotfiles,Seguranca,OutrasPastas}

# 1. Backup do Zen Browser (Perfil, Abas, Senhas, Extensões)
info "1/6 Backup do Zen Browser (Perfil completo, senhas, abas)..."
ZEN_SRC_UPPER="$HOME/Library/Application Support/Zen"
ZEN_SRC_LOWER="$HOME/Library/Application Support/zen"
if [[ -d "$ZEN_SRC_LOWER" ]]; then
    ZEN_SRC="$ZEN_SRC_LOWER"
else
    ZEN_SRC="$ZEN_SRC_UPPER"
fi
if [[ -d "$ZEN_SRC" ]]; then
    info "Origem Zen detectada em: $ZEN_SRC"
    rsync -av --progress --exclude="Cache*" --exclude="Crash Reports" "$ZEN_SRC/" "$BACKUP_DIR/ZenBrowser/"
    success "Zen Browser salvo no iCloud!"
else
    warn "Diretório do Zen Browser não encontrado."
fi

# 2. Backup do Raycast (Extensões, Atalhos, Ajustes de IA e Dados)
info "2/6 Backup do Raycast (Extensões, Atalhos, Snippets, IA)..."
RAYCAST_APP_SUP="$HOME/Library/Application Support/com.raycast.macos"
RAYCAST_CONF="$HOME/.config/raycast"
mkdir -p "$BACKUP_DIR/Raycast/ApplicationSupport" "$BACKUP_DIR/Raycast/config"

if [[ -d "$RAYCAST_APP_SUP" ]]; then
    rsync -av --progress "$RAYCAST_APP_SUP/" "$BACKUP_DIR/Raycast/ApplicationSupport/"
fi
if [[ -d "$RAYCAST_CONF" ]]; then
    rsync -av --progress "$RAYCAST_CONF/" "$BACKUP_DIR/Raycast/config/"
fi
success "Raycast completo salvo no iCloud!"

# 3. Backup da Pasta Developer (ignorando arquivos temporários/pesados)
info "3/6 Backup da pasta Developer (Projetos de Código)..."
DEV_SRC="$HOME/Developer"
if [[ -d "$DEV_SRC" ]]; then
    rsync -av --progress \
        --exclude="node_modules" \
        --exclude=".venv" \
        --exclude="venv" \
        --exclude=".build" \
        --exclude="DerivedData" \
        --exclude=".next" \
        --exclude="dist" \
        --exclude="target" \
        --exclude=".DS_Store" \
        "$DEV_SRC/" "$BACKUP_DIR/Developer/"
    success "Pasta Developer salva no iCloud!"
fi

# 4. Backup dos Projetos de IDEs (CLion, Idea, PyCharm)
info "4/6 Backup de projetos CLion, IntelliJ e PyCharm..."
for ide_dir in "$HOME/IdeaProjects" "$HOME/CLionProjects" "$HOME/PycharmProjects" "$HOME/PyCharmMiscProject"; do
    if [[ -d "$ide_dir" ]]; then
        dirname=$(basename "$ide_dir")
        rsync -av --progress \
            --exclude="node_modules" \
            --exclude=".venv" \
            --exclude="target" \
            --exclude=".build" \
            "$ide_dir/" "$BACKUP_DIR/Projetos_IDEs/$dirname/"
    fi
done
success "Projetos de IDEs salvos no iCloud!"

# 5. Backup do Repositório de Dotfiles & Brewfile
info "5/6 Copiando repositório de Dotfiles para o iCloud..."
DOTFILES_SRC="$HOME/.gemini/antigravity/scratch/dotfiles"
if [[ -d "$DOTFILES_SRC" ]]; then
    rsync -av --progress "$DOTFILES_SRC/" "$BACKUP_DIR/Dotfiles/"
    success "Dotfiles salvos no iCloud!"
fi

# 6. Criar Backup Criptografado das Chaves SSH e Credenciais
info "6/6 Empacotando chaves SSH em arquivo criptografado..."
TEMP_DIR="$(mktemp -d)"
mkdir -p "$TEMP_DIR/ssh_backup"

if [[ -d "$HOME/.ssh" ]]; then
    cp -R "$HOME/.ssh" "$TEMP_DIR/ssh_backup/" 2>/dev/null || true
fi
if [[ -d "$HOME/.gnupg" ]]; then
    cp -R "$HOME/.gnupg" "$TEMP_DIR/ssh_backup/" 2>/dev/null || true
fi

# Remover sockets de agente SSH se existirem no temp
find "$TEMP_DIR/ssh_backup" -type s -delete 2>/dev/null || true

ZIP_DEST="$BACKUP_DIR/Seguranca/chaves_ssh_privadas.zip"
rm -f "$ZIP_DEST" 2>/dev/null || true

echo "Por favor, digite uma senha para proteger o arquivo de chaves SSH (guarde esta senha!):"
(cd "$TEMP_DIR/ssh_backup" && zip -e -r "$ZIP_DEST" .)

rm -rf "$TEMP_DIR"
success "Chaves salvas de forma segura em $ZIP_DEST"

# Copiar outras pastas soltas importantes
for folder in "$HOME/Fila" "$HOME/Transcricoes" "$HOME/RedragonMouseRebindMac"; do
    if [[ -d "$folder" ]]; then
        rsync -av --progress "$folder/" "$BACKUP_DIR/OutrasPastas/$(basename "$folder")/"
    fi
done

echo ""
echo "${GREEN}${BOLD}====================================================${RESET}"
echo "${GREEN}${BOLD} 🎉 Backup Organizado no iCloud Concluído!          ${RESET}"
echo "${GREEN}${BOLD}====================================================${RESET}"
echo "Seu backup está em: $BACKUP_DIR"
echo ""
echo "Estrutura criada no seu iCloud Drive:"
echo " 📁 Backup_Mac_Formatacao/"
echo "    ├── 📁 Developer/          (Seus projetos de código)"
echo "    ├── 📁 ZenBrowser/         (Seu perfil, abas e senhas do Zen)"
echo "    ├── 📁 Raycast/            (Extensões, atalhos, IA e configs do Raycast)"
echo "    ├── 📁 Projetos_IDEs/      (CLion, IntelliJ, PyCharm)"
echo "    ├── 📁 Dotfiles/           (Brewfile e scripts de restauração)"
echo "    ├── 📁 Seguranca/          (Arquivo ZIP com chaves SSH)"
echo "    └── 📁 OutrasPastas/       (Pastas Fila, Transcrições, etc.)"
echo ""
