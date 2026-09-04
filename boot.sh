#!/data/data/com.termux/files/usr/bin/bash
set -e

BASE="$HOME/OMNIS_V3"
START="$BASE/start.sh"
RUNTIME="$BASE/data/runtime"
PIDFILE="$RUNTIME/omnis_runtime.pid"
LOCKDIR="$RUNTIME/omnis_runtime.lock"
LOG="$RUNTIME/omnis_boot.log"

mkdir -p "$RUNTIME"

if [ ! -x "$START" ]; then
    exit 1
fi

# ----------------------------------------------------------
# Start supervisor completely detached from this shell.
# ----------------------------------------------------------

nohup "$START" >> "$LOG" 2>&1 < /dev/null &

BOOT_PID=$!

disown "$BOOT_PID" 2>/dev/null || true

# ----------------------------------------------------------
# Wait only for registration.
# Never attach supervisor output to interactive terminal.
# ----------------------------------------------------------

REGISTERED_PID=""

for _ in $(seq 1 50); do

    if [ -f "$PIDFILE" ]; then
        REGISTERED_PID="$(cat "$PIDFILE" 2>/dev/null || true)"

        if [[ "$REGISTERED_PID" =~ ^[0-9]+$ ]] &&
           [ -d "/proc/$REGISTERED_PID" ]; then
            break
        fi
    fi

    sleep 0.1
done

if ! [[ "$REGISTERED_PID" =~ ^[0-9]+$ ]]; then
    exit 1
fi

if [ ! -d "/proc/$REGISTERED_PID" ]; then
    exit 1
fi

if [ ! -d "$LOCKDIR" ]; then
    exit 1
fi

exit 0
