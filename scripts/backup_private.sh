#!/usr/bin/env bash

# ==============================================================================
# Script de Backup Seguro de Dados Privados (SSH, Chaves, Credenciais)
# ==============================================================================

set -e

BACKUP_DIR="$HOME/Desktop"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_FILE="$BACKUP_DIR/mac_private_keys_$TIMESTAMP.zip"

echo "=== Criando Backup Seguro de Chaves SSH e Credenciais ==="
echo "Este arquivo conterá suas chaves SSH privadas e NÃO deve ser enviado para o GitHub!"
echo ""

TEMP_DIR="$(mktemp -d)"

# Copiar chaves SSH
if [[ -d "$HOME/.ssh" ]]; then
    echo "-> Incluindo ~/.ssh..."
    mkdir -p "$TEMP_DIR/ssh"
    cp -R "$HOME/.ssh/"* "$TEMP_DIR/ssh/" 2>/dev/null || true
fi

# Copiar chaves GPG se existirem
if [[ -d "$HOME/.gnupg" ]]; then
    echo "-> Incluindo ~/.gnupg..."
    mkdir -p "$TEMP_DIR/gnupg"
    cp -R "$HOME/.gnupg/"* "$TEMP_DIR/gnupg/" 2>/dev/null || true
fi

# Compactar com senha
echo ""
echo "Digite uma senha forte para proteger seu arquivo de backup:"
zip -e -r "$OUTPUT_FILE" -j "$TEMP_DIR"/*

rm -rf "$TEMP_DIR"

echo ""
echo "✅ Backup privado criado com sucesso em:"
echo "   $OUTPUT_FILE"
echo ""
echo "⚠️  IMPORTANTE: Guarde este arquivo em um Pen Drive, HD Externo ou iCloud Drive antes de formatar!"
