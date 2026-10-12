#!/usr/bin/awk -f
BEGIN {
  Prog = "fhtagn"
  if (!(Diff = ENVIRON["DIFF"])) Diff = "diff"
  if (!(Tmp = ENVIRON["TMPDIR"])) Tmp = "/tmp"
  initRnd() # additional source of "random"
  delete Vars # name->value
  All = ENVIRON["ALL"]
  srand()
  Success = Failed = 0
  fhtagn()
}
END { if (ToDel) system("rm -f" ToDel) }
function initRnd(   c) {
  (c = "echo $$") | getline Rnd # using PID serves a good approximation to random
  close(c)
}
function fhtagn(   i,file,err,l,code,nr,line,random,exitCode,stdOutF,stdErrF,testStarted,expected,hasMoreCode,k) {
  for (i = 1; i < ARGC; i++)
    if (k = index(l = ARGV[i], "="))
      Vars[substr(l, 1, k - 1)] = substr(l, k + 1)

  for (i = 1; i < ARGC; i++) {
    if ((file = ARGV[i]) ~ /=/) continue
    for (nr = 1; (err = getline l < file) > 0; nr++) {
      if (l ~ /^\$/) {
        if (testStarted) # finish previous
          checkTestResult(file, code, line, expected, stdOutF, stdErrF, exitCode, random)
        testStarted = 1
        expected = ""
        # execute line starting '$', producing out & err & exit_code
        ToDel = ToDel " " (stdOutF = tmpFile(random = rndS(), "out")) " " (stdErrF = tmpFile(random, "err"))
        if (index(code = substr(l, 2),"{{"))
          for (k in Vars)
            gsub("{{"k"}}", Vars[k], code)
        line = nr
        if (!(hasMoreCode = l ~ /\\$/))
          exitCode = run(code, stdOutF, stdErrF)
      } else if (hasMoreCode) {
        code = code "\n" l
        if (!(hasMoreCode = l ~ /\\$/))
          exitCode = run(code, stdOutF, stdErrF)
      } else if (l ~ /^[|@?]/) {
        # parse result block (|@?)
        expected = expected l "\n"
      } else if (testStarted) {
        testStarted = 0
        checkTestResult(file, code, line, expected, stdOutF, stdErrF, exitCode, random)
      }
    }
    if (err) die("error reading file: " file)
    close(file)
    if (testStarted) {
      testStarted = 0
      checkTestResult(file, code, line, expected, stdOutF, stdErrF, exitCode, random)
    }
  }
  if (All) {
    printf "result=%s, failure=%d, success=%d, total=%d, files=%d\n", Failed ? "FAIL" : "SUCCESS", Failed, Success, Failed + Success, i - 1
    exit !!Failed
  }
}
function die(err) { print err > "/dev/stderr"; exit 2 }
function checkTestResult(file, code, line, expected, stdOutF, stdErrF, exitCode, random,   actual,expectF,d) {
  actual = prefixFile("|", stdOutF) prefixFile("@", stdErrF)
  if (exitCode != 0) actual = actual "? " exitCode "\n"
  if (expected != actual) actual = normalizeActual(expected, actual)
  if (expected != actual) {
    Failed++
    #     printf "FAIL:\nexpected:\n#%s#\nactual:\n#%s#\n", expected, actual
    # use diff to show the difference
    print expected > (expectF = tmpFile(random, "exp"))
    close(expectF)
    print file ":" line ": $" code
    print actual | (d = Diff " -u --label expected --label actual " expectF " -; rm " expectF)
    close(d)
    if (!All) exit 1
  } else Success++
}
function normalizeActual(expected, actual,   e,a,n,i,res) {
  split(expected, e, "\n")
  n = split(actual, a, "\n")
  for (i = 1; i < n; i++) {
    # Replace successful regex assertions so comparison and diff stay literal.
    if (e[i] ~ /^[|@]~/ && substr(e[i], 1, 1) == substr(a[i], 1, 1) &&
        match(substr(a[i], 3), substr(e[i], 3)) == 1 && RLENGTH == length(a[i]) - 2)
      a[i] = e[i]
    res = res a[i] "\n"
  }
  return res
}
function prefixFile(prefix, fname,   l,res,err) {
  while ((err = getline l < fname) > 0)
    res = res prefix " " l "\n"
  if (err) die("error reading file: " fname)
  close(fname)
  return res
}
function run(code,stdOutF,stdErrF) {
  return system("{" code "\n} 1>" stdOutF " 2>" stdErrF)
}
function rndS() { return int(2147483647 * rand()) "." Rnd }
function tmpFile(random, ext) { return sprintf("%s/%s.%s.%s", Tmp, Prog, random, ext) }
