# EC Standard Login Environment -*- sh -*-
# user .cshrc file
# $Source: /tmp/repos/cvs/ec_environ-1.0/release/user/cshrc,v $
# $Revision: 1432 $

# !!!!           !!!!  USER MUST NEVER EDIT THIS FILE.
# !!!!           !!!!  Customizations to this file, will
# !!!! IMPORTANT !!!!  most likely cause you login sequence to fail,
# !!!! NOTE FOR  !!!!  which will be fixed by restoring the original copy.
# !!!! ALL USERS !!!!  Place all user customization in:
# !!!!           !!!!  $HOME/.cshrc.<username>
# !!!!           !!!!  Name of your default project in:
# !!!!           !!!!  $HOME/.project.<username>

# EC may release updates to this file which will be
# automatically installed.  If for some special reason
# you need to make local changes or want to suppress
# autofix, change 0 to 1 here: ECLOGIN_NO_AUTOFIX=0

# See full documentation at /usr/intel/common/pkgs/eclogin/<version>/docs
# or http://goto.intel.com/eclogin

# unfortunately xdm sets USER but not LOGNAME
if (! $?LOGNAME) then
  if ($?USER) then
    setenv LOGNAME $USER
  else
    # have to get creative now...
    if ( -e /usr/intel/bin/gid ) then
      setenv LOGNAME `/usr/intel/bin/gid -un`
    else
      # Q: safe to assume whoami is in $PATH ?
      setenv LOGNAME `whoami`
    endif
  endif
endif

if (! $?USER) setenv USER $LOGNAME
set ec_env_error_log = /tmp/eclogin-errors.$USER

# legacy and unconfigured clients may need to truncate here
if (-w $ec_env_error_log) then
  grep "^I:...cshrc...leaving" $ec_env_error_log >&/dev/null && /bin/cp /dev/null $ec_env_error_log >& /dev/null
endif

echo "I: (.cshrc) [entering] `/bin/date`" >>! $ec_env_error_log

# this will happen with csh on SunOS4, try to recover
if (! $?tcsh) then
  if (! $?EC_ENV_ROOT) then
    if (-r /etc/.cshrc) then
      source /etc/.cshrc
    else
      if (-r /etc/csh.cshrc) then
        source /etc/csh.cshrc
      endif
    endif
  endif
endif

# it is not obvious why this should go in .cshrc, but
# the flow should be:
#
# /etc/[csh].cshrc
# /etc/[csh].login
# $HOME/.cshrc
# $HOME/.login
#
# We try to catch both the missed etc files at the start
# of $HOME/.cshrc, using $?prompt to detect login shells.
#
if ($?prompt) then
  if (! $?tcsh) then
    if ($?EC_ENV_ROOT && ! $?EC_ENV_LOGIN) then
      if (-r /etc/.login) then
        source /etc/.login
      else
        if (-r /etc/csh.login) then
          source /etc/csh.login
        endif
      endif
    endif
  endif
endif

# TEMPORARY DEVELOPMENT hook for unconfigured clients, reach the client bits directly
if (! $?EC_ENV_ROOT) then
  if ( -f /usr/intel/common/pkgs/eclogin/1.0/etc/csh.cshrc ) then
    source /usr/intel/common/pkgs/eclogin/1.0/etc/csh.cshrc
  endif
endif

# TEMPORARY DEVELOPMENT hook for unconfigured clients, reach the client bits directly
if ($?prompt) then
  if ($?EC_ENV_ROOT && ! $?EC_ENV_LOGIN) then
    if ( -f /usr/intel/common/pkgs/eclogin/1.0/etc/csh.login ) then
      setenv EC_ENV_LOGIN 1
      source /usr/intel/common/pkgs/eclogin/1.0/etc/csh.login
    endif
  endif
endif

# discard, or will break xterm -ls run from this shell or its children
unsetenv EC_ENV_LOGIN

