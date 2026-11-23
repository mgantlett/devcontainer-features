#!/usr/bin/env sh
set -eu

VERSION="${VERSION:-latest}"
REPO="mgantlett/nomos"

ensure_tools() {
    if command -v curl >/dev/null 2>&1 && command -v tar >/dev/null 2>&1 && command -v sha256sum >/dev/null 2>&1; then
        return 0
    fi
    if command -v apt-get >/dev/null 2>&1; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        apt-get install -y --no-install-recommends ca-certificates curl tar coreutils
        rm -rf /var/lib/apt/lists/*
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache ca-certificates curl tar coreutils
    elif command -v microdnf >/dev/null 2>&1; then
        microdnf install -y ca-certificates curl tar coreutils
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y ca-certificates curl tar coreutils
    fi
}

resolve_tag() {
    req="$1"
    if [ "$req" = "latest" ] || [ -z "$req" ]; then
        eff="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/${REPO}/releases/latest")"
        tag="${eff##*/}"
        case "$tag" in
            v[0-9]*) printf '%s\n' "$tag" ;;
            *) echo "Failed to resolve latest release tag from ${eff}" >&2; exit 1 ;;
        esac
        return 0
    fi
    case "$req" in
        v*) printf '%s\n' "$req" ;;
        *) printf 'v%s\n' "$req" ;;
    esac
}

resolve_arch() {
    m="$(uname -m)"
    case "$m" in
        x86_64|amd64) printf 'x86_64\n' ;;
        aarch64|arm64) printf 'arm64\n' ;;
        *) echo "Unsupported architecture: $m" >&2; exit 1 ;;
    esac
}

ensure_tools
TAG="$(resolve_tag "$VERSION")"
ARCH="$(resolve_arch)"
ASSET="nomos_Linux_${ARCH}.tar.gz"
BASE_URL="https://github.com/${REPO}/releases/download/${TAG}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fsSL "${BASE_URL}/${ASSET}" -o "${TMP_DIR}/${ASSET}"
curl -fsSL "${BASE_URL}/checksums.txt" -o "${TMP_DIR}/checksums.txt"

EXPECTED="$(awk -v a="$ASSET" '$2 == a || $2 == ("*" a) { print $1; exit }' "${TMP_DIR}/checksums.txt")"
if [ -z "$EXPECTED" ]; then
    echo "Missing SHA-256 entry for ${ASSET} in checksums.txt (${TAG})" >&2
    exit 1
fi

ACTUAL="$(sha256sum "${TMP_DIR}/${ASSET}" | awk '{print $1}')"
if [ "$EXPECTED" != "$ACTUAL" ]; then
    echo "SHA-256 mismatch for ${ASSET}: expected ${EXPECTED}, got ${ACTUAL}" >&2
    exit 1
fi

tar -xzf "${TMP_DIR}/${ASSET}" -C "$TMP_DIR" nomos
install -m 0755 "${TMP_DIR}/nomos" /usr/local/bin/nomos
/usr/local/bin/nomos version
