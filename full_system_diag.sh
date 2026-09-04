#!/data/data/com.termux/files/usr/bin/bash
set +e

HOME_DIR="$HOME"
OMNIS_DIR="$HOME/OMNIS"
OMNIS_MAIN="$HOME/omnis_v2.py"
CANON="$HOME/OMNIS_CANONICAL_FREEZE_20260827T150440Z/omnis_v2.py"
BACKUP="$HOME/OMNIS.bak.1787930612/omnis_v2.py"
SHOGUN_LAUNCHER="$HOME/SYSTEM_ORGANIZED/SCRIPTS/SHOGUN_LIVE_OPERATIONAL.sh"
OUT="$HOME/OMNIS/full_system_diag.out"

exec > >(tee "$OUT") 2>&1

section() {
    printf '\n\n============================================================\n'
    printf '=== %s ===\n' "$1"
    printf '============================================================\n'
}

show_file() {
    local f="$1"
    printf '\n--- %s ---\n' "$f"
    if [ -e "$f" ]; then
        stat "$f"
        sha256sum "$f" 2>&1
    else
        printf 'MISSING\n'
    fi
}

section "TIME / ENVIRONMENT"
date -u
printf 'HOME=%s\n' "$HOME"
printf 'PWD=%s\n' "$PWD"
printf 'PREFIX=%s\n' "$PREFIX"
printf 'TERMUX_VERSION=%s\n' "${TERMUX_VERSION:-unknown}"
python3 --version 2>&1
uname -a 2>&1

section "HOME DIRECTORIES"
find "$HOME" -maxdepth 2 -type d -print 2>/dev/null | sort

section "OMNIS FILES"
find "$OMNIS_DIR" -maxdepth 4 -type f -print 2>/dev/null | sort
show_file "$OMNIS_MAIN"
show_file "$CANON"
show_file "$BACKUP"
show_file "$OMNIS_DIR/omnis_v2.py"
show_file "$OMNIS_DIR/local_llm_proxy.py"
show_file "$OMNIS_DIR/omnis.log"
show_file "$HOME/omnis_v2.db"

section "OMNIS HASH COMPARISON"
for f in "$CANON" "$BACKUP" "$OMNIS_MAIN" "$OMNIS_DIR/omnis_v2.py"; do
    [ -f "$f" ] && sha256sum "$f"
done

section "OMNIS SOURCE STRUCTURE"
if [ -f "$OMNIS_MAIN" ]; then
    grep -nE \
        '^(@app\.|def |class )' \
        "$OMNIS_MAIN" 2>&1
fi

section "OMNIS DISCOVERY IMPLEMENTATION"
if [ -f "$OMNIS_MAIN" ]; then
    sed -n '240,430p' "$OMNIS_MAIN"
fi

section "OMNIS EXECUTION / MAIN"
if [ -f "$OMNIS_MAIN" ]; then
    tail -120 "$OMNIS_MAIN"
fi

section "OMNIS RUNNING PROCESS"
pgrep -af 'omnis_v2.py' 2>&1 || true
ps -ef 2>&1 | grep -E '[o]mnis_v2|[p]ython3' | head -100

section "OMNIS API"
for endpoint in \
    / \
    /health \
    /system \
    /modules \
    /capabilities \
    /agents \
    /events
do
    printf '\n--- GET %s ---\n' "$endpoint"
    curl -sS --max-time 5 \
        "http://127.0.0.1:5000$endpoint" 2>&1
    printf '\n'
done

section "OMNIS PORTS"
ss -ltnp 2>&1 | grep -E ':5000|:8000|python|omnis' || true
netstat -ltnp 2>&1 | grep -E ':5000|:8000|python|omnis' || true

section "OMNIS DATABASE"
if [ -f "$HOME/omnis_v2.db" ]; then
    sqlite3 "$HOME/omnis_v2.db" \
        '.tables' 2>&1
    sqlite3 "$HOME/omnis_v2.db" \
        '.schema' 2>&1
    sqlite3 "$HOME/omnis_v2.db" \
        'SELECT name FROM sqlite_master WHERE type="table" ORDER BY name;' \
        2>&1
fi

section "SYSTEM ORGANIZED"
find "$HOME/SYSTEM_ORGANIZED" \
    -maxdepth 5 -type f -print \
    2>/dev/null | sort | head -500

