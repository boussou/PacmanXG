#!/bin/bash
set -e

# Build script for PacmanXG on Arch Linux
# Requires: fpc, msegui (mseide-msegui) or msegui source

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Check / install dependencies ---
echo "=== Checking dependencies ==="

if ! command -v fpc &>/dev/null; then
    echo "Free Pascal Compiler (fpc) not found. Installing..."
    sudo pacman -S --needed --noconfirm fpc
fi

# MSEgui: check common install locations
MSEDIR=""
for candidate in \
    /usr/lib/mseide-msegui \
    /usr/local/lib/mseide-msegui \
    /opt/mseide-msegui \
    "$PWD/mseide-msegui" \
    "$HOME/mseide-msegui" \
    "$HOME/msegui"; do
    if [ -d "$candidate/lib" ]; then
        MSEDIR="$candidate/"
        break
    fi
done

if [ -z "$MSEDIR" ]; then
    echo "MSEgui libraries not found."
    echo ""
    echo "Install via AUR (e.g. with yay):"
    echo "  yay -S mseide-msegui"
    echo ""
    echo "Or clone manually:"
    echo "  git clone https://gitlab.com/mseide-msegui/mseide-msegui.git ~/mseide-msegui"
    echo ""
    echo "Then re-run this script."
    exit 1
fi

MSELIBDIR="${MSEDIR}lib/common/"
TARGETOSDIR="linux"

echo "=== Using MSEgui at: ${MSEDIR} ==="
echo "=== MSELIBDIR: ${MSELIBDIR} ==="

# --- Gather unit directories ---
# From the .prj file:
#   ${MSEDIR}lib/addon/*/
#   ${MSELIBDIR}kernel/$TARGETOSDIR/
#   ${MSELIBDIR}kernel/
#   ${MSELIBDIR}*/
UNIT_ARGS=""

# ${MSEDIR}lib/addon/*/
for d in "${MSEDIR}"lib/addon/*/; do
    [ -d "$d" ] && UNIT_ARGS+=" -Fu${d}"
done

# ${MSELIBDIR}kernel/linux/
[ -d "${MSELIBDIR}kernel/${TARGETOSDIR}" ] && \
    UNIT_ARGS+=" -Fu${MSELIBDIR}kernel/${TARGETOSDIR}/"

# ${MSELIBDIR}kernel/
[ -d "${MSELIBDIR}kernel" ] && \
    UNIT_ARGS+=" -Fu${MSELIBDIR}kernel/"

# ${MSELIBDIR}*/
for d in "${MSELIBDIR}"*/; do
    [ -d "$d" ] && UNIT_ARGS+=" -Fu${d}"
done

# Include paths (same as unit paths)
INC_ARGS=""
for d in "${MSELIBDIR}"*/; do
    [ -d "$d" ] && INC_ARGS+=" -Fi${d}"
done
[ -d "${MSELIBDIR}kernel/${TARGETOSDIR}" ] && \
    INC_ARGS+=" -Fi${MSELIBDIR}kernel/${TARGETOSDIR}/"
[ -d "${MSELIBDIR}kernel" ] && \
    INC_ARGS+=" -Fi${MSELIBDIR}kernel/"

# --- Compile ---
echo "=== Compiling pacmanxg ==="

cd "$SCRIPT_DIR"

fpc \
    -Mobjfpc \
    -Sh \
    -Fcutf8 \
    -O2 -XX -Xs -CX \
    $UNIT_ARGS \
    $INC_ARGS \
    -Fu"$SCRIPT_DIR" \
    -Fi"$SCRIPT_DIR" \
    -o"${SCRIPT_DIR}/pacmanxg" \
    "${SCRIPT_DIR}/pacmanxg.pas"

echo "=== Build successful: ${SCRIPT_DIR}/pacmanxg ==="
