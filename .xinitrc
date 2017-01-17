# @(#) $Revision: 1.8 $ -*- sh -*-
# $Source: /usr/cvs/cvsrep/ec_environ-1.0/release/user/xinitrc,v $
#
# EC Standard Login Environment
# .xinitrc file
# $Source: /usr/cvs/cvsrep/ec_environ-1.0/release/user/xinitrc,v $
# $Revision: 1.8 $

###
###---------->DISCLAIMER<----------
###

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

#
# this is really a csh script but may be invoked
# by sh on some systems; force into csh
#
test X != "X$path" && goto cshish
exec /bin/csh $0 ${@+"$@"}
cshish:

###
###---------->DEBUG/TRACE LOG<----------
###

# log startup activity in the usual place...
set ec_env_error_log = /tmp/eclogin-errors.$USER
echo "I: (.xinitrc) [entering] `/bin/date`" >> $ec_env_error_log

# this is very bad
if (! $?EC_ENV_ROOT) then
  echo "E: (.xinitrc) EC_ENV_ROOT was missing, check user setup" >>$ec_env_error_log
endif

###
###---------->PREREQUISITES<----------
###

# ssh-agent startup has moved, uncomment this line
# to suppress agent management in the global file
# set EC_X_NO_SSHAGENT

###
###---------->GLOBAL COMPONENTS<----------
###
if (-r $EC_ENV_ROOT/ec/xinitrc) then
  source $EC_ENV_ROOT/ec/xinitrc
else
  echo "E: (.xinitrc) failed to find $EC_ENV_ROOT/ec/xinitrc" >>$ec_env_error_log
endif

###
###---------->SITE COMPONENTS<----------
###
if (-r $EC_ENV_ROOT/site/xinitrc) then
  source $EC_ENV_ROOT/site/xinitrc
else
  echo "E: (.xinitrc) failed to find $EC_ENV_ROOT/site/xinitrc" >>$ec_env_error_log
endif

###
###---------->USER COMPONENTS<----------
###
if (-r $HOME/.xinitrc.$USER) then
  source $HOME/.xinitrc.$USER
else
  echo "E: (.xinitrc) failed to find $HOME/.xinitrc.$USER" >>$ec_env_error_log
  exec xterm -n "failsafe session - xterm only"
endif

###
###---------->CLEANUP<----------
###

echo "I: (.xinitrc) [leaving] `/bin/date`" >> $ec_env_error_log
# THE END