# this is very bad
if (! $?EC_ENV_ROOT) then
  echo "E: (cshrc) EC_ENV_ROOT was missing, check client setup" >>! $ec_env_error_log
  echo "E: (cshrc)   or /usr/intel contents" >> $ec_env_error_log

  # try fallback option if file exists
  if ( -f $HOME/.cshrc.legacy ) then
    echo "I: (cshrc) switching to $HOME/.cshrc.legacy" >> $ec_env_error_log
    source $HOME/.cshrc.legacy
    exit
  endif

  setenv EC_ENV_ROOT /ec_env_root-system-error
endif

# start with global content
if (-r $EC_ENV_ROOT/ec/cshrc) then
  source $EC_ENV_ROOT/ec/cshrc
else
  echo "E: (.cshrc) Global components missing, check" >> $ec_env_error_log
  echo "E: (.cshrc)     EC_ENV_ROOT=$EC_ENV_ROOT" >> $ec_env_error_log
  echo "E: (.cshrc) trying to continue with system defaults." >> $ec_env_error_log

  if ($?prompt) then
    echo "E: (cshrc) Global eclogin components missing, check client setup"
    echo "E: (cshrc)   or /usr/intel contents.  This is a fatal error."
    echo "E: (cshrc)   EC_ENV_ROOT was set to $EC_ENV_ROOT"
    echo "E: (cshrc)   Please report it to Engineering Computing."
  endif

  # fake some core parts to avoid fatal errors while
  # trying to execute the rest of user's dot files
  alias modpath /bin/true
  setenv EC_UNAME "`/bin/uname -srm | /bin/sed 's/ /_/g'`"
endif

# extract project from user's setup
if (! $?EC_ENV_PROJ && -r $HOME/.project.$USER) then
  set ec_user_proj = `tail -1 $HOME/.project.$USER`
  if (-d "$EC_ENV_ROOT/projects/$ec_user_proj") then
    setenv EC_ENV_PROJ $ec_user_proj
  endif
  unset ec_user_proj
endif

# if user did not set, use default
if (! $?EC_ENV_PROJ) then
  setenv EC_ENV_PROJ default
endif

# extra diag for project config area
if (! -d $EC_ENV_ROOT/projects/$EC_ENV_PROJ/.) then
  echo "I: (.cshrc) project config area does not exist $EC_ENV_ROOT/projects/$EC_ENV_PROJ" >> $ec_env_error_log
endif

# run project setup first
if ($?EC_ENV_PROJ) then
  if (-r $EC_ENV_ROOT/projects/$EC_ENV_PROJ/cshrc) then
    source $EC_ENV_ROOT/projects/$EC_ENV_PROJ/cshrc
  else
    echo "I: (.cshrc) project cshrc missing: $EC_ENV_ROOT/projects/$EC_ENV_PROJ/cshrc" >> $ec_env_error_log
  endif
endif

# run user's setup next (if any)
if (-r $HOME/.cshrc.$USER) then
  source $HOME/.cshrc.$USER
else
    echo "I: (.cshrc) user cshrc missing: $HOME/.cshrc.$USER" >> $ec_env_error_log
endif

# this is the safest place to add cwd in $path
# if site/project/user did not already insert
# may be suppressed by setting in .cshrc.$USER
if (! $?EC_NO_ADD_DOTPATH) then
  modpath -q -f .
else
  unset EC_NO_ADD_DOTPATH
endif

###
### VALIDATION
### 
# User may choose to disable noisy validation messages,
# using $EC_DISABLE_VAL, choices are:
#
# <empty>
# project
# system
#

set ec_runprojval=1
set ec_runsysval=1

if ($?EC_DISABLE_VAL) then
  if ("$EC_DISABLE_VAL" =~ *project* ) set ec_runprojval=0
  if ("$EC_DISABLE_VAL" =~ *system* ) set ec_runsysval=0
endif

# no validation when NEUTER active
if ($?EC_ENV_NEUTER) then
  set ec_runprojval=0
  set ec_runsysval=0
