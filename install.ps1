# OpenAFP Gateway installer for Windows
# Requires: PowerShell 5.1+, Windows 10 1803+ (built-in tar/curl)
# Usage: powershell -ExecutionPolicy Bypass -File install.ps1

$ErrorActionPreference = "Stop"

$VERSION = if ($env:OPENAFP_VERSION) { $env:OPENAFP_VERSION } else { "v0.36.8" }
$REPO    = "https://gitee.com/openafp/openafp-public"
$GH_REPO = "https://github.com/openafp-net/openafp"
$CONFIG_DIR = Join-Path $HOME ".openafp"

# ---- platform detection ----
function Get-PlatformSuffix {
    $arch = switch ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture) {
        "X64"   { "amd64" }
        "Arm64" { "arm64" }
        default { throw "Unsupported architecture" }
    }
    return "windows-${arch}"
}

# ---- main ----
$PLATFORM = Get-PlatformSuffix
$ARCHIVE = "openafp-gateway-${PLATFORM}.zip"
$URL     = "${REPO}/releases/download/${VERSION}/${ARCHIVE}"
$GH_URL  = "${GH_REPO}/releases/download/${VERSION}/${ARCHIVE}"

Write-Host "==> Installing OpenAFP ${VERSION} (${PLATFORM})"

# create config directory
New-Item -ItemType Directory -Force -Path $CONFIG_DIR | Out-Null

# download & extract
$TMPDIR = Join-Path $env:TEMP "openafp-install-$(Get-Random)"
New-Item -ItemType Directory -Force -Path $TMPDIR | Out-Null

function Download-File {
    param($Uri, $OutFile)
    try {
        Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

try {
    Write-Host "==> Downloading ${URL}"
    $archivePath = Join-Path $TMPDIR $ARCHIVE
    if (-not (Download-File -Uri $URL -OutFile $archivePath)) {
        Write-Host "==> Gitee download failed, trying GitHub..."
        if (-not (Download-File -Uri $GH_URL -OutFile $archivePath)) {
            Write-Error "Download failed from both Gitee and GitHub"
            exit 1
        }
    }

    Write-Host "==> Extracting..."
    Expand-Archive -Path $archivePath -DestinationPath $TMPDIR -Force

    # install binary (archive contains platform-suffixed name, e.g. openafp-gateway-windows-amd64.exe)
    $binFile = Get-ChildItem -Path $TMPDIR -Recurse -Filter "openafp-gateway*.exe" | Select-Object -First 1
    if (-not $binFile) {
        Write-Error "Cannot find openafp-gateway executable"
        exit 1
    }
    $installDir = Join-Path $env:ProgramFiles "OpenAFP"
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
    Move-Item -Path $binFile.FullName -Destination (Join-Path $installDir "openafp-gateway.exe") -Force
    Write-Host "==> Installed to $installDir\openafp-gateway.exe"

    # generate default config if not exists
    $configPath = Join-Path $CONFIG_DIR "config.yaml"
    if (-not (Test-Path $configPath)) {
        $configContent = @"
server:
    port: 51888
    host: 0.0.0.0
    enable_https: false
    auth:
        enabled: false
        token: ""
        ip_whitelist: []
network:
    mode: auto
    listen_addrs:
        - /ip4/0.0.0.0/tcp/51890
        - /ip4/0.0.0.0/udp/51890/quic-v1
    announce_addrs: []
    bootstrap_peers:
        - /dns4/bootstrap.openafp.net/tcp/51890/p2p/12D3KooWCqGHJoqY7466vegQ6dKzUNE5b3Lp5DArqaEbZJBcJgB8
        - /dns4/relay-hk.openafp.net/tcp/51890/p2p/12D3KooWJ4PzqTdm72iX8wU5g5ZiMUdGB1f6mAru5gjdSCXvNHKy
    enable_mdns: true
    relay:
        enabled: true
        hop: false
        addrs:
            - /dns4/relay-cn.openafp.net/tcp/51890/p2p/12D3KooWCqGHJoqY7466vegQ6dKzUNE5b3Lp5DArqaEbZJBcJgB8
            - /dns4/relay-hk.openafp.net/tcp/51890/p2p/12D3KooWJ4PzqTdm72iX8wU5g5ZiMUdGB1f6mAru5gjdSCXvNHKy
database:
    path: $CONFIG_DIR\openafp.db
load_balance:
    default_strategy: least_used
circuit_breaker:
    failure_threshold: 5
    timeout_seconds: 60
observability:
    metrics:
        enabled: false
    tracing:
        enabled: true
    audit_log:
        enabled: false
a2a:
    enabled: false
compliance:
    enabled: false
security:
    network:
        allow_unencrypted_http: true
agents: []
agent:
    local:
        enabled: false
capabilities: []
"@
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($configPath, $configContent, $utf8NoBom)
        Write-Host "==> Default config created at ${configPath}"
    }

    # generate identity key if not exists
    $keyPath = Join-Path $CONFIG_DIR "identity.key"
    if (-not (Test-Path $keyPath)) {
        $bytes = New-Object byte[] 32
        [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
        $key = [Convert]::ToBase64String($bytes)
        $key | Out-File -FilePath $keyPath -Encoding ascii -NoNewline
        Write-Host "==> Identity key generated at ${keyPath}"
    }

    # add to PATH
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -notlike "*${installDir}*") {
        [Environment]::SetEnvironmentVariable("PATH", "${userPath};${installDir}", "User")
        Write-Host "==> Added ${installDir} to user PATH (restart shell to take effect)"
    }

    Write-Host ""
    Write-Host "OpenAFP ${VERSION} installed successfully!"
    Write-Host "  Binary: ${installDir}\openafp-gateway.exe"
    Write-Host "  Config: ${configPath}"
    Write-Host ""
    Write-Host "  To start: openafp-gateway --config ${configPath}"

} finally {
    Remove-Item -Recurse -Force $TMPDIR -ErrorAction SilentlyContinue
}
