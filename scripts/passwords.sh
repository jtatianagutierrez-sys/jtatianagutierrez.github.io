#!/bin/bash
# Show the live URL and password for every page in public-encrypted/.
# Nothing is re-encrypted; the passwords are just re-derived from .env.
#
# Run with:  ./scripts/passwords.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$REPO_ROOT/public-encrypted"
BASE_URL="https://jtatianagutierrez-sys.github.io/jtatianagutierrez.github.io"

if [ ! -f "$REPO_ROOT/.env" ]; then
  echo "ERROR: .env not found. It holds the master encryption secret." >&2
  exit 1
fi

set -a; source "$REPO_ROOT/.env"; set +a

if [ ! -d "$SRC_DIR" ]; then
  echo "No public-encrypted/ folder yet."
  exit 0
fi

found=0
while IFS= read -r -d '' src; do
  rel="${src#"$SRC_DIR/"}"
  password="$(printf '%s' "$rel" \
    | openssl dgst -sha256 -hmac "$STATICRYPT_MASTER_SECRET" -hex \
    | sed 's/^.*= *//' \
    | cut -c1-16)"

  echo ""
  echo "$rel"
  echo "  URL:      $BASE_URL/$rel"
  echo "  Password: $password"
  found=$((found + 1))
done < <(find "$SRC_DIR" -type f -name '*.html' -print0 | sort -z)

if [ "$found" -eq 0 ]; then
  echo "No .html files in public-encrypted/ yet."
else
  echo ""
  echo "Send the URL and the password in separate messages."
fi
