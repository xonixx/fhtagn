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

In fact this tool is a re-implementation of [darius/tush](https://github.com/darius/tush), [adolfopa/tush](https://github.com/adolfopa/tush).
But simpler (single tiny AWK script) and faster, because:
                      
- it uses `/dev/shm` where available instead of `/tmp`
- it compares the expected result with the actual in the code and only calls `diff` to show the difference if they don't match
- it doesn't create a sandbox folder for each test
- it doesn't use `mktemp` but rather generates random name in the code
