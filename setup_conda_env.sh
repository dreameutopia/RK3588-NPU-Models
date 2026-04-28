#!/usr/bin/env bash
set -euo pipefail

MINICONDA_DIR="${MINICONDA_DIR:-$HOME/miniconda3}"
ENV_NAME="${ENV_NAME:-rknn3}"
PYTHON_VERSION="${PYTHON_VERSION:-3.10}"
INSTALLER_NAME="${INSTALLER_NAME:-Miniconda3-latest-Linux-x86_64.sh}"
INSTALLER_URL="https://repo.anaconda.com/miniconda/${INSTALLER_NAME}"
CONDA_BIN="${MINICONDA_DIR}/bin/conda"

log() {
  echo "[setup] $*"
}

log "MINICONDA_DIR=${MINICONDA_DIR}"
log "ENV_NAME=${ENV_NAME}"
log "PYTHON_VERSION=${PYTHON_VERSION}"

if [[ ! -x "${CONDA_BIN}" ]]; then
  log "Miniconda not found, start install"
  if [[ ! -f "${INSTALLER_NAME}" ]]; then
    log "Downloading installer: ${INSTALLER_URL}"
    wget -O "${INSTALLER_NAME}" "${INSTALLER_URL}"
  else
    log "Installer already exists: ${INSTALLER_NAME}"
  fi

  log "Installing Miniconda to ${MINICONDA_DIR}"
  bash "${INSTALLER_NAME}" -b -p "${MINICONDA_DIR}"
else
  log "Miniconda already installed, skip install"
fi

log "Initialize conda for bash"
"${CONDA_BIN}" init bash

if command -v zsh >/dev/null 2>&1; then
  log "Initialize conda for zsh"
  "${CONDA_BIN}" init zsh
else
  log "zsh not found, skip conda init zsh"
fi

if "${CONDA_BIN}" tos --help >/dev/null 2>&1; then
  log "Accept conda ToS channels"
  "${CONDA_BIN}" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
  "${CONDA_BIN}" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
else
  log "Current conda has no tos command, skip ToS acceptance"
fi

if "${CONDA_BIN}" env list | awk '{print $1}' | grep -qx "${ENV_NAME}"; then
  log "Conda env ${ENV_NAME} already exists, skip create"
else
  log "Create conda env: ${ENV_NAME} (python=${PYTHON_VERSION})"
  "${CONDA_BIN}" create -n "${ENV_NAME}" "python=${PYTHON_VERSION}" -y
fi

log "Validate python in env"
"${CONDA_BIN}" run -n "${ENV_NAME}" python -V

cat <<EOF

Done.

Next step in current shell:
  source "${MINICONDA_DIR}/etc/profile.d/conda.sh"
  conda activate "${ENV_NAME}"

If you use zsh, restart shell or run:
  source ~/.zshrc

EOF