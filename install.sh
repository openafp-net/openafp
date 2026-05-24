     1|#!/bin/bash
     2|set -e
     3|
     4|VERSION="${OPENAFP_VERSION:-v0.36.1}"
     5|REPO="https://gitee.com/openafp/openafp-public"
     6|CONFIG_DIR="${HOME}/.openafp"
     7|BIN_DIR="/usr/local/bin"
     8|
     9|# ---- helpers ----
    10|detect_platform() {
    11|  local os arch
    12|  case "$(uname -s)" in
    13|    Linux)  os="linux" ;;
    14|    Darwin) os="darwin" ;;
    15|    *)      echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
    16|  esac
    17|  case "$(uname -m)" in
    18|    x86_64|amd64) arch="amd64" ;;
    19|    aarch64|arm64) arch="arm64" ;;
    20|    *) echo "Unsupported arch: $(uname -m)" >&2; exit 1 ;;
    21|  esac
    22|  echo "${os}-${arch}"
    23|}
    24|
    25|# ---- main ----
    26|PLATFORM=$(detect_platform)
    27|ARCHIVE="openafp-gateway-${PLATFORM}.tar.gz"
    28|URL="${REPO}/releases/download/${VERSION}/${ARCHIVE}"
    29|
    30|echo "==> Installing OpenAFP ${VERSION} (${PLATFORM})"
    31|
    32|# create config dir
    33|mkdir -p "${CONFIG_DIR}"
    34|
    35|# download & extract
    36|TMPDIR=$(mktemp -d)
    37|trap "rm -rf ${TMPDIR}" EXIT
    38|
    39|echo "==> Downloading ${URL}"
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
    48|
    49|tar xzf "${TMPDIR}/${ARCHIVE}" -C "${TMPDIR}"
    50|
    51|# install binary (archive name varies by platform)
    52|BIN_FILE=$(ls "${TMPDIR}"/openafp-gateway* 2>/dev/null | head -1)
    53|if [ -z "$BIN_FILE" ]; then
    54|    echo "Error: cannot find openafp-gateway binary"
    55|    exit 1
    56|fi
    57|sudo mv "$BIN_FILE" "${BIN_DIR}/openafp-gateway"
    58|sudo chmod +x "${BIN_DIR}/openafp-gateway"
    59|
    60|# generate default config if not exists
    61|if [ ! -f "${CONFIG_DIR}/config.yaml" ]; then
    62|  cat > "${CONFIG_DIR}/config.yaml" << EOF
    63|server:
    64|    port: 51888
    65|    host: 0.0.0.0
    66|    enable_https: false
    67|    auth:
    68|        enabled: false
    69|        token: ""
    70|        ip_whitelist: []
    71|network:
    72|    mode: auto
    73|    listen_addrs:
    74|        - /ip4/0.0.0.0/tcp/51890
    75|        - /ip4/0.0.0.0/udp/51890/quic-v1
    76|    announce_addrs: []
    77|    bootstrap_peers:
    78|        - /dns4/bootstrap.openafp.net/tcp/51890/p2p/12D3KooWCqGHJoqY7466vegQ6dKzUNE5b3Lp5DArqaEbZJBcJgB8
    79|        - /dns4/relay-hk.openafp.net/tcp/51890/p2p/12D3KooWJ4PzqTdm72iX8wU5g5ZiMUdGB1f6mAru5gjdSCXvNHKy
    80|    enable_mdns: true
    81|    relay:
    82|        enabled: true
    83|        hop: false
    84|        addrs:
    85|            - /dns4/relay-cn.openafp.net/tcp/51890/p2p/12D3KooWCqGHJoqY7466vegQ6dKzUNE5b3Lp5DArqaEbZJBcJgB8
    86|            - /dns4/relay-hk.openafp.net/tcp/51890/p2p/12D3KooWJ4PzqTdm72iX8wU5g5ZiMUdGB1f6mAru5gjdSCXvNHKy
    87|database:
    88|    path: ${CONFIG_DIR}/openafp.db
    89|load_balance:
    90|    default_strategy: least_used
    91|circuit_breaker:
    92|    failure_threshold: 5
    93|    timeout_seconds: 60
    94|observability:
    95|    metrics:
    96|        enabled: false
    97|    tracing:
    98|        enabled: true
    99|    audit_log:
   100|        enabled: false
   101|a2a:
   102|    enabled: false
   103|compliance:
   104|    enabled: false
   105|security:
   106|    network:
   107|        allow_unencrypted_http: true
   108|agents: []
   109|agent:
   110|    local:
   111|        enabled: false
   112|capabilities: []
   113|EOF
   114|  echo "==> Default config created at ${CONFIG_DIR}/config.yaml"
   115|fi
   116|
   117|# generate identity key if not exists
   118|if [ ! -f "${CONFIG_DIR}/identity.key" ]; then
   119|  openssl rand -base64 32 > "${CONFIG_DIR}/identity.key" 2>/dev/null || \
   120|    head -c 32 /dev/urandom | base64 > "${CONFIG_DIR}/identity.key"
   121|  chmod 600 "${CONFIG_DIR}/identity.key"
   122|  echo "==> Identity key generated at ${CONFIG_DIR}/identity.key"
   123|fi
   124|
   125|echo ""
   126|echo "OpenAFP ${VERSION} installed successfully!"
   127|echo "  Binary: ${BIN_DIR}/openafp-gateway"
   128|echo "  Config: ${CONFIG_DIR}/config.yaml"
   129|echo ""
   130|echo "  To start: openafp-gateway --config ${CONFIG_DIR}/config.yaml"