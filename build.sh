#!/bin/sh

set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

compiler=${FPC:-fpc}

# Ask the compiler for its effective target, including any cross flags.
set --
if [ -n "${FPCARCH:-}" ]; then
  set -- "$@" "-P$FPCARCH"
fi
if [ -n "${FPCOS:-}" ]; then
  set -- "$@" "-T$FPCOS"
fi

target_os=$("$compiler" "$@" -iTO)
target_cpu=$("$compiler" "$@" -iTP)
case "$target_os" in
  ''|*[!a-zA-Z0-9_-]*) echo "Invalid FPC target OS: $target_os" >&2; exit 1 ;;
esac
case "$target_cpu" in
  ''|*[!a-zA-Z0-9_-]*) echo "Invalid FPC target CPU: $target_cpu" >&2; exit 1 ;;
esac

build_dir="$project_dir/build/$target_os-$target_cpu"
mkdir -p "$build_dir"

set -- "$@" -B -Mdelphi -O3 -Fucommon "-FU$build_dir" "-FE$build_dir"

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
  "$project_dir/src/lxlite.rc" "$build_dir/lxlite-fpc.rc"

python3 "$project_dir/src/convert_os2_rc.py" \
  "$project_dir/src/os2api.rc" "$build_dir/os2api-fpc.rc"

"$resource_compiler" -of res "$build_dir/lxlite-fpc.rc" \
  -o "$project_dir/src/lxlite.res"

"$resource_compiler" -of res "$build_dir/os2api-fpc.rc" \
  -o "$project_dir/src/os2api.res"

(cd "$project_dir/src" && "$compiler" "$@" lxLite.pas)

cp "$project_dir/contrib/lxLite.cfg" "$build_dir/lxLite.cfg"

printf 'lxLite (%s-%s): %s\n' "$target_os" "$target_cpu" "$build_dir/lxLite"