section "SHOGUN SEARCH"
find "$HOME" -maxdepth 6 \
    \( \
        -iname '*shogun*' \
        -o -iname 'reasoning_v6_live.py' \
        -o -iname 'v4_complete_observations.json' \
        -o -iname 'WATCH.sh' \
        -o -iname 'SHOGUN_LIVE_OPERATIONAL.sh' \
    \) \
    -print 2>/dev/null | sort | head -1000

section "SHOGUN LAUNCHER"
show_file "$SHOGUN_LAUNCHER"
if [ -f "$SHOGUN_LAUNCHER" ]; then
    cat "$SHOGUN_LAUNCHER"
fi

section "SHOGUN REFERENCED PATHS"
if [ -f "$SHOGUN_LAUNCHER" ]; then
    grep -nE \
        'ROOT=|DEEP_RECON=|LOG=|V4=|TMP_OUT=|python3|reasoning|adapter|KATANA|BEACON|VACUUM|TAI_CHI|GOD_HAND|sleep' \
        "$SHOGUN_LAUNCHER" 2>&1
fi

section "DEEP RECON"
if [ -d "$HOME/deep_recon" ]; then
    find "$HOME/deep_recon" \
        -maxdepth 4 -type f -print \
        2>/dev/null | sort | head -1000
else
    printf 'MISSING: %s\n' "$HOME/deep_recon"
fi

section "T PRAO L4"
if [ -d "$HOME/T_PRAO_L4" ]; then
    find "$HOME/T_PRAO_L4" \
        -maxdepth 5 -type f -print \
        2>/dev/null | sort | head -1000
else
    printf 'MISSING: %s\n' "$HOME/T_PRAO_L4"
fi

section "RUNTIME PROCESSES"
ps -ef 2>&1 | grep -E \
    '[K]ATANA|[B]EACON|[V]ACUUM|[T]AI_CHI|[G]OD_HAND|[W]HALE|[R]ESURRECT|[S]HOGUN|[T]_PRAO|[O]MNIS' \
    || true

section "BACKGROUND JOBS"
jobs -l 2>&1

section "STARTUP REFERENCES"
for f in \
    "$HOME/.bashrc" \
    "$HOME/.profile" \
    "$HOME/.bash_profile"
do
    if [ -f "$f" ]; then
        printf '\n--- %s ---\n' "$f"
        grep -nEi \
            'SHOGUN|OMNIS|T_PRAO|WATCH|deep_recon' \
            "$f" 2>&1 || true
    fi
done

section "SHELL SCRIPTS IN HOME"
find "$HOME" -maxdepth 3 -type f -name '*.sh' \
    -print 2>/dev/null | sort

section "DATABASES"
find "$HOME" -maxdepth 5 -type f \
    \( -name '*.db' -o -name '*.sqlite' -o -name '*.sqlite3' \) \
    -print 2>/dev/null | sort

section "LOGS"
find "$HOME" -maxdepth 5 -type f \
    \( -name '*.log' -o -name '*.jsonl' \) \
    -print 2>/dev/null | sort | head -1000

section "RECENT ACTIVITY"
find "$HOME" -maxdepth 5 -type f -mmin -1440 \
    -printf '%TY-%Tm-%Td %TH:%TM:%TS %p\n' \
    2>/dev/null | sort -r | head -500

section "TARGETED SHOGUN FILE CHECK"
for f in \
    "$HOME/SHOGUN_OS" \
    "$HOME/SHOGUN_OS/08_INTELLIGENCE" \
    "$HOME/SHOGUN_OS/08_INTELLIGENCE/reasoning_v6_live.py" \
    "$HOME/SHOGUN_OS/08_INTELLIGENCE/v4_complete_observations.json" \
    "$HOME/deep_recon/adapters/adapter_v2_complete.py" \
    "$HOME/deep_recon/KATANA.py" \
    "$HOME/deep_recon/BEACON.py" \
    "$HOME/deep_recon/BEACON_MEGA.py" \
    "$HOME/deep_recon/VACUUM.py" \
    "$HOME/deep_recon/LIVE_VACUUM.py" \
    "$HOME/deep_recon/TAI_CHI.py" \
    "$HOME/deep_recon/GOD_HAND.py"
do
    show_file "$f"
done

section "DONE"
printf 'DIAGNOSTIC OUTPUT: %s\n' "$OUT"
printf 'NO SYSTEM FILES WERE MODIFIED.\n'
