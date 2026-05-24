#!/bin/bash
set -e

VERSION="${OPENAFP_VERSION:-v0.36.1}"
REPO="https://gitee.com/openafp/openafp-public"
GH_REPO="https://github.com/openafp-net/openafp"
CONFIG_DIR="${HOME}/.openafp"
BIN_DIR="/usr/local/bin"

# ---- helpers ----
detect_platform() {
  local os arch
  case "$(uname -s)" in
    Linux)  os="linux" ;;
    Darwin) os="darwin" ;;
    *)      echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
  esac
  case "$(uname -m)" in
    x86_64|amd64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) echo "Unsupported arch: $(uname -m)" >&2; exit 1 ;;
  esac
  echo "${os}-${arch}"
}

# ---- main ----
PLATFORM=$(detect_platform)
ARCHIVE="openafp-gateway-${PLATFORM}.tar.gz"
URL="${REPO}/releases/download/${VERSION}/${ARCHIVE}"

echo "==> Installing OpenAFP ${VERSION} (${PLATFORM})"

# create config dir
mkdir -p "${CONFIG_DIR}"

# download & extract
TMPDIR=$(mktemp -d)
trap "rm -rf ${TMPDIR}" EXIT

echo "==> Downloading ${URL}"
DOWNLOAD_OK=0
if command -v curl >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -fsSL -o "${TMPDIR}/${ARCHIVE}" "${URL}" && DOWNLOAD_OK=1
elif command -v wget >/dev/null 2>&1; then
  wget -q -O "${TMPDIR}/${ARCHIVE}" "${URL}" && DOWNLOAD_OK=1
else
  echo "ERROR: curl or wget required" >&2
  exit 1
fi

if [ "$DOWNLOAD_OK" != "1" ]; then
  GH_URL="${GH_REPO}/releases/download/${VERSION}/${ARCHIVE}"
  echo "==> Gitee failed, trying GitHub: ${GH_URL}"
  if command -v curl >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -fsSL -o "${TMPDIR}/${ARCHIVE}" "${GH_URL}"
  else
    wget -q -O "${TMPDIR}/${ARCHIVE}" "${GH_URL}"
  fi
fi

tar xzf "${TMPDIR}/${ARCHIVE}" -C "${TMPDIR}"

# install binary (archive name varies by platform)
BIN_FILE=$(ls "${TMPDIR}"/openafp-gateway* 2>/dev/null | head -1)
if [ -z "$BIN_FILE" ]; then
    echo "Error: cannot find openafp-gateway binary"
    exit 1
fi
sudo mv "$BIN_FILE" "${BIN_DIR}/openafp-gateway"
sudo chmod +x "${BIN_DIR}/openafp-gateway"

# generate default config if not exists
if [ ! -f "${CONFIG_DIR}/config.yaml" ]; then
  cat > "${CONFIG_DIR}/config.yaml" << EOF
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
    path: ${CONFIG_DIR}/openafp.db
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
EOF
  echo "==> Default config created at ${CONFIG_DIR}/config.yaml"
fi

# generate identity key if not exists
if [ ! -f "${CONFIG_DIR}/identity.key" ]; then
  openssl rand -base64 32 > "${CONFIG_DIR}/identity.key" 2>/dev/null || \
    head -c 32 /dev/urandom | base64 > "${CONFIG_DIR}/identity.key"
  chmod 600 "${CONFIG_DIR}/identity.key"
  echo "==> Identity key generated at ${CONFIG_DIR}/identity.key"
fi

echo ""
echo "OpenAFP ${VERSION} installed successfully!"
echo "  Binary: ${BIN_DIR}/openafp-gateway"
echo "  Config: ${CONFIG_DIR}/config.yaml"
echo ""
echo "  To start: openafp-gateway --config ${CONFIG_DIR}/config.yaml"