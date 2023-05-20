#!/usr/bin/awk -f
BEGIN {
  Prog = "fhtagn"
  Tmp = ok("[ -d /dev/shm ]") ? "/dev/shm" : "/tmp"
  fhtagn()
  srand()
}
function fhtagn(   file,l,code,random,exitCode,stdOutF,stdErrF,testStarted,expected) {
  for (i = 1; i < ARGC; i++) {
    file = ARGV[i]
  }

  while ((getline l < file) > 0) {
    if (l ~ /^\$/) {
      if (testStarted) {
        testStarted = 0
        checkTestResult(expected,stdOutF,stdErrF,exitCode,random)
      } else {
        testStarted = 1
        expected = ""
      }
      # execute line starting '$', producing out & err & exit_code
      code = substr(l,2)
      random = rnd()
      stdOutF = Tmp "/" Prog "." random ".out"
      stdErrF = Tmp "/" Prog "." random ".err"
      code = "(" code ") 1>" stdOutF " 2>" stdErrF
      exitCode = system(code)
    } else if (l ~ /^[|@?]/) {
      # parse result block (|@?)
      expected = expected l "\n"
    } else {
      if (testStarted) {
        testStarted = 0
        checkTestResult(expected,stdOutF,stdErrF,exitCode,random)
      }
    }
  }
  close(file)
  if (testStarted) {
    checkTestResult(expected,stdOutF,stdErrF,exitCode,random)
  }
}
function checkTestResult(expected, stdOutF, stdErrF, exitCode, random,   actual,expectF,actualF) {
  actual = prefixFile("|",stdOutF) prefixFile("@",stdErrF)
  system("rm -f " stdOutF " " stdErrF)
  if (exitCode != 0) actual = actual "? " exitCode "\n"
  if (expected != actual) {
    # printf "FAIL:\nexpected:\n#%s#\nactual:\n#%s#\n", expected, actual
    # use diff to show the difference
    expectF = Tmp "/" Prog "." random ".exp"
    actualF = Tmp "/" Prog "." random ".act"
    print expected > expectF
    print actual > actualF
    system("diff " expectF " " actualF "; rm " expectF " " actualF)
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
function ok(cmd) { return system(cmd) == 0 }
