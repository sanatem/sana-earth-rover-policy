#!/usr/bin/env bash
# Full setup: venv + torch + the vendored packages (genie, traversability).
# The Earth Rovers SDK is an external service and is not managed here.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Python environment"
if [ -n "${VIRTUAL_ENV:-}" ]; then
  # An environment is already active (e.g. `pyenv activate venv313`): use it.
  VENV="$VIRTUAL_ENV"
  echo "    using the active environment: $VENV"
else
  # Python 3.10-3.13: newer breaks the SDK deps build (pydantic-core) and
  # torch may not have wheels yet. Override with PYTHON=<interpreter>.
  if [ -z "${PYTHON:-}" ]; then
    for cand in python3.13 python3.12 python3.11 python3.10 python3; do
      if command -v "$cand" >/dev/null 2>&1 \
         && "$cand" -c 'import sys; sys.exit(0 if (3,10) <= sys.version_info < (3,14) else 1)' 2>/dev/null; then
        PYTHON="$cand"
        break
      fi
    done
  fi
  [ -n "${PYTHON:-}" ] || { echo "No Python 3.10-3.13 found (install one or pass PYTHON=)"; exit 1; }
  "$PYTHON" -c 'import sys; sys.exit(0 if (3,10) <= sys.version_info < (3,14) else 1)' \
    || { echo "Python 3.10-3.13 required (PYTHON=$PYTHON)"; exit 1; }
  echo "    creating .venv with $PYTHON ($("$PYTHON" --version 2>&1))"
  [ -d .venv ] || "$PYTHON" -m venv .venv
  VENV="$PWD/.venv"
fi
PIP="$VENV/bin/pip"
"$PIP" install --quiet --upgrade pip

echo "==> dependencies (torch takes a while the first time)"
"$PIP" install torch torchvision
"$PIP" install -e ./genie
"$PIP" install -e "./traversability[hf]"

echo
echo "Done (environment: $VENV). Next steps:"
echo "  1. Start Earth Rovers SDK v6.2+ separately (default: http://localhost:8000)"
echo "  2. $VENV/bin/python missions/level2.py --dry-run   # no rover movement"
