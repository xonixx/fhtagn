#!/bin/sh
# trims blank lines but preserves exit code

o=$(mktemp)
e=$(mktemp)

( "$@" ) 1>"$o" 2>"$e"

err=$?

awkScript='{ print NF ? $0 : "---blank---" }'

awk "$awkScript" "$o"
awk "$awkScript" "$e" >&2

rm "$o" "$e"

exit $err