endif

if ( $ec_runprojval ) then
  # project validation - passive, not sourced
  if ($?EC_ENV_PROJ) then
    if (-r $EC_ENV_ROOT/projects/$EC_ENV_PROJ/cshrc-val) then
      /bin/csh -f $EC_ENV_ROOT/projects/$EC_ENV_PROJ/cshrc-val
    else
      echo "I: (.cshrc) failed to find $EC_ENV_ROOT/projects/$EC_ENV_PROJ/cshrc-val" >> $ec_env_error_log
    endif
  endif
else
  echo "I: (.cshrc) user disabled $EC_ENV_ROOT/projects/$EC_ENV_PROJ/cshrc-val" >> $ec_env_error_log
endif

set printdiag=1
if ( $ec_runsysval ) then
# system validation - passive
if (-r $EC_ENV_ROOT/ec/cshrc-val) then
  if ($?prompt && $?EC_LOGINSH) then
    /bin/csh -f $EC_ENV_ROOT/ec/cshrc-val login

    # cshrc-val prints some diags, should not be duplicated below
    if ($status == 1) then
      set printdiag=0
    endif

  else
    /bin/csh -f $EC_ENV_ROOT/ec/cshrc-val
  endif
else
  #error - filesystem went away or master env corrupt?
  echo "E: (.cshrc) failed to find $EC_ENV_ROOT/ec/cshrc-val" >> $ec_env_error_log
endif
else
  echo "I: (.cshrc) user disabled $EC_ENV_ROOT/ec/cshrc-val" >> $ec_env_error_log
endif

unset ec_runprojval
unset ec_runsysval

###
### if log contains anything but info (I:) msgs and
### this is a login shell, print the results so far.
###
### do not wait for login flow because many users
### start a new session using xterm without -ls option
###
if ($?prompt && $?EC_LOGINSH ) then

  # NB: the log may disappear when other processes rewrite

  # TEMPORARY WORK AROUND FOR LACK OF SEMAPHORE ON THE LOG FILE
  #
  # side effects - errors captured into separate file that
  # should not be clobbered by anything else, can be left
  # for examination - and must be cleaned up manually.
  #
  /bin/rm -f /tmp/eclogin-errors-copy.$USER.$$
  test -r $ec_env_error_log && /bin/cp $ec_env_error_log /tmp/eclogin-errors-copy.$USER.$$ >& /dev/null

  #proceed if backup succeeded...
  if ($status == 0) then
    grep -v "^I:" /tmp/eclogin-errors-copy.$USER.$$ | grep "^.: " >& /dev/null

    #proceed if usable error strings found
    if ($status == 0) then
      echo "*********************************************************"
      echo "The following errors were logged during shell startup:"
      echo " "
      grep -v "^I:" /tmp/eclogin-errors-copy.$USER.$$
      echo " "
      echo "For reference a copy of the log containing these messages"
      echo "may be found in:"
      echo " /tmp/eclogin-errors-copy.$USER.$$"
      if ($printdiag == 1) then
        echo " "
        echo "For an explanation of these warnings/errors please see"
        echo "http://goto.intel.com/eclogin#diag-msgs "
      endif
      echo "*********************************************************"
      echo " "
    else
      #silent cleanup
      /bin/rm -f /tmp/eclogin-errors-copy.$USER.$$ >& /dev/null
    endif
  else
    #silent cleanup
    /bin/rm -f /tmp/eclogin-errors-copy.$USER.$$ >& /dev/null
  endif
endif
unset printdiag

# no further need for this env
unsetenv EC_LOGINSH

echo "I: (.cshrc) [leaving] `/bin/date`" >> $ec_env_error_log
#unset ec_env_error_log
#
#reset this so subsequent execution of any files will not
#fail due to missing variable, but not generate confusing
#log from unrelated shells.
set ec_env_error_log = /dev/null
