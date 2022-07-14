#!/bin/sh

function init_log()
{
    LOGFILE="$1"
    if [ ! -e "$LOGFILE" ]
    then
        touch "$LOGFILE"
        if [ $? != 0 ]
        then
            echo "ERROR: failed to initial logging. can't create log file $LOGFILE"
        fi
    fi
}

function log()
{
    echo `date` "$@" | tee -a "$LOGFILE"
}

function log_info()
{
    log "INFO:" "$@"
}

function log_error()
{
    log "ERROR:" "$@"
}

function generate_lock()
{
    log_info "generate lock file."
    echo 1 > $LOCKFILE
}

function start_lsf()
{
    log_info "Start LSF services on master host $MYHOST..."
    source $LSF_TOP/conf/profile.lsf
    lsadmin limstartup >>$LOGFILE 2>&1
    lsadmin resstartup >>$LOGFILE 2>&1
    badmin hstartup >>$LOGFILE 2>&1
    log_info "LSF services on master host $MYHOST started."
}
## Main ##

MYHOST=`uname -n`
LSF_TOP="/opt/ibm/lsf"
LOGFILE="/tmp/start_lsf_ce_$MYHOST.log"
LOCKFILE="$LSF_TOP/lsf_ce_$MYHOST.lock"

if [ -f "$LOCKFILE" ]
then
    log_info "lock file exists in $LOCKFILE, just start LSF service."
else
    init_log $LOGFILE
fi

start_lsf
generate_lock

# hang here now
while true
do
    if test $(pgrep -f lim | wc -l) -eq 0
    then
        log_error "LIM process has exited due to a fatal error."
        log_error `tail -n 20 $LSF_TOP/log/lim.log.$MYHOST`
    else
        echo `date` "LSF is running -:) ..."
    fi
    sleep 10
done
