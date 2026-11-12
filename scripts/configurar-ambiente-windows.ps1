<#
  Configura o ambiente de desenvolvimento do Controle de Presença no Windows.

  Uso (PowerShell, NÃO precisa ser como administrador):
    Set-ExecutionPolicy -Scope Process Bypass -Force
    .\configurar-ambiente-windows.ps1

  Pode ser executado de novo quantas vezes quiser: o que já está instalado é pulado.

  Onde fica cada coisa:
    D:\workspace\Claude\projetos\controle-presenca   código (clone do GitHub)
    D:\workspace\Claude\programas\...                 Git, Node.js e VS Code
    D:\workspace\Claude\ferramentas\flutter, pub-cache  SDK e cache do Flutter
    D:\workspace\Claude\npm-global, npm-cache          pacotes globais e cache do npm
  Atenção: o Flutter não aceita caminho com espaço; não use espaço em -Raiz.
#>
param(
    [string]$Raiz = 'D:\workspace\Claude',
    [string]$Ferramentas = 'D:\workspace\Claude\ferramentas',
    [string]$Projeto = 'D:\workspace\Claude\projetos\controle-presenca',
    [string]$Repositorio = 'https://github.com/PierreSalves/pwa-controle-presenca.git',
    [switch]$SemClaudeCode
)

$ErrorActionPreference = 'Stop'

function Escrever-Etapa([string]$texto) { Write-Host "`n==> $texto" -ForegroundColor Cyan }

function Atualizar-Path {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')
}

function Adicionar-PathUsuario([string]$pasta) {
    $atual = [Environment]::GetEnvironmentVariable('Path', 'User')
    $itens = @($atual -split ';' | Where-Object { $_ })
    if ($itens -notcontains $pasta) {
        [Environment]::SetEnvironmentVariable('Path', (($itens + $pasta) -join ';'), 'User')
    }
    Atualizar-Path
}

function Tem-Comando([string]$nome) { [bool](Get-Command $nome -ErrorAction SilentlyContinue) }

function Instalar-Winget([string]$id, [string]$comando, [string]$pasta) {
    if (Tem-Comando $comando) { Write-Host "  $id já instalado ($comando encontrado)."; return }
    $parametros = @('install', '--id', $id, '-e', '--silent',
              '--accept-package-agreements', '--accept-source-agreements')
    if ($pasta) { $parametros += @('--location', $pasta) }
    winget @parametros
    if ($LASTEXITCODE -ne 0) { throw "Falha ao instalar $id (winget saiu com $LASTEXITCODE)." }
    Atualizar-Path
}

# --- Pré-requisitos -----------------------------------------------------------
Escrever-Etapa 'Conferindo pré-requisitos'
if (-not (Test-Path 'D:\')) { throw 'A unidade D: não existe.' }
if ($Ferramentas -match ' ') { throw 'O caminho das ferramentas não pode ter espaço (exigência do Flutter).' }
if (-not (Tem-Comando 'winget')) {
    throw 'winget não encontrado. Instale o "Instalador de Aplicativo" pela Microsoft Store e rode de novo.'
}
New-Item -ItemType Directory -Force -Path $Raiz, "$Raiz\programas", $Ferramentas | Out-Null

# --- Programas ----------------------------------------------------------------
Escrever-Etapa 'Git'
Instalar-Winget 'Git.Git' 'git' "$Raiz\programas\Git"

Escrever-Etapa 'Node.js LTS (para a API em Cloudflare Workers / wrangler)'
Instalar-Winget 'OpenJS.NodeJS.LTS' 'node' "$Raiz\programas\nodejs"

Escrever-Etapa 'Visual Studio Code'
Instalar-Winget 'Microsoft.VisualStudioCode' 'code' "$Raiz\programas\VSCode"

Escrever-Etapa 'Google Chrome (o Flutter Web roda nele durante o desenvolvimento)'
$chrome = @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
            "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
            "$env:LocalAppData\Google\Chrome\Application\chrome.exe") | Where-Object { Test-Path $_ }
if ($chrome) { Write-Host '  Chrome já instalado.' } else { Instalar-Winget 'Google.Chrome' 'chrome' $null }

# --- npm no D: ----------------------------------------------------------------
Escrever-Etapa 'Configurando npm para guardar pacotes globais e cache no D:'
New-Item -ItemType Directory -Force -Path "$Raiz\npm-global", "$Raiz\npm-cache" | Out-Null
npm config set prefix "$Raiz\npm-global"
npm config set cache "$Raiz\npm-cache"
Adicionar-PathUsuario "$Raiz\npm-global"

# --- Flutter ------------------------------------------------------------------
Escrever-Etapa 'Flutter SDK (canal stable)'
$flutter = "$Ferramentas\flutter"
if (Test-Path "$flutter\bin\flutter.bat") {
    Write-Host '  Flutter já existe; atualizando.'
    & "$flutter\bin\flutter.bat" upgrade
} else {
    git clone -b stable https://github.com/flutter/flutter.git $flutter
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao clonar o Flutter.' }
}
New-Item -ItemType Directory -Force -Path "$Ferramentas\pub-cache" | Out-Null
[Environment]::SetEnvironmentVariable('PUB_CACHE', "$Ferramentas\pub-cache", 'User')
$env:PUB_CACHE = "$Ferramentas\pub-cache"
Adicionar-PathUsuario "$flutter\bin"
Adicionar-PathUsuario "$Ferramentas\pub-cache\bin"
flutter config --enable-web --no-analytics
dart --disable-analytics

# --- Claude Code --------------------------------------------------------------
if (-not $SemClaudeCode) {
    Escrever-Etapa 'Claude Code'
    if (Tem-Comando 'claude') { Write-Host '  Claude Code já instalado.' }
    else { Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression; Atualizar-Path }
}

# --- Código do projeto --------------------------------------------------------
Escrever-Etapa 'Clonando o projeto'
$projeto = $Projeto
New-Item -ItemType Directory -Force -Path (Split-Path $projeto) | Out-Null
if (Test-Path "$projeto\.git") {
    Write-Host '  Projeto já clonado; buscando atualizações.'
    git -C $projeto fetch --all --prune
} else {
    git clone $Repositorio $projeto
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao clonar o projeto.' }
}

$nome = git config --global user.name
if (-not $nome) {
    Write-Host '  Configure seu nome e e-mail no git:' -ForegroundColor Yellow
    Write-Host '    git config --global user.name  "Seu Nome"'
    Write-Host '    git config --global user.email "seu@email"'
}

# --- Extensões do VS Code -----------------------------------------------------
Escrever-Etapa 'Extensões do VS Code'
foreach ($ext in 'Dart-Code.flutter', 'Dart-Code.dart-code', 'dbaeumer.vscode-eslint') {
    code --install-extension $ext --force | Out-Null
}

# --- Conferência --------------------------------------------------------------
Escrever-Etapa 'Conferindo versões'
git --version
node --version
npm --version
flutter --version
if (-not $SemClaudeCode -and (Tem-Comando 'claude')) { claude --version }

Escrever-Etapa 'flutter doctor'
flutter doctor

Write-Host "`nPronto! Feche e abra o terminal para o PATH novo valer." -ForegroundColor Green
Write-Host "Projeto em: $projeto"
Write-Host 'Lembre: o que protege o código é o GitHub. Faça commit e push sempre.'
