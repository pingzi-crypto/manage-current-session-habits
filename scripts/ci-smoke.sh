#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SKILL_REPO_PATH=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
BACKEND_REPO_PATH=""
CODEX_HOME_VALUE=""
SKIP_REPO_MODE=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --skill-repo-path)
      SKILL_REPO_PATH=$2
      shift 2
      ;;
    --backend-repo-path)
      BACKEND_REPO_PATH=$2
      shift 2
      ;;
    --codex-home)
      CODEX_HOME_VALUE=$2
      shift 2
      ;;
    --skip-repo-mode)
      SKIP_REPO_MODE=1
      shift 1
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

SKILL_REPO_PATH=$(CDPATH= cd -- "$SKILL_REPO_PATH" && pwd)

if [ -z "$CODEX_HOME_VALUE" ]; then
  CODEX_HOME_VALUE=$(mktemp -d "${TMPDIR:-/tmp}/manage-current-session-habits-ci-XXXXXX")
fi

cleanup() {
  rm -rf "$CODEX_HOME_VALUE"
}
trap cleanup EXIT

export CODEX_HOME="$CODEX_HOME_VALUE"

echo "package-mode install + smoke"
bash "$SKILL_REPO_PATH/install.sh" --force-relink

echo "package-mode refresh + smoke"
bash "$SKILL_REPO_PATH/install.sh" --force-relink

echo "package-mode uninstall"
bash "$SKILL_REPO_PATH/uninstall.sh"

if [ "$SKIP_REPO_MODE" -eq 0 ]; then
  if [ -z "$BACKEND_REPO_PATH" ]; then
    echo "Repo-mode smoke requires --backend-repo-path unless --skip-repo-mode is set." >&2
    exit 1
  fi

  echo "repo-mode install + smoke"
  bash "$SKILL_REPO_PATH/install.sh" --backend-repo-path "$BACKEND_REPO_PATH" --force-relink

  echo "repo-mode uninstall"
  bash "$SKILL_REPO_PATH/uninstall.sh"
fi
