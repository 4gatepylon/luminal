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

# --- Optional: Python + ruff (for pytorch crate linting) ---
if command -v python3 &>/dev/null; then
    log "Python found: $(python3 --version)"
    if ! command -v ruff &>/dev/null; then
        log "Installing ruff for Python linting..."
        pip3 install --quiet ruff 2>/dev/null || warn "Could not install ruff — pytorch linting will be unavailable"
    fi
else
    warn "Python not found — pytorch crate linting will be unavailable (not required for core development)"
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
