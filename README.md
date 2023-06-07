# fhtagn

[![Run tests](https://github.com/xonixx/fhtagn/actions/workflows/run-tests.yml/badge.svg)](https://github.com/xonixx/fhtagn/actions/workflows/run-tests.yml)
                    
`fhtagn.awk` is a tiny CLI tool for literate testing for command-line programs.  
                   
File `tests.tush`:
```
$ command --that --should --execute correctly
| expected stdout output

$ command --that --will --cause error
@ expected stderr output
? expected-exit-code
```

Run the tests:
```shell
./fhtagn.awk tests.tush
```

In fact this is a re-implementation of [darius/tush](https://github.com/darius/tush), [adolfopa/tush](https://github.com/adolfopa/tush).
But simpler (single tiny AWK script) and faster, because:
                      
- it uses `/dev/shm` where available instead of `/tmp`
- it compares the expected result with the actual in the code and only calls `diff` to show the difference if they don't match
- it doesn't create a sandbox folder for each test
- it doesn't use `mktemp` but rather generates random name in the code

## Usage

```
./fhtagn.awk f1.tush [ f2.tush [ f3.tush [...] ] ]
```
This will stop on the first error found.

Example:
```
$ ./fhtagn.awk tests/1.tush tests/2.tush tests/3.tush 
tests/2.tush:10: $ echo "hello world"; echo "error msg" >&2; exit 7
--- expected
+++ actual
@@ -1,4 +1,4 @@
 | hello world
-@ error msg 444
-? 8
+@ error msg
+? 7
 
```

### Fail at the end
      
Set `ALL=1` environment variable.

This runs all tests, collects all errors, and shows the stats at the end.
```
ALL=1 ./fhtagn.awk f1.tush [ f2.tush [ f3.tush [...] ] ]
```

Useful for running in CI.

Example:
```
$ ALL=1 ./fhtagn.awk tests/1.tush tests/2.tush tests/3.tush 
tests/2.tush:10: $ echo "hello world"; echo "error msg" >&2; exit 7
--- expected
+++ actual
@@ -1,4 +1,4 @@
 | hello world
-@ error msg 444
-? 8
+@ error msg
+? 7
 
tests/3.tush:4: $ echo bbb
--- expected
+++ actual
@@ -1,2 +1,2 @@
-| BBB
+| bbb
 
result=FAIL, failure=2, success=4, total=6, files=3
```


