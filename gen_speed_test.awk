#!/usr/bin/awk -f
BEGIN {
  for (i=0; i<N; i++) {
    printf "Test #%d\n", i
    printf "$ echo aaa%d; echo bbb%d; echo ccc%d >&2; exit %d\n", i, i, i, (exitCode = i % 128)
    printf "| aaa%d\n", i
    printf "| bbb%d\n", i
    printf "@ ccc%d\n", i
    if (exitCode) printf "? %d\n", exitCode
    print
  }
}