#!/usr/bin/env bash

set -eo pipefail
shopt -s nullglob

root="$(realpath "$(dirname "$0")")"
projects=(01-wiredemo 02-blinky 03-walker 04-pipeline 05-serialtx lfsr)

max_len=0
for pr in "${projects[@]}"; do
    if [[ "${#pr}" -gt "$max_len" ]]; then
        max_len="${#pr}"
    fi
done

ok=()
failed=()

filter() {
    while read line; do printf "%-${max_len}s> %s\n" "$pr" "$line"; done
}

for pr in "${projects[@]}"; do
    cur_fail=0
    echo "=== $pr ===" >&2

    cd "$root/$pr"

    cur_fail=0
    if [[ -f CMakeLists.txt ]]; then
        (( cmake -GNinja -Bbuild -S. \
            && cmake --build build --clean-first \
            && build/V*) |& filter) || cur_fail=1
    fi

    for sby_file in *.sby; do
        sby="${sby_file%.sby}"
        (sby -f -d "verify.$sby" "$sby.sby" |& filter) || cur_fail=1
    done

    if [[ "$cur_fail" -eq 1 ]]; then
        echo "=== $pr FAILED ===" >&2
        failed+=("$pr")
    else
        echo "=== $pr ok ===" >&2
        ok+=("$pr")
    fi
done

echo "Ok     : (${#ok[@]}/${#projects[@]}) ${ok[*]}"
echo "Failed : (${#failed[@]}/${#projects[@]}) ${failed[*]}"

if [[ "${#failed[@]}" -gt 0 ]]; then
    exit 1
fi
