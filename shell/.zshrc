# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"


# neofetch --ascii_distro SliTaz

plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-history-substring-search
)

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes


ZSH_THEME="mikeh"
# ZSH_THEME="jonathan"


# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# cmatrix
# { sleep 1 ; echo starwars ; sleep 99999 ;} | nc -c telehack.com 23

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion



# === Alias: w (transcrever + zip) ===
w() {
  local in="$1"
  if [ -z "$in" ] || [ ! -f "$in" ]; then
    echo "uso: w /caminho/arquivo.{m4a,mp3,wav,...}"
    return 1
  fi

  local base="$(basename "$in")"
  base="${base%.*}"
  local outdir="$HOME/Transcricoes"
  local out="$outdir/$base"
  mkdir -p "$outdir"

  # FFmpeg obrigatório
  if ! command -v ffmpeg >/dev/null; then
    echo "FFmpeg não encontrado. Instale com: brew install ffmpeg"
    return 1
  fi

  # whisper-cli obrigatório
  local wdir="$HOME/whisper.cpp"
  local wbin="$wdir/build/bin/whisper-cli"
  if [ ! -x "$wbin" ]; then
    echo "whisper-cli não encontrado em: $wbin"
    echo "Compile com:"
    echo "  cd \"$wdir\" && cmake -B build -DGGML_METAL=1 && cmake --build build -j"
    return 1
  fi

  # Converter para WAV 16 kHz mono (mais compatível com whisper.cpp)
  local wav="$out.tmp.wav"
  ffmpeg -hide_banner -loglevel error -y \
    -i "$in" -ac 1 -ar 16000 -c:a pcm_s16le "$wav" || { echo "Falha na conversão FFmpeg"; return 1; }

  # Rodar whisper.cpp (usa Core ML se o encoder existir; senão, Metal)
  "$wbin" \
    -m "$wdir/models/ggml-large-v3.bin" \
    -f "$wav" \
    -l pt \
    --beam-size 5 \
    -otxt -osrt -ovtt \
    -of "$out"
  local status=$?

  # Limpar WAV temporário
  rm -f "$wav"
  if [ $status -ne 0 ]; then
    echo "Whisper falhou (código $status)"
    return $status
  fi

  # Coletar saídas desta transcrição e zipar (se existirem)
  local zip="$out.zip"
  local files=()
  for f in "$out".*; do
    [ -e "$f" ] || continue
    [[ "$f" == "$zip" ]] && continue
    files+=("$f")
  done

  if [ ${#files[@]} -gt 0 ]; then
    ( cd "$outdir" && zip -j -q -FS "${base}.zip" "${files[@]}" ) && \
      echo "📦 ZIP criado: $zip"
  else
    echo "Nenhuma saída encontrada para compactar."
  fi

  echo "✅ Saídas:"
  for f in "${files[@]}"; do echo "  $f"; done
  [ -f "$zip" ] && echo "  $zip"
}


alias balatro='/Users/lucasdalprabrascher/Library/Application\ Support/Steam/steamapps/common/Balatro/run_lovely_macos.sh'

alias steamConsole='/Applications/Steam.app/Contents/MacOS/steam_osx -console'

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
    else
        export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


if command -v /usr/libexec/java_home >/dev/null 2>&1; then
  JAVA11_HOME="$(/usr/libexec/java_home -v 11 2>/dev/null || true)"
  if [ -n "$JAVA11_HOME" ]; then
    export JAVA_HOME="$JAVA11_HOME"
  fi
  unset JAVA11_HOME
fi
export PATH="$HOME/.local/bin:$PATH"

export ANTHROPIC_BASE_URL=http://localhost:11434
export ANTHROPIC_API_KEY=ollama

alias cco='claude --model qwen3-coder --thinking disabled'


# Added by Antigravity CLI installer
export PATH="/Users/lucasdalprabrascher/.local/bin:$PATH"
