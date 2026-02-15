#!/bin/bash
set -e

# =============================================
#  Dev Environment Setup — WSL (Ubuntu)
#  github.com/leonardowsr/dev-setup
# =============================================
#
#  Uso:
#    ./install.sh          Instala tudo
#    ./install.sh --skip   Menu interativo (escolhe o que instalar)
#
# =============================================

GREEN="\033[32m"
CYAN="\033[36m"
YELLOW="\033[33m"
RED="\033[31m"
BOLD="\033[1m"
RESET="\033[0m"

log()  { echo -e "${CYAN}[*]${RESET} $1"; }
ok()   { echo -e "${GREEN}[✓]${RESET} $1"; }
warn() { echo -e "${YELLOW}[!]${RESET} $1"; }
err()  { echo -e "${RED}[✗]${RESET} $1"; }

INTERACTIVE=false
[[ "$1" == "--skip" ]] && INTERACTIVE=true

should_install() {
  if $INTERACTIVE; then
    read -p "  Instalar $1? [Y/n] " answer
    [[ -z "$answer" || "$answer" =~ ^[Yy] ]]
  else
    return 0
  fi
}

echo ""
echo -e "${BOLD}=========================================${RESET}"
echo -e "${BOLD}  Dev Environment Setup — WSL${RESET}"
echo -e "${BOLD}=========================================${RESET}"
echo ""

# -----------------------------------------------
# 1. Pacotes base do sistema
# -----------------------------------------------
log "Atualizando pacotes do sistema..."
sudo apt update -qq
sudo apt install -y \
  git curl wget unzip build-essential \
  ca-certificates gnupg lsb-release \
  software-properties-common \
  zlib1g-dev libssl-dev libreadline-dev \
  libffi-dev libbz2-dev libsqlite3-dev \
  htop
ok "Pacotes base instalados"

# -----------------------------------------------
# 1.5 Git config + .gitignore_global
# -----------------------------------------------
log "Configurando Git..."

if [ -z "$(git config --global user.name)" ]; then
  read -p "  Seu nome para o Git: " git_name
  git config --global user.name "$git_name"
fi

if [ -z "$(git config --global user.email)" ]; then
  read -p "  Seu email para o Git: " git_email
  git config --global user.email "$git_email"
fi

git config --global core.autocrlf input
git config --global credential.helper store
git config --global http.postBuffer 524288000

# .gitignore_global
GITIGNORE_GLOBAL="$HOME/.gitignore_global"
if [ ! -f "$GITIGNORE_GLOBAL" ]; then
  cat > "$GITIGNORE_GLOBAL" << 'GITIGNORE'
# OS
.DS_Store
Thumbs.db
Desktop.ini

# Editores/IDEs
.vscode/settings.json
.idea/
*.swp
*.swo
*~

# Env e secrets
.env
.env.*
!.env.example

# Dependencias
node_modules/
__pycache__/
*.pyc
.venv/

# Build
dist/
build/
*.log

# Debug
npm-debug.log*
yarn-debug.log*
yarn-error.log*
GITIGNORE
  git config --global core.excludesfile "$GITIGNORE_GLOBAL"
  ok ".gitignore_global criado"
else
  ok ".gitignore_global ja existe"
fi

ok "Git configurado ($(git config --global user.name) <$(git config --global user.email)>)"

# -----------------------------------------------
# 2. Zsh + Oh My Zsh + Plugins (via dotfiles)
# -----------------------------------------------
if should_install "Zsh + Oh My Zsh + Plugins"; then
  log "Configurando Zsh..."

  # Zsh
  if ! command -v zsh &>/dev/null; then
    sudo apt install -y zsh
  fi

  # Oh My Zsh
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  # Plugins
  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  declare -A zsh_plugins=(
    ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions.git"
    ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
    ["zsh-autocomplete"]="https://github.com/marlonrichert/zsh-autocomplete.git"
    ["you-should-use"]="https://github.com/MichaelAquilina/zsh-you-should-use.git"
  )
  for plugin in "${!zsh_plugins[@]}"; do
    [ ! -d "$ZSH_CUSTOM/plugins/$plugin" ] && git clone "${zsh_plugins[$plugin]}" "$ZSH_CUSTOM/plugins/$plugin"
  done

  # Ferramentas CLI modernas
  # eza
  if ! command -v eza &>/dev/null; then
    sudo apt install -y eza
  fi

  # zoxide
  if ! command -v zoxide &>/dev/null; then
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
  fi

  # Starship
  if ! command -v starship &>/dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
  fi

  # Copiar .zshrc do dotfiles (se existir)
  if [ -d "$HOME/dotfiles" ] && [ -f "$HOME/dotfiles/.zshrc" ]; then
    [ -f "$HOME/.zshrc" ] && cp "$HOME/.zshrc" "$HOME/.zshrc.bak"
    cp "$HOME/dotfiles/.zshrc" "$HOME/.zshrc"
    ok "Zshrc restaurado do dotfiles"
  else
    warn "Repo dotfiles nao encontrado — clone com: git clone https://github.com/leonardowsr/dotfiles.git ~/dotfiles"
  fi

  # Shell padrao
  if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)"
  fi

  ok "Zsh + Oh My Zsh + Plugins configurados"
fi

