#!/usr/bin/awk -f
BEGIN {
  Prog = "fhtagn"
  Tmp = ok("[ -d /dev/shm ]") ? "/dev/shm" : "/tmp"
  if (!(Diff = ENVIRON["DIFF"])) Diff = "diff"
  srand()
  fhtagn()
}
function fhtagn(   i,file,err,l,code,random,exitCode,stdOutF,stdErrF,testStarted,expected) {
  for (i = 1; i < ARGC; i++) {
    file = ARGV[i]
#    print "processing: " i, file
    while ((err = (getline l < file)) > 0) {
      if (l ~ /^\$/) {
        if (testStarted) # finish previous
          checkTestResult(file,code,expected,stdOutF,stdErrF,exitCode,random)
        testStarted = 1
        expected = ""
        # execute line starting '$', producing out & err & exit_code
        stdOutF = tmpFile(random = rnd(), "out")
        stdErrF = tmpFile(random, "err")
        code = substr(l,2)
        exitCode = system("(" code ") 1>" stdOutF " 2>" stdErrF) # can it be that {} are better than ()?
      } else if (l ~ /^[|@?]/) {
        # parse result block (|@?)
        expected = expected l "\n"
      } else if (testStarted) {
        testStarted = 0
        checkTestResult(file,code,expected,stdOutF,stdErrF,exitCode,random)
      }
    }
    if (err < 0) die("error reading file: " file)
    close(file)
    if (testStarted) {
      testStarted = 0
      checkTestResult(file,code,expected,stdOutF,stdErrF,exitCode,random)
    }
  }
}
function die(err) { print err > "/dev/stderr"; exit 2 }
function checkTestResult(file, code, expected, stdOutF, stdErrF, exitCode, random,   actual,expectF) {
  actual = prefixFile("|",stdOutF) prefixFile("@",stdErrF)
  system("rm -f " stdOutF " " stdErrF)
  if (exitCode != 0) actual = actual "? " exitCode "\n"
  if (expected != actual) {
    #     printf "FAIL:\nexpected:\n#%s#\nactual:\n#%s#\n", expected, actual
    # use diff to show the difference
    print expected > (expectF = tmpFile(random, "exp"))
    print "[" file "] $" code
    print actual | Diff " -u --label expected --label actual " expectF " -; rm " expectF
    exit 1
  }
}
function prefixFile(prefix, fname,   l,res) {
  while ((getline l < fname) > 0) {
    res = res prefix " " l "\n"
  }
  close(fname)
  return res
}
function rnd() { return int(2000000000 * rand()) }
function tmpFile(random, ext) { return sprintf("%s/%s.%d.%s", Tmp, Prog, random, ext) }
function ok(cmd) { return system(cmd) == 0 }
