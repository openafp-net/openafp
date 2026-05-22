# OpenAFP Gateway installer for Windows
# Requires: PowerShell 5.1+, Windows 10 1803+ (built-in tar/curl)
# Usage: powershell -ExecutionPolicy Bypass -File install.ps1

$ErrorActionPreference = "Stop"

$VERSION = if ($env:OPENAFP_VERSION) { $env:OPENAFP_VERSION } else { "v0.34.0" }
$REPO    = "https://gitee.com/openafp/openafp-public"
$CONFIG_DIR = Join-Path $HOME ".openafp"
$BIN_DIR    = Join-Path $HOME "bin"

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
$ARCHIVE = "openafp-gateway-${PLATFORM}.tar.gz"
$URL     = "${REPO}/releases/download/${VERSION}/${ARCHIVE}"

Write-Host "==> Installing OpenAFP ${VERSION} (${PLATFORM})"

# create directories
New-Item -ItemType Directory -Force -Path $CONFIG_DIR | Out-Null
New-Item -ItemType Directory -Force -Path $BIN_DIR | Out-Null

# download & extract
$TMPDIR = Join-Path $env:TEMP "openafp-install-$(Get-Random)"
New-Item -ItemType Directory -Force -Path $TMPDIR | Out-Null

try {
    Write-Host "==> Downloading ${URL}"
    $archivePath = Join-Path $TMPDIR $ARCHIVE
    Invoke-WebRequest -Uri $URL -OutFile $archivePath -UseBasicParsing

    Write-Host "==> Extracting..."
    tar xzf $archivePath -C $TMPDIR
    if ($LASTEXITCODE -ne 0) {
        throw "tar extraction failed"
    }

    # install binary
    $binary = Get-ChildItem -Path $TMPDIR -Recurse -Name "openafp-gateway.exe" |
              Select-Object -First 1
    if (-not $binary) {
        throw "openafp-gateway.exe not found in archive"
    }
    Copy-Item -Path (Join-Path $TMPDIR $binary) `
              -Destination (Join-Path $BIN_DIR "openafp-gateway.exe") -Force
    Write-Host "==> Installed to $BIN_DIR\openafp-gateway.exe"

    # generate default config if not exists
    $configPath = Join-Path $CONFIG_DIR "config.yaml"
    if (-not (Test-Path $configPath)) {
@"
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
"@ | Out-File -FilePath $configPath -Encoding utf8
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
    if ($userPath -notlike "*${BIN_DIR}*") {
        [Environment]::SetEnvironmentVariable("PATH", "${userPath};${BIN_DIR}", "User")
        Write-Host "==> Added ${BIN_DIR} to user PATH (restart shell to take effect)"
    }

    Write-Host ""
    Write-Host "OpenAFP ${VERSION} installed successfully!"
    Write-Host "  Binary: ${BIN_DIR}\openafp-gateway.exe"
    Write-Host "  Config: ${configPath}"
    Write-Host ""
    Write-Host "  To start: openafp-gateway --config ${configPath}"

} finally {
    Remove-Item -Recurse -Force $TMPDIR -ErrorAction SilentlyContinue
}
