#!/usr/bin/env bash

# =========================
# DevOps Automated Deploy Script
# =========================
# Logs: deploy.log (appends)
# Requires: .env in working directory with REPO_XXX variables
# Usage: ./setup.sh
# =========================

set -euo pipefail

LOG_FILE="$(pwd)/deploy.log"
ENV_FILE=".env"

RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
  local tag="$1"
  local msg="$2"
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo -e "${ts} [${tag}] ${msg}" | tee -a "${LOG_FILE}"
}

log_success() { log "SUCCESS" "$1"; }
log_info()    { log "INFO" "$1"; }
log_error()   { echo -e "${RED}$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1${NC}" | tee -a "${LOG_FILE}"; }
log_warn() {
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "$timestamp [WARN] $*"
}

# -------- Handle Ctrl+C gracefully --------
trap 'on_interrupt' INT

on_interrupt() {
  echo
  log_warn "Script interrupted by user (Ctrl+ C). Exiting."
  exit 130 
}

# -------- Load .env file and export variables --------
load_env() {
  if [[ ! -f "$ENV_FILE" ]]; then
    log_error ".env file missing in current directory. Exiting."
    exit 1
  fi
  set -a
  source "$ENV_FILE"
  set +a
  log_success ".env file loaded successfully."
}

# -------- Verify config variables --------
verify_config() {
  if [[ -z "${REPO_SSH_URI:-}" || -z "${REPO_DIR:-}" || -z "${JAR_PATH:-}" ]]; then
    log_error "One or more required variables (REPO_SSH_URI, REPO_DIR, JAR_PATH) are missing from .env."
    exit 1
  fi
  log_success "All required environment variables are set."
}

# -------- Check ssh-agent Running & Key Loaded --------
check_github_ssh() {
  log_info "Testing SSH key against GitHub"
  SSH_TEST_OUTPUT=$(ssh -T git@github.com 2>&1 || true)
  echo "$SSH_TEST_OUTPUT" >>"$LOG_FILE"

  if echo "$SSH_TEST_OUTPUT" | grep -q "successfully authenticated"; then
    log_success "SSH authentication to GitHub succeeded."
  else
    log_error "SSH authentication to GitHub via SSH failed.
Please ensure:
- Your SSH key is loaded into your agent (ssh-add ~/.ssh/<yourkey>)
- The public key is added to your GitHub account (https://github.com/settings/keys)
- Your SSH agent is active in this terminal (eval \$(ssh-agent))
See deploy.log for full SSH output."
    exit 1
  fi
}

# -------- Check for git --------
check_git() {
  if ! command -v git >/dev/null 2>&1; then
    log_error "git not found. Please install git and rerun this script."
    exit 1
  fi
  log_success "git is present."
}

# -------- Clone or Update Repo --------
clone_or_update_repo() {
  if [[ -d "$REPO_DIR" ]]; then
    log_info "Repository directory exists: $REPO_DIR. Attempting git pull."
    cd "$REPO_DIR"
    if ! git pull --rebase=false; then
      log_error "git pull failed (possibly due to merge conflict). Resolve conflicts and rerun."
      exit 1
    fi
    cd ..
    log_success "git pull successful."
  else
    if ! git clone "$REPO_SSH_URI" "$REPO_DIR"; then
      log_error "git clone failed. Check repository URL and your SSH setup."
      exit 1
    fi
    log_success "Repository cloned successfully into $REPO_DIR."
  fi
}

# -------- Java Version Detection (best effort, fragile can fail for different setups) --------
detect_java_version() {
  local ver=""
  if [[ -f "$REPO_DIR/.java-version" ]]; then
    ver=$(head -n1 "$REPO_DIR/.java-version" | tr -d '\n')
  elif [[ -n $(find "$REPO_DIR" -name build.gradle -print -quit) ]]; then
      gradle_file=$(find "$REPO_DIR" -name build.gradle -print -quit)
      ver=$(grep -E 'sourceCompatibility|targetCompatibility|JavaLanguageVersion\.of' "$gradle_file" | grep -oE '[0-9]+' | head -1)
  elif [[ -f "$REPO_DIR/pom.xml" ]]; then
    ver=$(grep -oPm1 "(?<=<java.version>)[^<]+" "$REPO_DIR/pom.xml")
  fi
  if [[ -n "$ver" ]]; then
    log_info "Detected Java version requirement: $ver"
  else
    log_info "Could not determine Java version from project files."
  fi
}

# -------- Check Java Installation --------
check_java() {
  if ! command -v java >/dev/null 2>&1; then
    log_error "Java not found. Please install the required Java version and rerun."
    exit 1
  fi
  JAVA_VER=$(java -version 2>&1 | head -n 1)
  log_success "Detected local Java: $JAVA_VER"
}

# -------- Check for JAR file --------
check_jar() {
  if [[ ! -f "$REPO_DIR/$JAR_PATH" ]]; then
    log_error "JAR file not found at $REPO_DIR/$JAR_PATH. Exiting."
    exit 1
  fi
  log_success "JAR file found: $REPO_DIR/$JAR_PATH"
}

# -------- Start Java Program --------
start_java() {
  log_info "Starting Java process: java -jar $JAR_PATH"
  cd "$REPO_DIR"
  if ! java -jar "$JAR_PATH"; then
    log_error "Failed to start Java process. Check logs or error output above."
    exit 1
  fi
  log_success "Java process completed (exited normally)."
  cd ..
}

# -------- Main --------
main() {
  load_env
  verify_config
  check_github_ssh
  check_git
  clone_or_update_repo
  detect_java_version
  check_java
  check_jar
  start_java
  log_info "Script execution complete."
}

main "$@"