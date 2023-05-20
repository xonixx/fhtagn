#!/usr/bin/awk -f
BEGIN {
  Prog = "fhtagn"
  Tmp = ok("[ -d /dev/shm ]") ? "/dev/shm" : "/tmp"
  srand()
  fhtagn()
}
function fhtagn(   i,file,err,l,code,random,exitCode,stdOutF,stdErrF,testStarted,expected) {
  for (i = 1; i < ARGC; i++) {
    file = ARGV[i]
  }

  while ((err = (getline l < file)) > 0) {
    if (l ~ /^\$/) {
      if (testStarted) {
        testStarted = 0 # TODO is this correct?
        checkTestResult(expected,stdOutF,stdErrF,exitCode,random)
      } else {
        testStarted = 1
        expected = ""
      }
      # execute line starting '$', producing out & err & exit_code
      stdOutF = tmpFile(random = rnd(), "out")
      stdErrF = tmpFile(random, "err")
      code = substr(l,2)
      exitCode = system("(" code ") 1>" stdOutF " 2>" stdErrF)
    } else if (l ~ /^[|@?]/) {
      # parse result block (|@?)
      expected = expected l "\n"
    } else if (testStarted) {
      testStarted = 0
      checkTestResult(expected,stdOutF,stdErrF,exitCode,random)
    }
  }
  if (err < 0) die("error reading file: " file)
  close(file)
  if (testStarted) {
    checkTestResult(expected,stdOutF,stdErrF,exitCode,random)
  }
}
function die(err) { print err > "/dev/stderr"; exit 2 }
function checkTestResult(expected, stdOutF, stdErrF, exitCode, random,   actual,expectF) {
  actual = prefixFile("|",stdOutF) prefixFile("@",stdErrF)
  system("rm -f " stdOutF " " stdErrF)
  if (exitCode != 0) actual = actual "? " exitCode "\n"
  if (expected != actual) {
    # printf "FAIL:\nexpected:\n#%s#\nactual:\n#%s#\n", expected, actual
    # use diff to show the difference
    print expected > (expectF = tmpFile(random, "exp"))
    print actual | "diff " expectF " -; rm " expectF
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
