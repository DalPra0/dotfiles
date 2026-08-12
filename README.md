# ⚡ RESTAURAÇÃO EM 1 CLIQUE (PÓS-FORMATAÇÃO)

> Abra o Terminal no Mac recém-formatado e cole o comando abaixo:

```bash
git clone https://github.com/DalPra0/dotfiles.git ~/dotfiles && cd ~/dotfiles && ./setup.sh
```

---

# 🚀 macOS Dotfiles & Backup Automatizado (DalPra0)

Este repositório contém a configuração completa do seu macOS, lista de todos os aplicativos instalados (via Homebrew/Brewfile), perfil do **Zen Browser**, extensões do **Raycast**, projetos da pasta **`Developer`** e um script para reconfigurar todo o sistema em **1 clique** após uma formatação do zero.

---

## 📂 O que está salvo e configurado

```text
.
├── Brewfile              # Todos os Apps (Casks), ferramentas CLI e extensões (Raycast, Cursor, Chrome, Zen, etc.)
├── setup.sh              # Script de restauração automatizada pós-formatação (1 Clique)
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
    ├── backup_to_icloud.sh # Script para backup completo no iCloud (Developer, Zen, Raycast, IDEs, SSH)
    └── backup_private.sh   # Script de backup de chaves SSH
```

---

## ☁️ Backup no iCloud Drive (Antes de Formatar)

No seu terminal atual, execute o comando abaixo para salvar e organizar seus arquivos no iCloud:

```bash
/Users/lucasdalprabrascher/.gemini/antigravity/scratch/dotfiles/scripts/backup_to_icloud.sh
```

### O que o backup do iCloud inclui:
- 📁 **Developer**: Todos os seus projetos de código (sem `node_modules` para economizar espaço).
- 📁 **ZenBrowser**: Seu perfil completo (Abas abertas, Favoritos, Extensões e Senhas salvas).
- 📁 **Raycast**: Todas as suas Extensões, Atalhos, Snippets, histórico e configurações de IA.
- 📁 **Projetos_IDEs**: Projetos do CLion, IntelliJ e PyCharm.
- 📁 **Seguranca**: Arquivo `.zip` criptografado com senha contendo suas chaves SSH (`~/.ssh`).

---

## 🧹 Como Formatar o Mac Limpo

1. Desligue seu Mac.
2. Ligue mantendo pressionado o botão de **Ligar (Power)** no Apple Silicon (M1/M2/M3/M4) até ver *"Carregando opções de inicialização"*.
3. Selecione **Opções** > **Utilitário de Disco**.
4. Apague a unidade principal (`Macintosh HD`) selecionando o formato **APFS**.
5. Saia do Utilitário de Disco e selecione **Reinstalar macOS**.

---

## ⚡ Passo a Passo Pós-Formatação

1. Faça login na sua conta **Apple ID**.
2. Abra o **Terminal**.
3. Execute o comando de restauração:

```bash
git clone https://github.com/DalPra0/dotfiles.git ~/dotfiles && cd ~/dotfiles && ./setup.sh
```

### O que o `setup.sh` fará automaticamente:
1. Instalará o **Xcode Command Line Tools**.
2. Instalará o **Homebrew**.
3. Baixará e instalará **todos os seus apps e ferramentas CLI** do `Brewfile` (Raycast, Zen, Chrome, Cursor, Zed, Figma, Notion, Discord, WhatsApp, Zoom, Steam, etc.).
4. Instalará o **Oh My Zsh** e o **Antigravity CLI**.
5. Restaurará seus **Dotfiles** (`.zshrc`, `.gitconfig`, `.config/*`).
6. Restaurará automaticamente do iCloud Drive a pasta **`Developer`**, o perfil do **Zen Browser** (com senhas e abas) e do **Raycast** (com atalhos e extensões).
