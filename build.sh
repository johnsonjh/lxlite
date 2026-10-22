#!/bin/sh

set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

compiler=${FPC:-fpc}

mkdir -p "$project_dir/build/linux"

set -- -B -Mdelphi -O2 -Fucommon -FU../build/linux -FE../build/linux

if [ -n "${FPC_UNIT_ROOT:-}" ]; then
  set -- "$@" -n \
    "-Fu$FPC_UNIT_ROOT/rtl" \
    "-Fu$FPC_UNIT_ROOT/rtl-console" \
    "-Fu$FPC_UNIT_ROOT/rtl-objpas" \
    "-Fu$FPC_UNIT_ROOT/rtl-extra" \
    "-Fu$FPC_UNIT_ROOT/fv"
fi

if [ -n "${FPC_TOOL_DIR:-}" ]; then
  set -- "$@" "-FD$FPC_TOOL_DIR"
  resource_compiler="$FPC_TOOL_DIR/fpcres"
else
  resource_compiler=${FPCRES:-fpcres}
fi

python3 "$project_dir/src/convert_os2_rc.py" \
  "$project_dir/src/lxlite.rc" "$project_dir/build/linux/lxlite-fpc.rc"

python3 "$project_dir/src/convert_os2_rc.py" \
  "$project_dir/src/os2api.rc" "$project_dir/build/linux/os2api-fpc.rc"

"$resource_compiler" -of res "$project_dir/build/linux/lxlite-fpc.rc" \
  -o "$project_dir/src/lxlite.res"

"$resource_compiler" -of res "$project_dir/build/linux/os2api-fpc.rc" \
  -o "$project_dir/src/os2api.res"

(cd "$project_dir/src" && "$compiler" "$@" lxLite.pas)

cp "$project_dir/contrib/lxLite.cfg" "$project_dir/build/linux/lxLite.cfg"

printf 'Linux lxLite: %s\n' "$project_dir/build/linux/lxLite"
