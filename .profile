# EC Standard Login Environment -*- sh -*-
# user profile
# $Source: /usr/cvs/cvsrep/ec_environ-1.0/release/user/profile,v $
# $Revision: 1.15 $

# !!!!           !!!!  USER MUST NEVER EDIT THIS FILE.
# !!!! IMPORTANT !!!!  Place all user customization in:
# !!!! NOTE FOR  !!!!  $HOME/.profile.<username>
# !!!! ALL USERS !!!!  Name of your default project in:
# !!!!           !!!!  $HOME/.project.<username>

# EC may release updates to this file which will be
# automatically installed.  If for some special reason
# you need to make local changes or want to suppress
# autofix, change 0 to 1 here: ECLOGIN_NO_AUTOFIX=0

# See full documentation at /usr/intel/common/pkgs/eclogin/<version>/docs
# or http://<url-tbd>
# TODO: detailed docs.

# unfortunately xdm sets USER but not LOGNAME
if [ "1$LOGNAME" = "1" ]; then
  if [ "1$USER" != "1" ]; then
    LOGNAME=$USER export LOGNAME
  else
    # have to get creative now...
    if [ -x /usr/intel/bin/gid ]; then
      LOGNAME=`/usr/intel/bin/gid -un` export LOGNAME
    else
      # Q: safe to assume whoami is in $PATH ?
      LOGNAME=`whoami` export LOGNAME
    fi
  fi
fi

if [ "1$USER" = "1" ]; then
  USER=$LOGNAME export LOGNAME
fi
ec_env_error_log=/tmp/eclogin-errors.$USER

# legacy and unconfigured clients may need to truncate here
if [ -w $ec_env_error_log ]; then
  grep "^I:...profile...leaving" $ec_env_error_log >/dev/null && /bin/cp /dev/null $ec_env_error_log
fi

echo "I: (.profile) [entering] `/bin/date`" >> $ec_env_error_log

# TEMPORARY DEVELOPMENT hook for unconfigured clients, reach the client bits directly
if [ "1$EC_ENV_ROOT" = "1" ]; then
  if [ -f /usr/intel/common/pkgs/eclogin/1.0/etc/profile ]; then
    . /usr/intel/common/pkgs/eclogin/1.0/etc/profile
  fi
fi

# this is very bad
havelegacy=0
if [ "1$EC_ENV_ROOT" = "1" ]; then
  echo "E: (.profile) EC_ENV_ROOT was missing, check client setup" >> $ec_env_error_log
  echo "E: (.profile)   or /usr/intel contents" >> $ec_env_error_log

  # try fallback option if file exists
  if [ -f $HOME/.profile.legacy ]; then
    echo "I: (profile) switching to $HOME/.profile.legacy" >> $ec_env_error_log
    . $HOME/.profile.legacy
    havelegacy=1
  else
    echo "W: (.profile) no .profile.legacy found; the rest of this environment"
    echo "W: (.profile) is likely to fail due to missing system files or"
    echo "W: (.profile) unsupported platform."
  fi

  EC_ENV_ROOT=/ec_env_root-system-error export EC_ENV_ROOT
fi

# bypass the rest if .profile.legacy was invoked
if [ "0$havelegacy" = "00" ]; then

  # start with global content
  if [ -r $EC_ENV_ROOT/ec/profile ]; then
    . $EC_ENV_ROOT/ec/profile
  else
    echo "E: (.profile) global components missing, check" >> $ec_env_error_log
    echo "E: (.profile)     EC_ENV_ROOT=$EC_ENV_ROOT" >> $ec_env_error_log
    echo "E: (.profile) trying to continue with system defaults." >> $ec_env_error_log
  fi

  # extract project from user's setup
  if [ "1$EC_ENV_PROJ" = "1" -a -r $HOME/.project.$USER ]; then
    ec_user_proj=`tail -1 $HOME/.project.$USER`
    if  [ -d "$EC_ENV_ROOT/projects/$ec_user_proj" ]; then
      EC_ENV_PROJ=$ec_user_proj export EC_ENV_PROJ
    fi
    unset ec_user_proj
  fi

  # if user did not set, use default
  if  [ "1$EC_ENV_PROJ" = "1" ]; then
    EC_ENV_PROJ=default export EC_ENV_PROJ
  fi

  # extra diag for project config area
  if [ ! -d $EC_ENV_ROOT/projects/$EC_ENV_PROJ/. ]; then
    echo "I: (.profile) project config area does not exist $EC_ENV_ROOT/projects/$EC_ENV_PROJ" >> $ec_env_error_log
  fi

  # run project setup first
  if [ "1$EC_ENV_PROJ" != "1" ]; then
    if [ -r $EC_ENV_ROOT/projects/$EC_ENV_PROJ/profile ]; then
      . $EC_ENV_ROOT/projects/$EC_ENV_PROJ/profile
    else
      echo "I: (.profile) project profile missing: $EC_ENV_ROOT/projects/$EC_ENV_PROJ/profile" >> $ec_env_error_log
    fi
  fi

  # run user's setup next (if any)
  if  [ -r $HOME/.profile.$USER ]; then
    . $HOME/.profile.$USER
  else
      echo "I: (.profile) user profile missing: $HOME/.profile.$USER" >> $ec_env_error_log
  fi

  # project validation - passive, not sourced
  if [ "1$EC_ENV_PROJ" != "1" -a "x$EC_ENV_NEUTER" != "x1" ]; then
    if [ -r $EC_ENV_ROOT/projects/$EC_ENV_PROJ/profile-val ]; then
      /bin/sh $EC_ENV_ROOT/projects/$EC_ENV_PROJ/profile-val
    else
      echo "I: (.profile) failed to find $EC_ENV_ROOT/projects/$EC_ENV_PROJ/profile-val" >> $ec_env_error_log
    fi
  fi

  # system validation - passive (Q: is it ok to reuse csh style)
  if [ -r $EC_ENV_ROOT/ec/cshrc-val -a "x$EC_ENV_NEUTER" != "x1" ]; then
    /bin/csh -f $EC_ENV_ROOT/ec/cshrc-val
    # cleanup env - Tibet#946117
    set --
  else
    #error - filesystem went away or master env corrupt?
    echo "E: (.profile) failed to find $EC_ENV_ROOT/ec/cshrc-val" >> $ec_env_error_log
  fi
fi

# cleanup
unset havelegacy

echo "I: (.profile) [leaving] `/bin/date`" >> $ec_env_error_log
unset ec_env_error_log
