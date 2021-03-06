*! utils: rewrites of built-in Stata commands, for speed and profit
*! type -which utils- for a list of commands and options
*! version 1.4 F. Briatte 2jun2013

*! find: a more useful -lookfor- command
cap pr drop find
program find, rclass
	qui lookfor `*'
	loc q `r(varlist)'
	if "`q'" != "" codebook `q', c
	return local varlist = "`q'"
end

*! load: a more useful -use- command
cap pr drop load
program load
	syntax anything(everything) [if] [in]
	loc p data/
	// open from working directory
	cap use `*', clear
	// if fails, open from data/ folder
	if _rc cap use `p'`*', clear
	if _rc exit _rc
	// show info (obs. and notes)
	loc d : data l
	if "`d'" == "" loc d "`c(filename)'"
	loc n = _N
	di as txt "`d'", "(N = `n')"
	notes _dta
end

*! wipe: remove log files in working folders (requires X Window System)
*! use option 'pwd' to include the working directory
*! use option 'pre' to select a log file prefix
*! use option 'ext' to select a log file extension
cap pr drop wipe
program wipe
  syntax [anything] [, pwd pre(string) ext(string)]
  tokenize `anything'
  if "`ext'" == "" loc ext = "log"
  if "`pwd'" != "" {
    loc expr = "`pre'*.`ext'"
    cap !rm `expr'
  }
  while "`*'" != "" {
    loc dir = "`1'"
    loc expr = "`dir'/`pre'*.`ext'"
    cap !rm `expr'
    macro shift
  }
end

*! updates: package update checker
cap pr drop updates
program updates
  cap qui ssc hot
  if !_rc cap noi adoupdate, update all
  if _rc di as err "ERROR: could not go online to check for updates."
end

*! science: a program by Rudolf Carnap, with assistance from the Vienna Circle
*! this program has been abandoned
cap pr drop science
program science
	di as txt _n "  Science is a system of statements"
	di as txt "  based on direct experience"
	di as txt "  and controlled by experimental verification."
	di as txt _n "  -- Rudolf Carnap" _n
end

*! pkgs: determine if a folder can be used to install Stata packages
*! version 0.1 F. Briatte 18aug2013
cap pr drop pkgs
program pkgs
  syntax [using/] [, quiet]
  
  * test PLUS directory codename by default
  if "`using'" == "" loc using = c(sysdir_plus)
  loc pwd = c(pwd)
  loc trk = "stata.trk"

  * set working directory to install path, or...
  cap cd "`using'"
	* ... create directory if missing (_rc == 601)
  if _rc cap mkdir "`using'", public

  * determine whether stata.trk exists
  loc erase = 0
  cap confirm new file `trk'
  if _rc == 0 loc erase = 1

  * determine whether the user has admin privileges
  tempname foo
  cap file open `foo' using `trk', write append
  cap file close `foo'

  * declare paths that can write to stata.trk valid
  if _rc == 0 {
    sysdir set PLUS "`using'"
    if "`quiet'" == "" di as txt "Package install path set to:" _n "`using'"
  }
  else {
    di as err _n "WARNING: invalid package install path" _n "`using'"
  }

  * erase empty stata.trk created on permissions test
  if `erase' == 1 {
  	cap erase `trk'
  	if _rc di as err "WARNING: permissions test failed with code", _rc
  }

  * return
  qui cd "`pwd'"
  exit _rc
end

// enjoy
