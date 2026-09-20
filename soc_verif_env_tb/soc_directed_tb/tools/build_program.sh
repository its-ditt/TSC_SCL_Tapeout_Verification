#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
python3 "$ROOT/tools/assemble_rv32i.py" \
    "$ROOT/programs/rv32i_directed.S" \
    "$ROOT/programs/program.hex"
cp "$ROOT/programs/program_image.svh" "$ROOT/tb/program_image.svh"
