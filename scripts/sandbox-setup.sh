#!/usr/bin/env bash
set -euo pipefail

# Setup script for developing luminal in a sandbox without GPU access.
# Installs Rust, checks tools, and runs a build+test smoke to verify.

MIN_RUST="1.91"

log() { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33mWARN: %s\033[0m\n' "$*"; }
die() { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# --- Rust ---
install_rust() {
    log "Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
    # shellcheck source=/dev/null
    . "$HOME/.cargo/env"
}

if ! command -v rustc &>/dev/null; then
    install_rust
elif ! command -v rustup &>/dev/null; then
    warn "rustc found but rustup is missing — installing rustup to manage toolchains"
    install_rust
fi

# Source cargo env in case it was just installed
if [ -f "$HOME/.cargo/env" ]; then
    # shellcheck source=/dev/null
    . "$HOME/.cargo/env"
fi

# Ensure minimum version
RUST_VER=$(rustc --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
log "Rust version: $RUST_VER (minimum: $MIN_RUST)"

version_ge() {
    printf '%s\n%s' "$1" "$2" | sort -V | head -n1 | grep -qx "$2"
}

if ! version_ge "$RUST_VER" "$MIN_RUST"; then
    log "Rust $RUST_VER is below minimum $MIN_RUST — updating..."
    rustup update stable
    RUST_VER=$(rustc --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    version_ge "$RUST_VER" "$MIN_RUST" || die "Could not get Rust >= $MIN_RUST (got $RUST_VER)"
fi

# --- Git ---
command -v git &>/dev/null || die "git is required (for egglog git dependency)"

# --- C compiler (transitive build dep via the cc crate, used by egglog) ---
if ! command -v cc &>/dev/null && ! command -v gcc &>/dev/null && ! command -v clang &>/dev/null; then
    log "No C compiler found — attempting to install one..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y -qq build-essential
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y gcc
    elif command -v yum &>/dev/null; then
        sudo yum install -y gcc
    elif command -v apk &>/dev/null; then
        apk add --no-cache build-base
    elif command -v brew &>/dev/null; then
        # macOS: Xcode CLI tools provide cc
        xcode-select --install 2>/dev/null || true
    else
        die "No C compiler found and no known package manager to install one. Install gcc or clang manually."
    fi
fi
command -v cc &>/dev/null || command -v gcc &>/dev/null || command -v clang &>/dev/null \
    || die "C compiler still not available after install attempt"
log "C compiler: $(cc --version 2>/dev/null | head -1 || gcc --version 2>/dev/null | head -1 || clang --version 2>/dev/null | head -1)"

# --- Python dev headers (needed by PyO3 crates: luminal_reference_py, luminal_cuda_lite_py) ---
HAS_PYTHON_DEV=false
if command -v python3 &>/dev/null; then
    log "Python found: $(python3 --version)"
    if python3 -c "import sysconfig; assert sysconfig.get_path('include')" 2>/dev/null \
       && [ -f "$(python3 -c 'import sysconfig; print(sysconfig.get_path("include"))')/Python.h" ]; then
        HAS_PYTHON_DEV=true
        log "Python dev headers found"
    else
        log "Python dev headers missing — attempting to install..."
        if command -v apt-get &>/dev/null; then
            sudo apt-get install -y -qq python3-dev 2>/dev/null && HAS_PYTHON_DEV=true
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y python3-devel 2>/dev/null && HAS_PYTHON_DEV=true
        fi
        $HAS_PYTHON_DEV || warn "Could not install Python dev headers — PyO3 crates will be excluded from clippy"
    fi
    if ! command -v ruff &>/dev/null; then
        log "Installing ruff for Python linting..."
        pip3 install --quiet ruff 2>/dev/null || warn "Could not install ruff — pytorch linting will be unavailable"
    fi
else
    warn "Python not found — PyO3 crates will be excluded from clippy, pytorch linting unavailable"
fi

# --- Workspace packages that build without a GPU ---
CPU_PACKAGES=(
    -p luminal
    -p luminal_reference
    -p luminal_nn
    -p model_zoo
    -p luminal_tracing
    -p luminal_pytorch_utils
    -p test_runtime
)

# --- Build check ---
log "Building CPU workspace packages..."
cargo build "${CPU_PACKAGES[@]}" 2>&1

# --- Clippy ---
log "Running clippy (excluding GPU crates)..."
cargo clippy --workspace \
    --exclude luminal_cuda_lite \
    --exclude luminal_metal \
    --all-targets -- -D warnings 2>&1

# --- Fmt check ---
log "Checking formatting..."
cargo fmt --all --check 2>&1 || {
    warn "Formatting issues found — running cargo fmt to fix"
    cargo fmt --all
}

# --- Quick smoke test ---
log "Running core unit tests (spin tier)..."
cargo test -p luminal --lib 2>&1

log "Setup complete. Quick reference:"
cat <<'HELP'

  Development tiers (no GPU needed):

    Spin (fast iteration on core):
      cargo test -p luminal --lib

    Spin + proof of life (core + reference runtime):
      cargo test -p luminal --lib
      cargo test -p luminal_reference --lib

    Landing (full CPU suite, before committing):
      cargo test --release -p luminal -p luminal_reference -p luminal_nn \
        -p model_zoo -p test_runtime -p luminal_tracing -p luminal_pytorch_utils

    Clippy (excludes GPU crates):
      cargo clippy --workspace --exclude luminal_cuda_lite --exclude luminal_metal --all-targets -- -D warnings

    Format:
      cargo fmt --all

  GPU crates (luminal_cuda_lite, luminal_metal) are excluded — they
  require actual GPU hardware to build and test.
HELP