# -----------------------------------------------
# 3. NVM + Node.js + PNPM
# -----------------------------------------------
if should_install "NVM + Node.js + PNPM"; then
  log "Instalando NVM..."

  if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  else
    ok "NVM ja instalado"
  fi

  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  log "Instalando Node.js LTS..."
  nvm install --lts
  nvm alias default lts/*
  ok "Node $(node -v) instalado"

  log "Instalando PNPM..."
  if ! command -v pnpm &>/dev/null; then
    corepack enable
    corepack prepare pnpm@latest --activate
  fi
  ok "PNPM $(pnpm -v) instalado"

  log "Instalando Bun..."
  if ! command -v bun &>/dev/null; then
    curl -fsSL https://bun.sh/install | bash
  fi
  ok "Bun $(~/.bun/bin/bun -v 2>/dev/null || echo 'instalado') pronto"
fi

# -----------------------------------------------
# 4. Java (Microsoft OpenJDK 17)
# -----------------------------------------------
if should_install "Java (OpenJDK 17)"; then
  log "Instalando Java 17..."

  if ! java -version 2>&1 | grep -q "17"; then
    # Adicionar repo Microsoft
    wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O /tmp/ms-prod.deb
    sudo dpkg -i /tmp/ms-prod.deb
    rm /tmp/ms-prod.deb
    sudo apt update -qq
    sudo apt install -y msopenjdk-17
  fi

  ok "Java $(java -version 2>&1 | head -1) instalado"
fi

# -----------------------------------------------
# 5. Python + uv (gerenciador moderno)
# -----------------------------------------------
if should_install "Python + uv"; then
  log "Configurando Python..."

  if ! command -v python3 &>/dev/null; then
    sudo apt install -y python3 python3-pip python3-venv
  fi

  if ! command -v uv &>/dev/null; then
    log "Instalando uv (gerenciador Python moderno)..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi

  ok "Python $(python3 --version) + uv instalados"
fi

# -----------------------------------------------
# 6. Docker
# -----------------------------------------------
if should_install "Docker"; then
  log "Instalando Docker..."

  if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER"
    warn "Docker instalado — faca logout/login pra usar sem sudo"
  else
    ok "Docker ja instalado ($(docker --version))"
  fi
fi

# -----------------------------------------------
# 7. GitHub CLI
# -----------------------------------------------
if should_install "GitHub CLI (gh)"; then
  log "Instalando GitHub CLI..."

  if ! command -v gh &>/dev/null; then
    (type -p wget >/dev/null || sudo apt install wget -y) \
      && sudo mkdir -p -m 755 /etc/apt/keyrings \
      && out=$(mktemp) && wget -nv -O- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
      && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
      && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
      && sudo apt update -qq && sudo apt install gh -y
    warn "Depois de instalar, autentique com: gh auth login"
  else
    ok "GitHub CLI ja instalado ($(gh --version | head -1))"
  fi
fi

# -----------------------------------------------
# 8. Ngrok
# -----------------------------------------------
if should_install "Ngrok"; then
  log "Instalando Ngrok..."

  if ! command -v ngrok &>/dev/null; then
    curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok-v3-stable-linux-amd64.tgz | sudo tar xz -C /usr/local/bin
    warn "Depois de instalar, autentique com: ngrok config add-authtoken <token>"
  else
    ok "Ngrok ja instalado"
  fi
fi

# -----------------------------------------------
# 9. Android SDK tools (via Windows — WSL config)
# -----------------------------------------------
if should_install "Android SDK config (WSL -> Windows)"; then
  log "Configurando Android SDK..."

  WIN_USER=$(cmd.exe /C "echo %USERNAME%" 2>/dev/null | tr -d '\r' || echo "")
  if [ -n "$WIN_USER" ]; then
    ANDROID_SDK="/mnt/c/Users/$WIN_USER/AppData/Local/Android/Sdk"
    if [ -d "$ANDROID_SDK" ]; then
      ok "Android SDK detectado em $ANDROID_SDK"
      echo "  As variaveis ANDROID_HOME ja estao no .zshrc"
    else
      warn "Android SDK nao encontrado em $ANDROID_SDK"
      warn "Instale o Android Studio no Windows primeiro"
    fi
  else
    warn "Nao foi possivel detectar o usuario Windows"
  fi
fi

# -----------------------------------------------
# 9. VSCode extensions
# -----------------------------------------------
if should_install "VSCode extensions"; then
  log "Instalando extensoes do VSCode..."

  extensions=(
    # Essenciais
    "anthropic.claude-code"
    "expo.vscode-expo-tools"
    "yoavbls.pretty-ts-errors"
    "github.vscode-pull-request-github"
    "redhat.vscode-yaml"
    # Produtividade
    "biomejs.biome"
    "bradlc.vscode-tailwindcss"
    "dbaeumer.vscode-eslint"
    "esbenp.prettier-vscode"
    "prisma.prisma"
  )

  for ext in "${extensions[@]}"; do
    code --install-extension "$ext" --force 2>/dev/null || true
  done

  ok "Extensoes do VSCode instaladas"
fi

# -----------------------------------------------
# 10. Nerd Font (lembrete)
# -----------------------------------------------
echo ""
echo -e "${YELLOW}=========================================${RESET}"
echo -e "${YELLOW}  LEMBRETE: Instale a Nerd Font no Windows${RESET}"
echo -e "${YELLOW}=========================================${RESET}"
echo ""
echo "  No PowerShell do Windows:"
echo "    winget install Nerd-Fonts.JetBrainsMono"
echo ""
echo "  No VSCode (settings.json):"
echo '    "terminal.integrated.fontFamily": "JetBrainsMono Nerd Font"'
echo ""

# -----------------------------------------------
# Resumo
# -----------------------------------------------
echo -e "${GREEN}=========================================${RESET}"
echo -e "${GREEN}  Setup completo!${RESET}"
echo -e "${GREEN}=========================================${RESET}"
echo ""
echo "  Proximo passo: abra um novo terminal (ou rode 'zsh')"
echo ""
echo "  Se ainda nao fez:"
echo "    gh auth login          -> autenticar GitHub"
echo "    nvm use --lts          -> ativar Node"
echo ""
