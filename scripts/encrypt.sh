#!/bin/bash
# Encrypt every HTML page in public-encrypted/ and write the locked version
# into the matching folder at the repo root (which is what GitHub Pages serves).
#
#   public-encrypted/reports/ceo-weekly.html   ->   reports/ceo-weekly.html
#
# Each page gets its own password, derived from the master secret in .env plus
# the file's path. Same file always gets the same password.
#
# Run it yourself with:  ./scripts/encrypt.sh
# It also runs automatically on every commit via the pre-commit hook.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$REPO_ROOT/public-encrypted"
STATICRYPT="$HOME/.claude/tools/node_modules/.bin/staticrypt"

if [ ! -x "$STATICRYPT" ]; then
  echo "ERROR: StatiCrypt not found at $STATICRYPT" >&2
  echo "Reinstall with: mkdir -p ~/.claude/tools && cd ~/.claude/tools && npm install staticrypt" >&2
  exit 1
fi

if [ ! -f "$REPO_ROOT/.env" ]; then
  echo "ERROR: .env not found. It holds the master encryption secret." >&2
  exit 1
fi

set -a; source "$REPO_ROOT/.env"; set +a

if [ -z "${STATICRYPT_MASTER_SECRET:-}" ] || [ -z "${STATICRYPT_SALT:-}" ]; then
  echo "ERROR: STATICRYPT_MASTER_SECRET or STATICRYPT_SALT missing from .env" >&2
  exit 1
fi

if [ ! -d "$SRC_DIR" ]; then
  echo "Nothing to encrypt: public-encrypted/ does not exist."
  exit 0
fi

# Derive this page's password from the master secret + its path.
derive_password() {
  printf '%s' "$1" \
    | openssl dgst -sha256 -hmac "$STATICRYPT_MASTER_SECRET" -hex \
    | sed 's/^.*= *//' \
    | cut -c1-16
}

count=0
while IFS= read -r -d '' src; do
  rel="${src#"$SRC_DIR/"}"                 # e.g. reports/ceo-weekly.html
  out_dir="$REPO_ROOT/$(dirname "$rel")"   # e.g. <repo>/reports
  password="$(derive_password "$rel")"

  mkdir -p "$out_dir"

  "$STATICRYPT" "$src" \
    --password "$password" \
    --salt "$STATICRYPT_SALT" \
    --config false \
    --directory "$out_dir" \
    --remember 30 \
    --short \
    --template-title "Protected report" \
    --template-instructions "This page is password protected. Enter the password you were sent." \
    --template-button "View report" \
    --template-color-primary "#1f4e79" \
    --template-color-secondary "#f4f6f8" \
    --template-error "That password isn't right." \
    >/dev/null

  echo "  encrypted  $rel"
  count=$((count + 1))
done < <(find "$SRC_DIR" -type f -name '*.html' -print0 | sort -z)

if [ "$count" -eq 0 ]; then
  echo "Nothing to encrypt: no .html files in public-encrypted/."
else
  echo "$count page(s) encrypted. Run ./scripts/passwords.sh to see the passwords."
fi
