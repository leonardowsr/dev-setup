# dev-setup

Script automatizado para configurar meu ambiente de desenvolvimento no WSL (Ubuntu) do zero.

## O que instala

| Categoria | Ferramentas |
|-----------|-------------|
| **Sistema** | git, curl, wget, build-essential, htop e dependencias |
| **Git** | Config interativa (nome/email) + .gitignore_global |
| **Shell** | Zsh, Oh My Zsh, plugins (autosuggestions, syntax-highlighting, autocomplete, you-should-use) |
| **CLI modernas** | eza, zoxide, Starship |
| **Node.js** | NVM + Node LTS + PNPM (via corepack) + Bun |
| **Java** | Microsoft OpenJDK 17 |
| **Python** | Python 3 + uv (gerenciador moderno) |
| **Docker** | Docker Engine |
| **GitHub** | GitHub CLI (gh) |
| **Ngrok** | Tunneling para expor localhost |
| **Android** | Android SDK nativo no Linux (build-tools, platform-tools, NDK) |
| **VSCode** | Extensoes essenciais (Biome, Prisma, Tailwind, Expo, etc.) |

## Uso rapido

### PC novo — instalacao completa

```bash
# 1. Instalar pre-requisitos
sudo apt update && sudo apt install -y git curl

# 2. Clonar os dois repos
git clone https://github.com/leonardowsr/dotfiles.git ~/dotfiles
git clone https://github.com/leonardowsr/dev-setup.git ~/dev-setup

# 3. Rodar o setup
cd ~/dev-setup
./install.sh
```

### Instalacao interativa (escolher o que instalar)

```bash
./install.sh --skip
```

Vai perguntar item por item se voce quer instalar.

## O que cada secao faz

### 1. Pacotes base
Instala compiladores, libs necessarias para NVM/Python e htop.

### 1.5 Git config + .gitignore_global
- Pede nome e email interativamente (nada sensivel no repo)
- Configura `core.autocrlf=input`, `credential.helper=store`
- Cria `.gitignore_global` com regras para `.env`, `node_modules`, `.DS_Store`, IDEs, etc.

### 2. Zsh + Oh My Zsh + Plugins
- Instala Zsh e define como shell padrao
- Instala Oh My Zsh com plugins customizados
- Instala eza, zoxide e Starship
- Restaura `.zshrc` do repo [dotfiles](https://github.com/leonardowsr/dotfiles)

### 3. NVM + Node.js + PNPM
- Instala NVM v0.40.1
- Instala Node.js LTS e define como padrao
- Ativa PNPM via corepack
- Instala [Bun](https://bun.sh) — runtime JS ultrarapido

### 4. Java (OpenJDK 17)
Instala Microsoft OpenJDK 17 nativo no Linux (nao depende do Windows).

### 5. Python + uv
- Python 3 (ja vem no Ubuntu, mas garante pip e venv)
- [uv](https://github.com/astral-sh/uv) — gerenciador de pacotes Python ultrarapido (substitui pip, venv, pipx)

### 6. Docker
Instala Docker Engine e adiciona seu usuario ao grupo docker.

### 7. GitHub CLI
Instala `gh` para criar PRs, issues, etc. direto do terminal.

### 8. Ngrok
Instala ngrok para expor localhost via tunnel (usado com Expo, webhooks, etc.).

### 9. Android SDK (Linux nativo)
Instala o Android SDK direto no Linux/WSL (`~/Android/Sdk`). Inclui:
- command-line tools + sdkmanager
- platform-tools (adb)
- build-tools 36.0.0
- platform android-36
- NDK 27.1

Muito mais rapido que usar o SDK do Windows via `/mnt/c/`.

### 10. VSCode Extensions
Instala extensoes essenciais:
- `anthropic.claude-code` — Claude Code
- `expo.vscode-expo-tools` — Expo
- `yoavbls.pretty-ts-errors` — Erros TypeScript legiveis
- `biomejs.biome` — Linter/Formatter
- `bradlc.vscode-tailwindcss` — Tailwind CSS
- `prisma.prisma` — Prisma ORM
- `github.vscode-pull-request-github` — PRs no VSCode

## Pos-instalacao (manual)

### Nerd Font (para icones no terminal)

No **PowerShell do Windows**:

```powershell
winget install Nerd-Fonts.JetBrainsMono
```

No VSCode (`settings.json`):

```json
"terminal.integrated.fontFamily": "JetBrainsMono Nerd Font"
```

### Autenticar GitHub

```bash
gh auth login
```

### Autenticar Docker Hub (se necessario)

```bash
docker login
```

## Estrutura dos repos

```
~/
├── dotfiles/          -> configs do shell (.zshrc, starship.toml)
│   ├── .zshrc
│   ├── install.sh     -> restaura so o shell
│   └── README.md
│
└── dev-setup/         -> setup completo do ambiente
    ├── install.sh     -> instala tudo (shell + ferramentas + linguagens)
    └── README.md
```
