# 🚀 macOS Dotfiles & Setup Automatizado (DalPra0)

Este repositório contém a configuração completa do meu macOS, lista de aplicativos instalados (via Homebrew) e um script para reconfigurar todo o sistema em **1 clique** após uma formatação do zero.

---

## 📂 Estrutura do Repositório

```text
.
├── Brewfile              # Todos os Apps (Casks), ferramentas CLI e extensões instaladas
├── setup.sh              # Script de restauração automatizada pós-formatação
├── .gitignore            # Proteção contra envio de chaves privadas e logs
├── shell/
│   ├── .zshrc           # Configuração do Zsh (aliases, temas, variáveis)
│   ├── .bash_profile    # Configuração do Bash Profile
│   └── .bashrc          # Configuração do Bash
├── git/
│   └── .gitconfig       # Configuração global do Git (nome, email)
├── config/
│   ├── fastfetch/       # Configuração do Fastfetch
│   ├── karabiner/       # Mapeamento do teclado (Karabiner-Elements)
│   ├── zed/             # Configurações do editor Zed
│   ├── spotify-player/  # Configuração do player Spotify CLI
│   └── aerospace/       # Tiling Window Manager
└── scripts/
    └── backup_private.sh # Script para backup seguro de chaves SSH
```

---

## 📋 Passo 1: O que fazer ANTES de formatar o Mac

### 1.1 Gerar o backup privado das suas chaves SSH
Execute o script abaixo para criar um arquivo `.zip` com senha contendo suas chaves SSH (`~/.ssh`):
```bash
./scripts/backup_private.sh
```
> **ATENÇÃO:** Mova o arquivo `.zip` gerado na Mesa (Desktop) para um **Pen Drive, HD Externo ou iCloud Drive**!

### 1.2 Subir este repositório para o seu GitHub
Abra o terminal e execute os comandos para publicar este repositório na sua conta do GitHub:

```bash
git init
git add .
git commit -m "feat: backup completo de dotfiles, apps e configurações"
git branch -M main

# Se você possui o GitHub CLI (gh) instalado:
gh repo create dotfiles --public --source=. --remote=origin --push

# Ou adicione o remote manualmente (substituindo pela URL do seu repositório criado no GitHub):
# git remote add origin https://github.com/DalPra0/dotfiles.git
# git push -u origin main
```

---

## 🧹 Passo 2: Como Formatar o Mac Limpo

1. Desligue seu Mac.
2. Ligue mantendo pressionado o botão de **Ligar (Power)** no Apple Silicon (M1/M2/M3/M4) até ver "Carregando opções de inicialização".
3. Selecione **Opções** > **Utilitário de Disco**.
4. Apague a unidade principal (`Macintosh HD`) selecionando o formato **APFS**.
5. Saia do Utilitário de Disco e selecione **Reinstalar macOS**.

---

## ⚡ Passo 3: O que fazer APÓS formatar (Restauração do zero)

Em um Mac recém-instalado, abra o **Terminal** e execute apenas este comando:

```bash
git clone https://github.com/DalPra0/dotfiles.git ~/dotfiles && cd ~/dotfiles && chmod +x setup.sh && ./setup.sh
```

### O que o `setup.sh` fará automaticamente:
1. Instalará o **Xcode Command Line Tools**.
2. Instalará o **Homebrew**.
3. Baixará e instalará **todos os seus apps e ferramentas CLI** do `Brewfile` (Chrome, Zed, Figma, Aerospace, Raycast, Notion, etc.).
4. Instalará o **Oh My Zsh**.
5. Restaurará todos os arquivos de configuração (`.zshrc`, `.gitconfig`, `.config/*`).
6. Aplicará ajustes de sistema do macOS.

---

## 🔐 Restaurando suas chaves SSH privadas

Copie o arquivo `.zip` salvo no seu iCloud/Pen Drive para o novo Mac e descompacte suas chaves de volta para a pasta home:
```bash
unzip ~/Downloads/mac_private_keys_*.zip -d ~/.ssh/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_* 2>/dev/null || true
```
