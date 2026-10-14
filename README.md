[![Stand With Ukraine](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/banner-direct-single.svg)](https://stand-with-ukraine.pp.ua)

# fhtagn

[![Run tests](https://github.com/xonixx/fhtagn/actions/workflows/run-tests.yml/badge.svg)](https://github.com/xonixx/fhtagn/actions/workflows/run-tests.yml)
![coverage](coverage.svg)
                    
`fhtagn.awk` is a tiny CLI tool for literate testing for command-line programs.  
                   
File `tests.fhtagn`:
```
$ command --that --should --execute correctly
| expected stdout output

$ command --that --will --cause error
@ expected stderr output
? expected-exit-code
```

Run the tests:
```sh
./fhtagn.awk tests.fhtagn
```

In fact, this is a re-implementation of [darius/tush](https://github.com/darius/tush), [adolfopa/tush](https://github.com/adolfopa/tush).
But simpler (single tiny AWK script) and faster, because:
                      
- it uses `/dev/shm` where available instead of `/tmp`
- it compares the expected result with the actual in the code and only calls `diff` to show the difference if they don't match
- it doesn't create a sandbox folder for each test
- it doesn't use `mktemp` but rather generates random name in the code

## Usage

```sh
./fhtagn.awk f1.fhtagn [ f2.fhtagn [ f3.fhtagn [...] ] ]
```
This will stop on the first error found.

Example:
```
$ ./fhtagn.awk tests/1.fhtagn tests/2.fhtagn tests/3.fhtagn 
tests/2.fhtagn:12: $ echo "hello world"; echo "error msg" >&2; exit 7
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
```sh
ALL=1 ./fhtagn.awk f1.fhtagn [ f2.fhtagn [ f3.fhtagn [...] ] ]
```

Useful for running in CI.

Example:
```
$ ALL=1 ./fhtagn.awk tests/1.fhtagn tests/2.fhtagn tests/3.fhtagn 
tests/2.fhtagn:12: $ echo "hello world"; echo "error msg" >&2; exit 7
--- expected
+++ actual
@@ -1,4 +1,4 @@
 | hello world
-@ error msg 444
-? 8
+@ error msg
+? 7
 
tests/3.fhtagn:7: $ echo bbb
--- expected
+++ actual
@@ -1,2 +1,2 @@
-| BBB
+| bbb
 
result=FAIL, failure=2, success=4, total=6, files=3
```

### Regex matching

Use `|~pattern` to match a stdout line or `@~pattern` to match a stderr line:

```text
$ echo 'version: 1.2.3'; echo 'warning: 42' >&2
|~version: [0-9]+\.[0-9]+\.[0-9]+
@~warning: [0-9]+
```

Patterns use AWK extended regular expressions and must match the whole line.
For a substring match, surround the pattern with `.*`, for example
`|~.*connection refused.*`. Each assertion matches exactly one line; extra or
missing output lines still fail, and output order and stream must match.
Literal and regex assertions can be mixed. Exit-code assertions remain literal.

Everything after `~` is the pattern, including whitespace and backslashes.
There are no `/…/` delimiters or additional escaping: use `\.` for a literal dot.
`|~ abc` requires a leading space, `|~` matches only an empty line, and `|~.*`
matches any single line, including an empty one. To expect literal output starting
with `~`, use the usual space: `| ~text`.

On failure, the diff shows unmatched patterns against actual output. Successful
regex assertions appear unchanged in the diff, even when another assertion fails.

Patterns must be valid for your AWK implementation. An invalid regex causes a
native AWK error and aborts the run, even with `ALL=1`. It may leave temporary
files because AWK can skip the cleanup in `END` on such errors.

### Parameterized tests

You can use variable substitution to parametrize tests. This works like so:

```
# in your .fhtagn file you have

$ command {{VAR1}} '{{VAR2}}'
| expected output
```

And you run it like so:

```sh
./fhtagn.awk tests.fhtagn VAR1=value VAR2='other value'
```

The example use case here is to check the correctness of the same command when ran by different versions of a programming language. This is what we do to test fhtagn itself with different AWKs: [link1](https://github.com/xonixx/fhtagn/blob/c3986e11757a05b8b3932b4eec204cbfdb31874b/tests/fhtagn.tush#L2), [link2](https://github.com/xonixx/fhtagn/blob/c3986e11757a05b8b3932b4eec204cbfdb31874b/Makesurefile#L74), [link3](https://github.com/xonixx/fhtagn/blob/c3986e11757a05b8b3932b4eec204cbfdb31874b/Makesurefile#L53).

Note that in case of test failure, you will see an expanded command line, which is helpful for debugging.
